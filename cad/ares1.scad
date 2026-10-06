// =====================================================================
// ARES-1 直立式雙履帶火星探測車 — 參數化零件庫
//
// 用法：
//   openscad -D 'part="tub"' -o stl/tub.stl ares1.scad
//   part = "assembly" 會顯示整車組合（含簡化的電子零件，不可列印）
//
// 座標（組合狀態）：建模時 x = 車子左側、y = 車頭方向、z = 向上，原點在地面中心，
// 與 web/index.html 對應 web(X, Y, Z) = scad(x, z, y)。這個對應是鏡像，輸出前由 out() 鏡射回來。
// 每個零件用 print_*() 轉成列印方向（平放在 z = 0）。
// =====================================================================
include <ares1_params.scad>

part = "assembly";   // 由命令列 -D 覆寫
yaw  = 0;            // 組合預覽時的頭部角度
explode = 0;         // 組合預覽的爆炸量（0–1）
$fn = 48;

// ------------------------- 衍生尺寸（與網頁 computeLayout 相同） -------------------------
PD      = trackPitch / sin(180 / sprocketTeeth);
Rp      = PD / 2;
pinY    = grouser + trackT / 2;
axleY   = pinY + Rp;
trackTop= axleY + Rp + trackT / 2 + grouser;
hw      = innerW / 2;
wallOut = hw + plateT;
trackX0 = wallOut + trackGap;
trackCx = trackX0 + trackW / 2;
trackOut= trackX0 + trackW;
zS      = wheelbase / 2;
loopLen = 2 * wheelbase + PI * PD;
links   = round(loopLen / trackPitch);
motorTotal = gearLen + motorCan + encLen;
mR      = motorD / 2;
floorTop= floorY + floorT;
tubLen  = ceil(wheelbase + motorD + 18);
tubZ0   = -tubLen / 2;
tubZ1   = tubLen / 2;
endWallT= 3;
// 底盤是「雙層巴士」：下層馬達＋驅動板＋電源區，上層整層是行動電源的電池艙
bay     = (bankMount != "back");
trayY0  = axleY + mR + 0.8;          // 托盤底面＝馬達頂 +0.8
trayT   = 1.6;
trayTop = trayY0 + trayT;
deckY0  = bay ? trayTop + bayH : max(trackTop + 0.6, trayY0);
deckY1  = deckY0 + deckT;
coax    = (layout == "A");
mLz     = -zS;
mRz     = coax ? -zS : zS;
// 馬達：[sign, flangeX, z]
MOTORS  = [[+1, hw, mLz], [-1, -hw, mRz]];
// 右側線材通道（地板直通上身）、托盤右緣立邊、電池艙
chX0 = -hw; chX1 = -hw + 16;
lipX0 = chX1; lipX1 = chX1 + 2;
pillarW = 7;
bayX0 = lipX1; bayX1 = hw - pillarW;       // 可用寬（預設 85）
bayZ1 = tubZ1 - endWallT;                  // 前壁就是擋塊，後方整個打開
// 上身固定立柱 [x0, x1, y0, y1]（頂端 M3 熱熔螺母）
PILLARS = [[hw - pillarW, hw, -33.5, -26.5], [hw - pillarW, hw, 26.5, 33.5],
           [-hw, -hw + pillarW, 18.5, 25.5], [-hw, -hw + pillarW, tubZ0 + endWallT, tubZ0 + endWallT + 6]];
TRAYPOST = [lipX0 - 2, lipX1, 20, 26];
STRAP_SLOTS = [-55, -10, 35];
SLOT_X = [lipX1 + 2.5, lipX1 + 10.5, bayX1 - 10.5, bayX1 - 2.5];
TRAY_SCREWS = [[0, tubZ1 - endWallT - 3], [35, tubZ1 - endWallT - 3], [(TRAYPOST[0] + TRAYPOST[1]) / 2, (TRAYPOST[2] + TRAYPOST[3]) / 2]];
// 驅動板：右側，端子朝車身中央、VM 在後端，排針在線材通道正下方
drvX    = -(hw - 4 - drvW / 2);
drvZ    = -12;
DRV_HOLE = [11.4, 20.4];   // 孔距 22.8 × 40.8（由 R3.6 圓角推得）
// 電源區（下層右後角；同軸方案改右前）：CH224K、Mini560、AMS1117
pwS  = coax ? -1 : 1;
pwZi = coax ? tubZ1 - endWallT : tubZ0 + endWallT;
function pzr(a, b) = [min(pwZi + pwS * a, pwZi + pwS * b), max(pwZi + pwS * a, pwZi + pwS * b)];
PDB  = concat([-hw + 15, -hw + 27], pzr(-2.5, 22));           // [x0, x1, y0, y1]
BUCK = concat([-hw + 28.5, -hw + 28.5 + buckW], pzr(0.5, 0.5 + buckL));
LDO  = concat([-hw + 1, -hw + 12], pzr(8, 30));
modY0 = floorTop + 3;
usbX = -hw + 21;
usbY = modY0 + 3.2;
usbWallY = coax ? tubZ1 - endWallT : tubZ0;
deckHole = [chX0 + 7, chX1 - 1, -36, -10];   // [x0, x1, y0, y1]
bodyY0  = deckY1;
bodyY1  = bodyY0 + bodyH;
bw      = bodyW / 2;
inW     = bw - shellT;
inZ0    = -bodyD / 2 + shellT;
inZ1    = bodyD / 2 - shellT;
topT    = 4;
topY1   = bodyY1;
topY0   = topY1 - topT;
wingX1  = inW - 1.4;
wingX0  = wingX1 - 3;
spineZ0 = neckZ + 10;
spineZ1 = spineZ0 + 3;
spkZF   = inZ1 - 1;
spkZB   = spkZF - spkH;
spkY    = bodyY0 + min(max(bodyH * 0.5, 26), 52);
ampX    = min(max(spkD / 2 + 14, 20), wingX0 - 10);
ampY    = bodyY0 + 14;
swX     = bw - 22;
perfY0  = min(bodyY0 + 43, topY0 - 31);
swZ     = -bodyD / 2 + 16;
riserH  = neckExtra;
mountY1 = topY1 + riserH;
mountY0 = mountY1 - 4;
// SG92R（SG9x 規格書值，待實物量測）
// 23.2×12.1×22.7、跨距 32.1、總高 30.5 依商品圖 [C]；耳片高度、軸心位置 [E]
sv_l = 23.2; sv_w = 12.1; sv_h = 22.7; sv_tabSpan = 32.1; sv_tabT = 2.5; sv_tabZ = 15.9;
sv_shaftOff = 5.9; sv_bossD = 11.8; sv_bossH = 4.0; sv_holeSp = 27.8; sv_hornD = 20; sv_hornH = 4.2;
servoY0 = mountY0 - sv_tabT - sv_tabZ;
servoTop= servoY0 + sv_h;
bossTop = servoTop + sv_bossH;
hornTop = bossTop + sv_hornH;
pivotY  = hornTop + 2;
collarR0 = 21; collarR1 = 24; collarH = 7;
skirtR0 = collarR1 + tol + 0.2; skirtR1 = skirtR0 + 2; skirtDrop = 8.5;   // 預設 tol 0.3 → 裙邊 ID 49
harnessR = 16;
stopAng = yawMax + 10;
stopR   = 31;
winR0 = 9; winR1 = collarR0 - 0.5; winZ = -7.5;
// 頭部（區域座標：原點＝轉軸與頭部底面交點，y 朝前，z 朝上）
hW = headW / 2; hT = 1.8; hFloorT = 3;
hz0 = headZ - headD / 2;
hz1 = headZ + headD / 2;
lensFrontZ = hz1 - 1;
pcbY = headH / 2 + 1;
pcbFrontZ = lensFrontZ - lensH;
esp_l = 62.6; esp_w = 28.3; esp_t = 1.6;
camEye = abs(lensOffset) >= 12 ? sign(lensOffset) : 0;   // 真鏡頭在哪一隻眼（-1＝右眼）
eyeX = camEye != 0 ? abs(lensOffset) : min(hW - 18, 21);
micP = [esp_l / 2 - 9, hz0 + 12, headH - hT];
// 上身骨架的頂板螺絲柱
TOP_BOSSES = [[wingX0 - 3, inZ0 + 6], [-(wingX0 - 3), inZ0 + 6], [30, spineZ0 - 4], [-30, spineZ0 - 4]];
SHELL_SCREWS = [-41, 5];   // 外殼側面螺絲的 y 位置（z = bodyY0 + 8）；-41 避開右後方線孔

