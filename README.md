# ARES-1 Rover

低成本、可在高中營隊實作的**直立式雙履帶火星探測車**。主版本 B：WALL·E 式的直立身體與可左右轉的頭，
但把工程放在前面：兩顆 JGA25-370 對角擺放、電池壓在底盤最低處、頭部伺服只負責轉不負責扛。

![CAD 組合預覽](docs/img/cad_assembly.png)

| | |
|---|---|
| 外形 | 181 × 160 × 203 mm，約 920 g，重心高 61 mm |
| 驅動 | 2 × JGA25-370（霍爾編碼器回授）＋ DRV8870 雙路，3D 列印履帶（節距 12.5、每邊 28 片） |
| 大腦／眼睛 | GOOUUU ESP32-S3-CAM 整塊裝在頭裡，真鏡頭就在右眼，跟頭一起轉 |
| 頭部 | SG92R 直接由 ESP32 驅動（不需伺服驅動板），±45°（機械限位 ±55°） |
| 聲音 | INMP441（頭部）＋ MAX98357A ＋ Ø40 喇叭，I2S 共用時脈 |
| 電源 | 2S 18650（從車尾抽屜換電池）、5 A 保險絲、5 V 降壓 |

## 內容

| 路徑 | 說明 |
|---|---|
| [`web/index.html`](web/index.html) | 互動式 3D 工程網頁（Three.js）：視角、爆炸圖、透明外殼、剖面、配線、點選規格、參數調整、干涉檢查、重心、鏡頭視野、組裝步驟 |
| [`docs/DESIGN.md`](docs/DESIGN.md) | 工程設計書：方案比較、分層、旋轉機構、穩定性、配線與 GPIO、尺寸狀態、風險、待補量清單、BOM、組裝 |
| [`cad/ares1.scad`](cad/ares1.scad) | 參數化 OpenSCAD 零件庫（與網頁同一組參數） |
| [`cad/ares1_params.scad`](cad/ares1_params.scad) | 參數檔，標記已確認／估計／待量測／設計值 |
| [`cad/stl/`](cad/stl) | 預設參數產生的 16 個 STL（全部 ≤ 155 mm，可用 180 × 180 平台） |
| [`firmware/ares1_bringup/`](firmware/ares1_bringup) | 腳位定義＋硬體上線測試程式（馬達、伺服、喇叭、麥克風、電池） |

## 快速開始

1. 用瀏覽器打開 `web/index.html`（需要網路載入 Three.js）。
2. 看「檢查」分頁的干涉與穩定性結果、「規格」分頁的待量測清單。
3. 量到新尺寸後，改網頁參數 →「產生 OpenSCAD 參數」→ 貼進 `cad/ares1_params.scad` → 執行 `cad/build_stl.sh`。

> 已依商品圖更新 ESP32-S3-CAM（GOOUUU）、JGA25-370、DRV8870、MAX98357A、INMP441、SG92R。
> 仍待量測：鏡頭實際位置、減速比、6P 編碼器線腳位、喇叭型式等，詳見 `docs/DESIGN.md` 第 11 節。量到之前先別大量列印。
