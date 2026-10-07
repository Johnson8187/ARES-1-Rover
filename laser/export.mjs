// 從工程網頁重新產生雷切檔（跟網頁「雷切」分頁下載的一模一樣）
// 需要 Node 18+ 和 Playwright：npm i -D playwright && npx playwright install chromium
// 用法：node laser/export.mjs                       → 預設參數，輸出 400x300、600x400、300x200 三種板材
//       node laser/export.mjs ply=2.9 kerf=0.18    → 改參數（名稱跟網頁 P 物件一樣）
// 離線時可以設 THREE_DIR=/path/to/three/package（three@0.169.0 解壓縮的資料夾）
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..');
const OUT = HERE;
const over = Object.fromEntries(process.argv.slice(2).filter(a => a.includes('=')).map(a => {
  const [k, v] = a.split('=');
  return [k, isNaN(+v) ? v : +v];
}));
const SIZES = [[400, 300], [600, 400], [300, 200]];

const browser = await chromium.launch(process.env.CHROME ? { executablePath: process.env.CHROME } : {});
const page = await browser.newPage();
const errs = [];
page.on('pageerror', e => errs.push(e.message));
if (process.env.THREE_DIR) {
  await page.route('https://cdn.jsdelivr.net/npm/three@0.169.0/**', route => {
    const f = path.join(process.env.THREE_DIR, route.request().url().replace('https://cdn.jsdelivr.net/npm/three@0.169.0/', ''));
    return fs.existsSync(f) ? route.fulfill({ path: f, contentType: 'application/javascript' }) : route.fulfill({ status: 404, body: '' });
  });
}
await page.goto('file://' + path.join(ROOT, 'web/index.html'));
await page.waitForFunction(() => window.__ares && window.__ares.WOOD.length > 0, null, { timeout: 30000 });

const res = await page.evaluate(([over, sizes]) => {
  const a = window.__ares;
  a.P = { ...a.P, ...over };
  a.build();
  const P = a.P, files = {};
  const csv = ['code,group,name,width_mm,height_mm,mirrored,sheet_400x300'];
  for (const [W, H] of sizes) {
    const PP = { ...P, sheetW: W, sheetH: H };
    const plan = a.laserPlan(PP, a.WOOD);
    const n = plan.sheets.length;
    for (const sh of plan.sheets) {
      const base = `ARES1_${W}x${H}_sheet${sh.n}of${n}`;
      files[base + '.svg'] = a.sheetSVG(sh, PP, { title: `${W}×${H} 板 ${sh.n}/${n}` });
      files[base + '.dxf'] = a.sheetDXF(sh);
      if (W === 400) for (const q of sh.parts) csv.push([q.p.code, q.p.grp, q.p.name, (q.rot ? q.h : q.w).toFixed(1), (q.rot ? q.w : q.h).toFixed(1), q.mirrored ? 1 : 0, sh.n].join(','));
    }
    if (plan.big.length) files[`TOO_BIG_${W}x${H}.txt`] = plan.big.map(p => p.code + ' ' + p.name).join('\n');
  }
  const test = a.laserPlan(P, a.testParts(P), { W: 140, H: 60, crop: true });
  files['ARES1_test.svg'] = a.sheetSVG(test.sheets[0], P, { title: '切縫測試片' });
  files['ARES1_test.dxf'] = a.sheetDXF(test.sheets[0]);
  files['parts.csv'] = csv.sort((x, y) => x.startsWith('code') ? -1 : y.startsWith('code') ? 1 : x.localeCompare(y, 'en', { numeric: true })).join('\n') + '\n';
  return { files, P: { ply: P.ply, kerf: P.kerf, fit: P.fit, nameTag: P.nameTag, layout: P.layout } };
}, [over, SIZES]);

for (const f of fs.readdirSync(OUT)) if (/^(ARES1_|TOO_BIG_).*\.(svg|dxf|txt)$/.test(f)) fs.unlinkSync(path.join(OUT, f));
for (const [name, text] of Object.entries(res.files)) fs.writeFileSync(path.join(OUT, name), text);
console.log(`參數 ${JSON.stringify(res.P)}，寫出 ${Object.keys(res.files).length} 個檔案到 ${path.relative(process.cwd(), OUT) || '.'}`);
if (errs.length) { console.error('網頁錯誤：', errs.join('\n')); process.exitCode = 1; }
await browser.close();