echo(str("ARES-1: PD=", PD, " axleY=", axleY, " links=", links, " tubLen=", tubLen, " trayY0=", trayY0, " deckY0=", deckY0, " pivotY=", pivotY));

// ------------------------- 小工具 -------------------------
module rr2(x0, y0, x1, y1, r) {
  rr = min(r, (x1 - x0) / 2 - 0.01, (y1 - y0) / 2 - 0.01);
  translate([x0 + rr, y0 + rr]) offset(r = rr) square([x1 - x0 - 2 * rr, y1 - y0 - 2 * rr]);
}
module plateYZ(x0, t) { translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(t) children(); }   // 2D(y,z) 沿 +x 擠出
module plateXZ(y0, t) { translate([0, y0 + t, 0]) rotate([90, 0, 0]) linear_extrude(t) children(); } // 2D(x,z) 沿 +y 擠出
module boxB(x0, x1, y0, y1, z0, z1) { translate([min(x0, x1), min(y0, y1), min(z0, z1)]) cube([abs(x1 - x0), abs(y1 - y0), abs(z1 - z0)]); }
module cylX(r, x0, x1, y, z) { translate([min(x0, x1), y, z]) rotate([0, 90, 0]) cylinder(r = r, h = abs(x1 - x0)); }
module cylY(r, y0, y1, x, z) { translate([x, min(y0, y1), z]) rotate([-90, 0, 0]) cylinder(r = r, h = abs(y1 - y0)); }
module ring(r0, r1, h) { difference() { cylinder(r = r1, h = h, $fn = 96); translate([0, 0, -1]) cylinder(r = r0, h = h + 2, $fn = 96); } }
function arcpts(r, a0, a1, n, cy) = [for (i = [0:n]) let(t = a0 + (a1 - a0) * i / n) [r * sin(t), cy - r * cos(t)]];
aOut = acos(-winZ / winR1);
aIn  = acos(-winZ / winR0);
WINDOW = concat(arcpts(winR1, -aOut, aOut, 24, neckZ), arcpts(winR0, aIn, -aIn, 12, neckZ));
// 頭部 PCB 座標（原點在 PCB 正面中心，y 為法線朝前）→ 頭部區域座標
function F2H(p) = [p[0], pcbFrontZ + p[1] * cos(camTilt) + p[2] * sin(camTilt), pcbY - p[1] * sin(camTilt) + p[2] * cos(camTilt)];
module inPCBFrame() { translate([0, pcbFrontZ, pcbY]) rotate([-camTilt, 0, 0]) children(); }

