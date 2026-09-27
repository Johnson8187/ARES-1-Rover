// ARES-1 腳位定義（ESP32-S3-CAM，鏡頭在中段、USB 在一端的 S3-WROOM CAM 類板子）
//
// !!! 待確認 !!!  以下依常見板型推估，請對照你手上板子的絲印再改：
//   - 相機腳位推估與 ESP32-S3-EYE 相同（XCLK 15、SIOD 4、SIOC 5、Y2–Y9 11/9/8/10/12/18/17/16、
//     VSYNC 6、HREF 7、PCLK 13），CameraWebServer 範例請選 CAMERA_MODEL_ESP32S3_EYE。
//   - 若板子有 SD 卡座，38/39/40 可能接 SD_CMD/CLK/D0 → 不要插 SD 卡。
//   - 若板子的板載 LED 在 GPIO2，伺服輸出時 LED 會微亮（無害）。
//   - GPIO48 很多板子接 WS2812，保留不用。
// 永遠不要用：GPIO26–37（Flash／Octal PSRAM）、19/20（原生 USB）、0/3/45/46（strapping）、
//             43/44（UART0，要看序列埠 log 的話）。
#pragma once

// 電池電壓：VBAT —100k— GPIO1 —33k— GND（8.4 V → 2.08 V）
constexpr int PIN_VBAT     = 1;    // ADC1_CH0（ADC2 在 Wi-Fi 開啟時不能用）
constexpr float VBAT_RATIO = (100.0f + 33.0f) / 33.0f;

// DRV8870 ×2（每顆馬達兩支 PWM，沒有 ENA）
constexpr int PIN_ML_IN1 = 14;     // 左馬達（車尾左側）
constexpr int PIN_ML_IN2 = 21;
constexpr int PIN_MR_IN1 = 47;     // 右馬達（車頭右側）
constexpr int PIN_MR_IN2 = 38;

// SG92R 頭部 Yaw（直接由 ESP32 輸出 50 Hz，不用 LU9685）
constexpr int PIN_SERVO  = 2;

// I2S0 全雙工：麥克風與功放共用 BCLK / WS
constexpr int PIN_I2S_BCLK = 39;   // INMP441 SCK ＋ MAX98357A BCLK
constexpr int PIN_I2S_WS   = 40;   // INMP441 WS  ＋ MAX98357A LRC
constexpr int PIN_I2S_DOUT = 41;   // → MAX98357A DIN
constexpr int PIN_I2S_DIN  = 42;   // ← INMP441 SD（L/R 接 GND＝左聲道）

// 機構與安全參數（與 web/index.html、cad/ares1_params.scad 相同）
constexpr int   HEAD_YAW_MAX_DEG = 45;     // 軟體限位；機械限位 ±55°
constexpr float ACCEL_LIMIT      = 2.4f;   // m/s²，穩定性計算建議值
constexpr float VBAT_WARN        = 6.9f;   // 提示回充
constexpr float VBAT_STOP        = 6.6f;   // 停車（DRV8870 在 6.5 V 以下欠壓）