// =====================================================================
// 1. 底盤槽（一體列印：底板＋左右側壁〔馬達座〕＋前後壁＋立柱＋托盤凸緣）
//    列印方向：底板貼平台。後壁上半部是電池艙開口，下半部是 CH224K 的 USB-C 孔。
// =====================================================================
module rear_wall_2d() {
  if (bay) polygon([[-hw - 0.5, floorTop - 0.5], [hw + 0.5, floorTop - 0.5], [hw + 0.5, deckY0], [bayX1, deckY0],
                    [bayX1, trayY0], [lipX0, trayY0], [lipX0, deckY0], [-hw - 0.5, deckY0]]);
  else rr2(-hw - 0.5, floorTop - 0.5, hw + 0.5, deckY0, 1);
}
module tub() {
  difference() {
    union() {
      translate([0, 0, floorY]) linear_extrude(floorT) rr2(-wallOut, tubZ0, wallOut, tubZ1, 6);
      plateYZ(hw, plateT) rr2(tubZ0, floorY, tubZ1, deckY0, 6);
      plateYZ(-wallOut, plateT) rr2(tubZ0, floorY, tubZ1, deckY0, 6);
      plateXZ(tubZ0, endWallT) rear_wall_2d();
      plateXZ(tubZ1 - endWallT, endWallT) rr2(-hw - 0.5, floorTop - 0.5, hw + 0.5, deckY0, 1);
      // 上身固定立柱
      for (p = PILLARS) boxB(p[0], p[1], p[2], p[3], floorTop - 0.5, deckY0);
      if (bay) {
        // 托盤凸緣（下緣 45° 倒角，免支撐）：左壁（避開左後馬達）、前壁（含兩個鎖托盤的螺絲座）
        hull() { boxB(hw - 3, hw, mLz + mR + 1, tubZ1 - endWallT, trayY0 - 0.8, trayY0); boxB(hw - 0.01, hw, mLz + mR + 1, tubZ1 - endWallT, trayY0 - 3.8, trayY0); }
        hull() { boxB(lipX0, hw, tubZ1 - endWallT - 6, tubZ1 - endWallT, trayY0 - 0.8, trayY0); boxB(lipX0, hw, tubZ1 - endWallT - 0.01, tubZ1 - endWallT, trayY0 - 6.8, trayY0); }
        boxB(TRAYPOST[0], TRAYPOST[1], TRAYPOST[2], TRAYPOST[3], floorTop - 0.5, trayY0);
      }
      // 馬達尾端托架（兩根立柱，束線帶從底板槽繞過馬達）
      for (m = MOTORS) {
        cx = m[1] - m[0] * motorTotal + m[0] * (encLen + 6);   // 托在馬達身上，讓出編碼器接頭
        for (s = [-1, 1]) boxB(cx - 3, cx + 3, m[2] + s * 12.9, m[2] + s * 16.4, floorTop - 0.5, axleY);
      }
      // 驅動板螺絲座（M3 自攻；孔距為推估，待量測）
      for (sx = [-1, 1], sz = [-1, 1]) translate([drvX + sx * DRV_HOLE[0], drvZ + sz * DRV_HOLE[1], floorTop - 0.5]) cylinder(d = 6.5, h = 4.5);
      // 電源區：CH224K 兩條滑軌（PCB 穿過牆孔）、Mini560／AMS1117 各兩根小柱（雙面膠或熱熔膠）
      for (xx = [PDB[0] + 1.5, PDB[1] - 1.5]) boxB(xx - 1, xx + 1, max(PDB[2], tubZ0 + endWallT), min(PDB[3], tubZ1 - endWallT), floorTop - 0.5, modY0);
      for (m = [BUCK, LDO], yy = [m[2] + 3, m[3] - 3]) translate([(m[0] + m[1]) / 2, yy, floorTop - 0.5]) cylinder(d = 3.6, h = modY0 - floorTop + 0.5);
    }
    // 底板：馬達下方長槽
    for (m = MOTORS) {
      xa = max(min(m[1], m[1] - m[0] * motorTotal) - 1, -hw + 0.5);
      xb = min(max(m[1], m[1] - m[0] * motorTotal) + 1, hw - 0.5);
      translate([0, 0, floorY - 1]) linear_extrude(floorT + 2) rr2(xa, m[2] - 9, xb, m[2] + 9, 3);
    }
    // 側壁：馬達軸孔、M3 沉頭、惰輪張緊長槽
    for (m = MOTORS) {
      xin = m[0] > 0 ? hw : -wallOut;
      cylX(4.2, xin - 1, xin + plateT + 1, m[2], axleY);
      // 兩個 M3 左右（水平）排列 → 編碼器 6P 接頭水平朝車身中央，不會頂到托盤；沉孔 2 mm 配 ISO 7380 圓頭
      for (d = [-motorHole / 2, motorHole / 2]) {
        cylX(1.7, xin - 1, xin + plateT + 1, m[2] + d, axleY);
        if (m[0] > 0) cylX(3.1, wallOut - 2, wallOut + 1, m[2] + d, axleY);
        else cylX(3.1, -wallOut - 1, -wallOut + 2, m[2] + d, axleY);
      }
      hull() for (d = [-4, 4]) cylX(2.2, xin - 1, xin + plateT + 1, -m[2] + d, axleY);
    }
    // CH224K 的 USB-C 孔（C 公頭外殼要進得去：13.5 × 7.6）
    plateXZ(usbWallY - 1, endWallT + 2) rr2(usbX - 6.75, usbY - 3.8, usbX + 6.75, usbY + 3.8, 2.5);
    // 前壁任務模組介面 2×M3
    for (s = [-1, 1]) cylY(1.7, tubZ1 - endWallT - 1, tubZ1 + 1, s * 20, (floorTop + min(trayY0, deckY0)) / 2);
    // 立柱頂端 M3 熱熔螺母孔（Ø4.0×6）
    for (p = PILLARS) translate([(p[0] + p[1]) / 2, (p[2] + p[3]) / 2, deckY0 - 6.5]) cylinder(d = insertD, h = 7);
    // 托盤螺絲導孔（M2.5 自攻）
    if (bay) for (q = TRAY_SCREWS) translate([q[0], q[1], trayY0 - 6]) cylinder(d = 2.1, h = 7, $fn = 16);
    // 驅動板螺絲座導孔
    for (sx = [-1, 1], sz = [-1, 1]) translate([drvX + sx * DRV_HOLE[0], drvZ + sz * DRV_HOLE[1], floorY + 0.8]) cylinder(d = 2.8, h = 10);
    // 托架束線帶孔
    for (m = MOTORS) {
      cx = m[1] - m[0] * motorTotal + m[0] * (encLen + 6);
      for (s = [-1, 1]) boxB(cx - 2, cx + 2, m[2] + s * 12, m[2] + s * 17.5, floorTop + 1.2, floorTop + 2.8);
    }
  }
}

// =====================================================================
// 2. 驅動輪／惰輪（同一個檔案，drive 決定孔型）
//    列印方向：外側面（離側壁最遠那面）貼平台，用 print_sprocket()。
//    兩片抬高的圓盤底下都有 45° 錐形腹板，免支撐。
// =====================================================================
module cone_web(zA, zB, rA) {   // 在 zA 半徑 rA，往 zB 以 45° 收小；殼厚約 1.6
  h = abs(zB - zA); rB = rA - h;
  translate([0, 0, min(zA, zB)]) difference() {
    cylinder(h = h, r1 = zB > zA ? rA : rB, r2 = zB > zA ? rB : rA, $fn = 80);
    translate([0, 0, -0.01]) cylinder(h = h + 0.02, r1 = (zB > zA ? rA : rB) - 2.3, r2 = (zB > zA ? rB : rA) - 2.3, $fn = 80);
  }
}
module sprocket(drive = true) {
  zT0 = trackX0 - (wallOut + 0.5);
  zT1 = zT0 + trackW;
  rimR = Rp - trackT / 2 - 0.5;
  cz = zT0 + trackW / 2;
  difference() {
    union() {
      cylinder(r = 7, h = zT1);                   // 輪轂 Ø14：把 M3 螺母槽整個包住
      translate([0, 0, zT0]) cylinder(r = rimR, h = 4, $fn = 80);
      translate([0, 0, zT1 - 4]) cylinder(r = rimR, h = 4, $fn = 80);
      translate([0, 0, cz - 4.5]) cylinder(r = rimR, h = 9, $fn = 80);
      cone_web(cz + 4.5, zT1 - 4, rimR);          // 齒盤 → 外側圓盤
      cone_web(zT0 + 4, cz - 4.5, rimR);          // 內側圓盤 → 齒盤
      for (i = [0:4]) rotate([0, 0, i * 72 + 18]) translate([0, -1.2, zT0]) cube([rimR - 0.5, 2.4, trackW]);
      for (i = [0:sprocketTeeth - 1]) rotate([0, 0, (i + 0.5) * 360 / sprocketTeeth])
        translate([0, 0, cz - 4]) linear_extrude(8) polygon([[rimR - 1, -2.5], [Rp + 2.2, -1.2], [Rp + 2.2, 1.2], [rimR - 1, 2.5]]);
    }
    if (drive) {
      // D 形孔（軸 Ø4、D 切面 3.5；tol 0.3 → 孔 Ø4.15、平面距圓心 1.55）深 8.5
      translate([0, 0, -1]) linear_extrude(9.5) intersection() { circle(d = shaftD + tol / 2, $fn = 40); translate([-2.4, -2.4]) square([2.4 + (3.5 - shaftD / 2) + tol / 6, 4.8]); }
      // 止付螺絲孔（朝 D 平面）＋ M3 螺母槽（從靠壁面塞入）
      translate([0, 0, 4.5]) rotate([0, 90, 0]) cylinder(d = 3.2, h = rimR + 5);
      translate([2.9, -2.95, -1]) cube([2.7, 5.9, 4.5 + 3.3 + 1]);
    } else {
      translate([0, 0, -1]) cylinder(d = 4 + tol * 4 / 3, h = zT1 + 2);   // M4 軸
      if (idler_bearing) for (z = [-1, zT1 - 5]) translate([0, 0, z]) cylinder(d = 13.1, h = 6);
    }
  }
}

// =====================================================================
// 3. 履帶片（每邊 links 片，1.75 mm 線材當插銷）
//    列印方向：內面（平）貼平台，抓地齒朝上
// =====================================================================
module track_link() {
  p = trackPitch; w = trackW; kd = trackT; pd = 1.75 + tol * 2 / 3; gap = tol + 0.1;   // 插銷 1.75 線材
  A = [[-w / 2, -w / 2 + 5.4], [-4.9, 4.9], [w / 2 - 5.4, w / 2]];
  B = [[-w / 2 + 5.4 + gap, -4.9 - gap], [4.9 + gap, w / 2 - 5.4 - gap]];
  top = 1.2;
  difference() {
    union() {
      translate([-w / 2, -p / 2, -kd / 2]) cube([w, p, kd / 2 + top]);
      for (k = A) translate([k[0], p / 2, 0]) rotate([0, 90, 0]) cylinder(d = kd, h = k[1] - k[0], $fn = 28);
      for (k = B) translate([k[0], -p / 2, 0]) rotate([0, 90, 0]) cylinder(d = kd, h = k[1] - k[0], $fn = 28);
      for (s = [-1, 1]) translate([s > 0 ? 5.5 : -w / 2, -1.1, top - 0.01]) cube([w / 2 - 5.5, 2.2, grouser + 0.01]);
    }
    for (y = [-p / 2, p / 2]) translate([-w / 2 - 1, y, 0]) rotate([0, 90, 0]) cylinder(d = pd, h = w + 2, $fn = 16);
    for (k = B) translate([k[0] - gap, p / 2 - kd / 2 - gap, -kd]) cube([k[1] - k[0] + 2 * gap, kd + 2 * gap, 2 * kd]);
    for (k = A) translate([k[0] - gap, -p / 2 - kd / 2 - gap, -kd]) cube([k[1] - k[0] + 2 * gap, kd + 2 * gap, 2 * kd]);
    translate([-4.5, -2.8, -kd]) cube([9, 5.6, 2 * kd]);   // 鏈輪齒窗
  }
}
module track_links_plate(nx = 4, ny = 4) {
  for (i = [0:nx - 1], j = [0:ny - 1]) translate([i * (trackW + 4), j * (trackPitch + 8), trackT / 2]) track_link();
}

// =====================================================================
// 4. 電池艙托盤（架在凸緣與小立柱上，3 顆 M2.5 自攻；右緣立邊兼導軌與通道牆）
//    列印方向：平放，立邊朝上，免支撐
// =====================================================================
module tray_2d() {
  c = tol + 0.1; xr = hw - c; zf = bayZ1 - tol; nx = bayX1 - c;
  P1 = PILLARS[0]; P2 = PILLARS[1];
  difference() {
    polygon([[lipX0, tubZ0], [bayX1, tubZ0], [bayX1, tubZ0 + endWallT + tol], [xr, tubZ0 + endWallT + tol],
             [xr, P1[2] - c], [nx, P1[2] - c], [nx, P1[3] + c], [xr, P1[3] + c],
             [xr, P2[2] - c], [nx, P2[2] - c], [nx, P2[3] + c], [xr, P2[3] + c],
             [xr, zf], [lipX0, zf]]);
    // 減重窗（避開扣孔）
    zs = [tubZ0 + 6, STRAP_SLOTS[0] - 13, STRAP_SLOTS[0] + 13, STRAP_SLOTS[1] - 13, STRAP_SLOTS[1] + 13, STRAP_SLOTS[2] - 13, STRAP_SLOTS[2] + 13, bayZ1 - 6];
    for (i = [0:2:len(zs) - 2]) if (zs[i + 1] - zs[i] > 10) rr2(lipX1 + 16, zs[i], bayX1 - 16, zs[i + 1], 4);
    // 魔鬼氈扣孔（每側兩個一組，綁帶從橋下穿過）
    for (zc = STRAP_SLOTS, xs = SLOT_X) rr2(xs - 1.5, zc - 11, xs + 1.5, zc + 11, 1.4);
    for (q = TRAY_SCREWS) translate([q[0], q[1]]) circle(d = 2.9, $fn = 20);
  }
}
module battery_tray() {
  difference() {
    union() {
      translate([0, 0, trayY0]) linear_extrude(trayT) tray_2d();
      boxB(lipX0, lipX1, tubZ0, bayZ1 - 0.3, trayTop - 0.01, trayTop + 8);
    }
    for (q = TRAY_SCREWS) translate([q[0], q[1], trayTop - 1.2]) cylinder(d1 = 2.9, d2 = 5.4, h = 1.21, $fn = 20);
  }
}
// 前方墊塊：短的行動電源在前面塞幾片，把重心推回中間（10 mm 一片，可疊）
module bank_spacer() {
  w = min(bankW - 6, bayX1 - bayX0 - 4); h = min(bankT, bayH - 1) * 0.8;
  difference() {
    translate([-w / 2, 0, 0]) cube([w, 10, h]);
    translate([0, -1, h]) rotate([-90, 0, 0]) cylinder(d = 14, h = 12);   // 手指缺口
  }
}

// =====================================================================
// 5. 上身骨架（底板兼底盤上蓋＋ㄇ字形脊板／側翼）
//    列印方向：底板貼平台，免支撐
// =====================================================================
module upper_frame() {
  fh0 = deckY1; fh1 = topY0;
  difference() {
    union() {
      translate([0, 0, deckY0]) linear_extrude(deckT) rr2(-wallOut, tubZ0, wallOut, tubZ1, 6);
      plateXZ(spineZ0, 3) rr2(-wingX1, fh0 - 0.5, wingX1, fh1, 2);
      for (s = [-1, 1]) boxB(s * wingX0, s * wingX1, inZ0 + 2, spineZ1, fh0 - 0.5, fh1);
      // 斜撐（右邊在線孔上方斷開）
      for (s = [-1, 1]) {
        over = min(s * (wingX0 - 8), s * wingX0) < deckHole[1] && max(s * (wingX0 - 8), s * wingX0) > deckHole[0];
        segs = over ? [[inZ0 + 2, deckHole[2] - 2], [deckHole[3] + 2, spineZ0]] : [[inZ0 + 2, spineZ0]];
        for (g = segs) if (g[1] - g[0] > 3) hull() {
          boxB(s * (wingX0 - 0.01), s * wingX0, g[0], g[1], fh0 - 0.5, fh0 + 20);
          boxB(s * (wingX0 - 8), s * wingX0, g[0], g[1], fh0 - 0.5, fh0);
        }
      }
      // 頂板螺絲柱：底下 45° 斜撐接到側翼或脊板（免支撐）
      for (b = TOP_BOSSES) hull() {
        translate([b[0] - 4, b[1] - 4, fh1 - 10]) cube([8, 8, 10]);
        if (abs(b[0]) > wingX0 - 6) boxB(sign(b[0]) * wingX0, sign(b[0]) * (wingX0 + 1), b[1] - 4, b[1] + 4, fh1 - 18, fh1);
        else boxB(b[0] - 4, b[0] + 4, spineZ0, spineZ0 + 1, fh1 - 18, fh1);
      }
      for (s = [-1, 1], yy = SHELL_SCREWS) boxB(s * (wingX0 - 5), s * wingX0 + s * 0.5, yy - 4, yy + 4, fh0 - 0.5, bodyY0 + 13);
    }
    for (p = PILLARS) translate([(p[0] + p[1]) / 2, (p[2] + p[3]) / 2, deckY0 - 1]) cylinder(d = 3.4, h = deckT + 2);
    translate([0, 0, deckY0 - 1]) linear_extrude(deckT + 2) rr2(deckHole[0], deckHole[2], deckHole[1], deckHole[3], 2);   // 線孔：對準右側通道，J1/J2 從這裡上來
    for (s = [-1, 1]) translate([s * 30, tubZ1 - 8, deckY0 - 1]) cylinder(d = 3.4, h = deckT + 2);
    // 脊板穿線孔
    plateXZ(spineZ0 - 1, 5) rr2(-10, fh0 + 4, 10, fh0 + 16, 3);
    // MAX98357A 上方兩孔（中心距 12.6，已確認）
    for (s = [-1, 1]) cylY(0.9, spineZ0 - 1, spineZ1 + 1, ampX + s * 6.3, ampY + 19.1 / 2 - 2.5);
    // 喇叭墊高環固定孔
    for (a = [30, 150, 270]) cylY(1.7, spineZ0 - 1, spineZ1 + 1, (spkD / 2 + 7) * cos(a), spkY + (spkD / 2 + 7) * sin(a));
    // 外殼側面螺絲導孔
    for (s = [-1, 1], yy = SHELL_SCREWS) cylX(1.3, s * (wingX0 - 6), s * (wingX1 + 1), yy, bodyY0 + 8);
    // 頂板螺絲導孔
    for (b = TOP_BOSSES) translate([b[0], b[1], fh1 - 9]) cylinder(d = 2.6, h = 10);
    // 束線帶槽：右翼（配電板）；降壓模組已搬到底盤電源區
    for (yy = [spineZ0 - 12, spineZ0 - 40], zz = [perfY0 + 5.5, perfY0 + 23.5])
      boxB(-(wingX0 - 1), -(wingX1 + 1), yy - 1.5, yy + 1.5, zz - 2, zz + 2);
  }
}

// =====================================================================
// 6. 頂板／頸座（伺服機倒吊、軸環、限位柱、腎形線束窗口、開關孔）
//    列印方向：板面貼平台，軸環朝上
// =====================================================================
module neck_deck() {
  rw = 20;
  difference() {
    union() {
      translate([0, 0, topY0]) linear_extrude(topT) rr2(-inW + tol + 0.2, inZ0 + tol + 0.2, inW - tol - 0.2, inZ1 - tol - 0.2, 3);   // 外殼要從上面套下來
      if (riserH > 0) {
        difference() {
          translate([0, 0, topY1 - 0.5]) linear_extrude(riserH - 4 + 0.5) rr2(-rw, neckZ - rw, rw, neckZ + rw, 3);
          translate([0, 0, topY1 - 1]) linear_extrude(riserH + 2) rr2(-rw + 2.4, neckZ - rw + 2.4, rw - 2.4, neckZ + rw - 2.4, 1);
        }
        translate([0, 0, mountY0]) linear_extrude(4) rr2(-rw - 6, neckZ - rw - 6, rw + 6, neckZ + rw + 6, 4);
      }
      translate([0, neckZ, mountY1 - 0.5]) ring(collarR0, collarR1, collarH + 0.5);
      for (s = [-1, 1]) translate([stopR * sin(180 + s * stopAng), neckZ + stopR * cos(180 + s * stopAng), mountY1 - 0.5]) cylinder(d = 5, h = 6.5);
    }
    // 伺服開孔＋線束窗口（在安裝板上）
    translate([0, 0, mountY0 - 1]) linear_extrude(6) {
      sc = tol * 2 / 3;
      rr2(-sv_shaftOff - sc, neckZ - sv_w / 2 - sc, sv_l - sv_shaftOff + sc, neckZ + sv_w / 2 + sc, 0.5);
      polygon(WINDOW);
    }
    // 伺服耳片 M2 自攻導孔（由下往上）
    for (s = [-1, 1]) translate([sv_l / 2 - sv_shaftOff + s * sv_holeSp / 2, neckZ, mountY0 - 1]) cylinder(d = 1.6, h = 4.5, $fn = 16);
    if (riserH > 0) translate([0, 0, topY0 - 1]) linear_extrude(topT + 2) rr2(-rw + 2.4, neckZ - rw + 2.4, rw - 2.4, neckZ + rw - 2.4, 1);
    // 開關孔（KCD1 開孔 19×13）
    translate([swX - 6.5, swZ - 9.5, topY0 - 1]) cube([13, 19, topT + 2]);
    // 固定到骨架的 M3 沉頭孔
    for (b = TOP_BOSSES) { translate([b[0], b[1], topY0 - 1]) cylinder(d = 3.4, h = topT + 2); translate([b[0], b[1], topY1 - 1.8]) cylinder(d1 = 3.4, d2 = 6.6, h = 1.81); }
    if (!mic_in_head) translate([-bw + 14, -bodyD / 2 + 12, topY0 - 1]) cylinder(d = 2.4, h = topT + 2);
  }
}

// =====================================================================
// 7. 身體外殼（上下開口的套筒；拆 4 顆 M3 後往上拔，頭不用拆）
//    列印方向：直立
// =====================================================================
module body_shell() {
  difference() {
    translate([0, 0, bodyY0]) linear_extrude(bodyH) rr2(-bw, -bodyD / 2, bw, bodyD / 2, 3);
    translate([0, 0, bodyY0 - 1]) linear_extrude(bodyH + 2) rr2(-inW, inZ0, inW, inZ1, 1.4);
    for (rr = [0:5.5:spkD / 2 - 5]) let(n = rr == 0 ? 1 : floor(2 * PI * rr / 5.5))
      for (i = [0:n - 1]) cylY(1.5, bodyD / 2 - shellT - 1, bodyD / 2 + 1, rr * cos(i * 360 / n), spkY + rr * sin(i * 360 / n));
    boxB(-20, 20, bodyD / 2 - 0.6, bodyD / 2 + 1, bodyY0 + 6, bodyY0 + 16);        // 名牌凹槽
    boxB(-bw - 1, bw + 1, bodyD / 2 - 0.6, bodyD / 2 + 1, bodyY1 - 6, bodyY1 - 3); // 飾條
    for (i = [-3:3]) translate([i * 5 - 1.25, -bodyD / 2 - 1, bodyY1 - 40]) cube([2.5, shellT + 2, 14]);   // 直條散熱孔（橫的會變 36 mm 長橋）
    for (s = [-1, 1], yy = SHELL_SCREWS) cylX(1.7, s * (bw - shellT - 1), s * (bw + 1), yy, bodyY0 + 8);
  }
}

// =====================================================================
// 8. 喇叭墊高環（前唇貼平台列印；三片直立肋當螺絲柱）
// =====================================================================
module speaker_ring() {
  Lr = spkZF + 0.8 - spineZ1;
  od = spkD + 4.4; id = spkD + 2 * tol;
  difference() {
    union() {
      cylinder(d = od, h = Lr, $fn = 96);
      for (a = [30, 150, 270]) hull() {
        rotate([0, 0, a]) translate([spkD / 2 + 7, 0, 0]) cylinder(d = 7, h = Lr);
        rotate([0, 0, a]) translate([od / 2 - 1.5, -2.5, 0]) cube([1, 5, Lr]);
      }
    }
    translate([0, 0, 0.8]) cylinder(d = id, h = Lr, $fn = 96);            // 喇叭座（前唇 0.8 在 z=0 側）
    translate([0, 0, -1]) cylinder(d = spkD - 5, h = 3, $fn = 96);        // 前唇開口
    for (a = [30, 150, 270]) rotate([0, 0, a]) translate([spkD / 2 + 7, 0, Lr - 9]) cylinder(d = 2.6, h = 10);
    translate([-4, od / 2 - 4, Lr - 10]) cube([8, 6, 11]);                  // 喇叭線出口
  }
}

// =====================================================================
// 9. 頭部轉盤（裙邊、限位指、舵盤凸台、線束孔、PCB 底部支撐柱）
//    列印方向：頂面貼平台（倒放），裙邊朝上
// =====================================================================
HOOD_SCREWS = [[hW - hT - 3, hz0 + hT + 3], [-(hW - hT - 3), hz0 + hT + 3], [hW - hT - 3, hz1 - hT - 3], [-(hW - hT - 3), hz1 - hT - 3]];
BACK_SCREWS = [[20, hz0 + hT + 2.5], [-20, hz0 + hT + 2.5]];
module head_floor() {
  difference() {
    union() {
      linear_extrude(hFloorT) rr2(-hW, hz0, hW, hz1, 5);
      cylinder(r = skirtR1, h = hFloorT, $fn = 96);                  // 圓形法蘭：裙邊整圈都坐在轉盤上（倒放列印免支撐）
      translate([0, 0, -skirtDrop]) ring(skirtR0, skirtR1, skirtDrop + 0.5);
      boxB(-2.5, 2.5, -skirtR1 - 3.5, -skirtR1 + 0.2, -6, hFloorT);   // 限位指（接到轉盤頂面，列印時貼平台）
      translate([0, 0, -2]) cylinder(d = 20, h = 2.5);
    }
    translate([0, 0, -3]) cylinder(d = 6, h = hFloorT + 4);
    translate([0, -harnessR, -1]) cylinder(d = 8, h = hFloorT + 2);
    for (a = [45, 135, 225, 315]) translate([7.2 * cos(a), 7.2 * sin(a), -3]) cylinder(d = 1.6, h = hFloorT + 4, $fn = 12);
    for (p = concat(HOOD_SCREWS, BACK_SCREWS)) translate([p[0], p[1], -1]) cylinder(d = 2.4, h = hFloorT + 2, $fn = 16);
  }
}

// =====================================================================
// 10. 頭罩（護目鏡臉：前、上、左右四面，後方與底部開口）
//     列印方向：臉朝下貼平台
// =====================================================================
module head_hood() {
  difference() {
    union() {
      difference() {
        translate([0, 0, hFloorT]) linear_extrude(headH - hFloorT) rr2(-hW, hz0 + hT, hW, hz1, 4);
        translate([0, 0, hFloorT - 1]) linear_extrude(headH - hT - hFloorT + 1) rr2(-(hW - hT), hz0 - 1, hW - hT, hz1 - hT, 2.5);
      }
      // PCB 角座（四角，沿俯角傾斜）：前擋＋側擋＋上下擋，後方開口。
      // PCB 從頭罩後方放入，由後蓋的四根壓柱往前壓住；鏡頭插進 Ø12 孔順便定位。
      inPCBFrame() for (s = [-1, 1], v = [-1, 1]) difference() {
        boxB(s * (esp_l / 2 - 1.5), s * (hW - hT + 0.6), -3.5, 2, v * (esp_w / 2 - 4), v * (esp_w / 2 + 1.5));
        boxB(s * (esp_l / 2 - 1.6), s * (esp_l / 2 + tol + 0.1), -3.6, 0.2, v > 0 ? esp_w / 2 - 5 : -esp_w / 2 - tol, v > 0 ? esp_w / 2 + tol : -esp_w / 2 + 5);
      }
      // 麥克風定位框
      if (mic_in_head) translate([micP[0], micP[1], headH - hT - 1.5]) difference() {
        translate([-6.2, -6.2, 0]) cube([12.4, 12.4, 1.6]);
        translate([-5 - tol * 2 / 3, -5 - tol * 2 / 3, -1]) cube([10 + tol * 4 / 3, 10 + tol * 4 / 3, 4]);
      }
      // 轉盤固定耳（M2 由下往上鎖）
      for (p = HOOD_SCREWS) hull() {
        translate([p[0] - 3, p[1] - 3, hFloorT]) cube([6, 6, 4]);
        if (p[1] < 0) translate([p[0] > 0 ? hW - hT - 0.1 : -(hW - hT), p[1] - 3, hFloorT]) cube([0.1, 12, 4]);
      }
    }
    for (p = HOOD_SCREWS) translate([p[0], p[1], hFloorT - 1]) cylinder(d = 1.8, h = 6, $fn = 12);
    // 鏡頭孔
    cylY(6, hz1 - hT - 1, hz1 + 1, lensOffset, pcbY);
    // 護目鏡凹槽（貼黑色貼紙或塗黑）與眼圈座
    boxB(-hW + 5, hW - 5, hz1 - 0.6, hz1 + 1, pcbY - 13, pcbY + 13);
    for (s = [-1, 1]) cylY(14.1 + tol / 2, hz1 - 0.6 - 0.6, hz1 + 1, s * eyeX, pcbY);
    // USB-C 開孔（頭部左側）
    boxB(hW - hT - 1, hW + 1, pcbFrontZ - 2, pcbFrontZ + 6, pcbY - 10, pcbY + 10);
    // 收音孔
    if (mic_in_head) for (d = [-3, 0, 3]) translate([micP[0] + d, micP[1], headH - hT - 1]) cylinder(d = 1.5, h = hT + 2, $fn = 12);
  }
}

// =====================================================================
// 11. 頭部後蓋（散熱槽，2 顆 M2 鎖轉盤）
// =====================================================================
PRONGS = [for (s = [-1, 1], v = [-1, 1]) F2H([s * (esp_l / 2 - 2), -esp_t, v * 9])];
module head_back() {
  difference() {
    union() {
      plateXZ(hz0, hT) rr2(-hW, hFloorT, hW, headH, 4);
      for (p = BACK_SCREWS) boxB(p[0] - 3, p[0] + 3, hz0 + hT - 0.5, hz0 + hT + 5, hFloorT, hFloorT + 4);
      // PCB 壓柱（壓在 PCB 背面四角，避開排針）
      for (q = PRONGS) cylY(2, hz0 + hT - 0.5, q[1], q[0], q[2]);
    }
    for (i = [-3:3]) plateXZ(hz0 - 1, hT + 2) rr2(i * 7 - 1.4, headH * 0.45, i * 7 + 1.4, headH * 0.8, 1.2);
    for (p = BACK_SCREWS) translate([p[0], p[1], hFloorT - 1]) cylinder(d = 1.8, h = 6, $fn = 12);
  }
}

// ---------- 12. 造型小零件 ----------
module eye_ring() { difference() { union() { cylinder(d = 28, h = 1.8, $fn = 72); translate([0, 0, -0.6]) cylinder(d = 28.2, h = 0.61, $fn = 72); } translate([0, 0, -1]) cylinder(d = 20, h = 4, $fn = 72); } }
module pupil() { cylinder(d = 13, h = 1.2, $fn = 48); }
module eyelid() { linear_extrude(1.4) scale([1, 0.62]) intersection() { circle(r = 14.5, $fn = 64); translate([-15, 0]) square([30, 15]); } }

// =====================================================================
// 13. 試配套件：大件之前先印這些小片（一盤約 1 小時、不到 30 g），拿實物試
//     每一片都直接用正式零件的同一段程式或同一組尺寸，試得過，正式件就配得起來。
// =====================================================================
// 間隙梳：5 個孔（單邊間隙 0.1–0.5，刻字標示）＋ 1 根 Ø5 銷。銷能順順插進去的最小孔 → tol
module fit_tol() {
  difference() {
    translate([0, -3, 0]) cube([64, 21, 3]);
    for (i = [0:4]) {
      c = 0.1 + 0.1 * i;
      translate([8 + i * 12, 10, -1]) cylinder(d = 5 + 2 * c, h = 5, $fn = 72);
      translate([8 + i * 12, 0.6, 2.4]) linear_extrude(1) text(str(c), size = 3.2, halign = "center", font = "Liberation Sans:style=Bold");
    }
  }
  translate([-9, 10, 0]) cylinder(d = 5, h = 12, $fn = 72);
}
// 馬達座：側壁的軸孔＋2×M3 沉頭，拿真的 JGA25-370 鎖鎖看（沉頭面朝上列印）
module fit_motor() {
  difference() {
    translate([-22, -16, 0]) cube([44, 32, plateT]);
    translate([0, 0, -1]) cylinder(r = 4.2, h = plateT + 2);
    for (d = [-motorHole / 2, motorHole / 2]) {
      translate([d, 0, -1]) cylinder(r = 1.7, h = plateT + 2);
      translate([d, 0, plateT - 2]) cylinder(r = 3.1, h = 3);
    }
  }
}
// 驅動輪輪轂：D 孔＋止付螺絲孔＋螺母槽，套到馬達軸上試
module fit_hub() { translate([0, 0, -20]) intersection() { print_sprocket(true); translate([0, 0, 20]) cylinder(r = 7, h = 15); } }
// 履帶 3 片：用 1.75 線材試插銷、試彎折、試鏈輪齒窗
module fit_track() { track_links_plate(3, 1); }
// 頸部：頂板的伺服開孔＋軸環＋限位柱（左），頭部轉盤的裙邊＋舵盤凸台（右）
module fit_neck() {
  intersection() { translate([0, -neckZ, -topY0]) neck_deck(); translate([0, 0, -1]) cylinder(r = 37, h = 40, $fn = 120); }
  translate([75, 0, 0]) intersection() { print_head_floor(); translate([0, 0, -1]) cylinder(r = 31, h = 30, $fn = 120); }
}
// ESP32-S3-CAM 外框量規：間隙和頭罩角座相同，板子要能平放進去、四角架在台階上
module fit_pcb() {
  L2 = esp_l / 2 + tol + 0.1; W2 = esp_w / 2 + tol;
  difference() {
    translate([-L2 - 2, -W2 - 2, 0]) cube([2 * L2 + 4, 2 * W2 + 4, 2.4]);
    translate([-L2, -W2, -1]) cube([2 * L2, 2 * W2, 5]);
  }
  for (s = [-1, 1], v = [-1, 1]) translate([s > 0 ? esp_l / 2 - 1.5 : -L2, v > 0 ? esp_w / 2 - 4 : -W2, 0]) cube([L2 - (esp_l / 2 - 1.5), W2 - (esp_w / 2 - 4), 1]);
}
// DRV8870 孔位樣板：外形同 PCB，板子疊上去 4 個孔要對齊（孔距是推估值，最容易錯）
module fit_drv() {
  difference() {
    translate([-drvW / 2, -drvL / 2, 0]) cube([drvW, drvL, 2]);
    for (sx = [-1, 1], sz = [-1, 1]) translate([sx * DRV_HOLE[0], sz * DRV_HOLE[1], -1]) cylinder(d = 3.2, h = 4);
    translate([-drvW / 2 + 6, -drvL / 2 + 8, -1]) cube([drvW - 12, drvL - 16, 4]);
  }
}
// 熱熔螺母孔：4 種孔徑，燙進去最正、不會歪也不會鬆的那個 → insertD
module fit_insert() {
  ds = [insertD - 0.2, insertD, insertD + 0.2, insertD + 0.4];
  difference() {
    cube([46, 16, 7]);
    for (i = [0:3]) {
      translate([6 + i * 11.3, 10, 0.6]) cylinder(d = ds[i], h = 7, $fn = 48);
      translate([6 + i * 11.3, 1.2, 6.4]) linear_extrude(1) text(str(ds[i]), size = 2.6, halign = "center", font = "Liberation Sans:style=Bold");
    }
  }
}

// =====================================================================
// 組合預覽（含簡化電子零件，僅供檢查）
// =====================================================================
module motor_dummy(m) {
  s = m[0]; x0 = m[1];
  color("DimGray") cylX(mR, x0, x0 - s * gearLen, m[2], axleY);
  color("Silver") cylX(mR, x0 - s * gearLen, x0 - s * (gearLen + motorCan), m[2], axleY);
  color("Black") cylX(mR, x0 - s * (gearLen + motorCan), x0 - s * motorTotal, m[2], axleY);
  color("LightGray") cylX(shaftD / 2, x0, x0 + s * shaftLen, m[2], axleY);
  fz = m[2] > 0 ? -1 : 1;
  color("White") boxB(x0 - s * (motorTotal - 1.5), x0 - s * (motorTotal - 9.5), m[2] + fz * (mR - 1.5), m[2] + fz * (mR + 3.5), axleY - 4.5, axleY + 4.5);   // 編碼器 6P 接頭水平朝車身中央
}
module head_assembly() {
  color("SlateGray") head_floor();
  color("OldLace") head_hood();
  color("OldLace") head_back();
  color("Black") inPCBFrame() translate([-esp_l / 2, -esp_t, -esp_w / 2]) cube([esp_l, esp_t, esp_w]);
  color("#222") inPCBFrame() cylY(4, 0, lensH, lensOffset, 0);
  for (s = [-1, 1]) translate([s * eyeX, hz1 + 0.6, pcbY]) rotate([-90, 0, 0]) { color("Chocolate") eye_ring(); if (s != camEye) color("#3a4550") translate([0, 0, -0.6]) pupil(); }
  if (mic_in_head) color("ForestGreen") translate([micP[0] - 5, micP[1] - 5, micP[2] - 2.8]) cube([10, 10, 1.2]);
}
module assembly() {
  ex = explode;
  color("Gray") tub();
  for (m = MOTORS) translate([0, 0, ex * 55]) motor_dummy(m);
  for (m = MOTORS) {
    s = m[0];
    for (y = [m[2], -m[2]]) translate([s * (wallOut + 0.5 + ex * 45), y, axleY]) rotate([0, s * 90, 0]) color(y == m[2] ? "Chocolate" : "Sienna") sprocket(y == m[2]);
  }
  bkx = (bayX0 + bayX1) / 2;
  if (bay) {
    color("SlateGray") translate([0, 0, ex * 40]) battery_tray();
    color("#30353d") translate([0, -ex * 150, ex * 62]) boxB(bkx - bankW / 2, bkx + bankW / 2, bayZ1 - bankSpacer - bankL, bayZ1 - bankSpacer, trayTop, trayTop + bankT);
    if (bankSpacer > 0) color("Peru") translate([bkx, bayZ1 - bankSpacer, trayTop + ex * 62]) scale([1, bankSpacer / 10, 1]) bank_spacer();
  }
  color("FireBrick") translate([0, 0, ex * 45]) boxB(drvX - drvW / 2, drvX + drvW / 2, drvZ - drvL / 2, drvZ + drvL / 2, floorTop + 4, floorTop + 5.6);
  translate([0, 0, ex * 22]) {
    color("Black") boxB(PDB[0], PDB[1], PDB[2], PDB[3], modY0, modY0 + 1.6);
    color("Silver") boxB(usbX - 4.5, usbX + 4.5, coax ? PDB[3] - 7.3 : PDB[2], coax ? PDB[3] : PDB[2] + 7.3, modY0 + 1.6, modY0 + 4.8);
    color("RoyalBlue") boxB(BUCK[0], BUCK[1], BUCK[2], BUCK[3], modY0, modY0 + buckH);
    color("Crimson") boxB(LDO[0], LDO[1], LDO[2], LDO[3], modY0, modY0 + 4);
  }
  translate([0, 0, ex * 95]) {
    color("LightSteelBlue") upper_frame();
    color("LightSlateGray") translate([0, spineZ1, spkY]) rotate([-90, 0, 0]) speaker_ring_placed();
  }
  translate([0, 0, ex * 175]) color("LightSteelBlue") neck_deck();
  translate([0, 0, ex * 150]) color("RoyalBlue", 0.8) boxB(-sv_shaftOff, sv_l - sv_shaftOff, neckZ - sv_w / 2, neckZ + sv_w / 2, servoY0, servoTop);
  translate([0, 0, ex * 120]) color("OldLace", 0.9) body_shell();
  translate([0, neckZ, pivotY + ex * 250]) rotate([0, 0, -yaw]) head_assembly();
  // 履帶（簡化成跑道形帶子）
  for (s = [-1, 1]) color("#333") translate([s * trackCx + ex * s * 85, 0, 0]) rotate([90, 0, 90]) translate([0, 0, -trackW / 2]) linear_extrude(trackW)
    difference() { offset(r = trackT / 2 + grouser) hull() for (y = [-zS, zS]) translate([y, axleY]) circle(r = Rp, $fn = 64);
                   offset(r = -trackT / 2) hull() for (y = [-zS, zS]) translate([y, axleY]) circle(r = Rp, $fn = 64); }
}
module speaker_ring_placed() { rotate([180, 0, 0]) translate([0, 0, -(spkZF + 0.8 - spineZ1)]) speaker_ring(); }

// =====================================================================
// 列印方向
// =====================================================================
module print_tub()          { translate([0, 0, -floorY]) tub(); }
module print_upper_frame()  { translate([0, 0, -deckY0]) upper_frame(); }
module print_neck_deck()    { translate([0, 0, -topY0]) neck_deck(); }
module print_body_shell()   { translate([0, 0, -bodyY0]) body_shell(); }
module print_battery_tray() { translate([0, 0, -trayY0]) battery_tray(); }
module print_head_floor()   { translate([0, 0, hFloorT]) rotate([180, 0, 0]) head_floor(); }
module print_sprocket(d)    { translate([0, 0, trackX0 - (wallOut + 0.5) + trackW]) rotate([180, 0, 0]) sprocket(d); }
module print_head_hood()    { rotate([-90, 0, 0]) translate([0, -hz1, 0]) head_hood(); }
module print_head_back()    { rotate([90, 0, 0]) translate([0, -hz0, 0]) head_back(); }

// 內部建模沿用網頁座標（x＝車子左側、y＝車頭、z＝上）。y/z 對調等於鏡像，
// 所以所有輸出統一再 mirror([1,0,0]) 一次，得到和網頁、實車同方向的零件。
module out() mirror([1, 0, 0]) children();

if (part == "assembly") out() assembly();
if (part == "tub") out() print_tub();
if (part == "sprocket") out() print_sprocket(true);
if (part == "idler") out() print_sprocket(false);
if (part == "track_link") out() translate([0, 0, trackT / 2]) track_link();
if (part == "track_links_16") out() track_links_plate(4, 4);
if (part == "battery_tray") out() print_battery_tray();
if (part == "bank_spacer") out() bank_spacer();
if (part == "upper_frame") out() print_upper_frame();
if (part == "neck_deck") out() print_neck_deck();
if (part == "body_shell") out() print_body_shell();
if (part == "speaker_ring") out() speaker_ring();
if (part == "head_floor") out() print_head_floor();
if (part == "head_hood") out() print_head_hood();
if (part == "head_back") out() print_head_back();
if (part == "eye_ring") out() translate([0, 0, 0.6]) eye_ring();
if (part == "pupil") out() pupil();
if (part == "eyelid") out() eyelid();
if (part == "fit_tol") fit_tol();            // 有字的零件不鏡射，字才不會反
if (part == "fit_motor") out() fit_motor();
if (part == "fit_hub") out() fit_hub();
if (part == "fit_track") out() fit_track();
if (part == "fit_neck") out() fit_neck();
if (part == "fit_pcb") out() fit_pcb();
if (part == "fit_drv") out() fit_drv();
if (part == "fit_insert") fit_insert();
