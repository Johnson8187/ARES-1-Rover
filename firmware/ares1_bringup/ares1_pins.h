// ARES-1 腳位定義 — GOOUUU ESP32-S3-CAM（ESP32-S3-N16R8）
//
// 已依商品圖排針絲印核對（左排：3V3 EN 4 5 6 7 15 16 17 18 8 3 46 9 10 11 12 13 14 5V；
// 右排：TX0 RX0 1 2 42 41 40 39 38 37 36 35 0 45 48 47 21 20 19 GND）。
//
// 不能用的腳：
//   - GPIO4–13、15–18：相機（與 ESP32-S3-EYE 相同對應；CameraWebServer 範例選 CAMERA_MODEL_ESP32S3_EYE）
//   - GPIO35/36/37：排針上有拉出來，但 N16R8 的 Octal PSRAM 在用，接了會當機
//   - GPIO43/44：TX0/RX0 接 CH340（TTL 口），用來燒錄與看序列埠
//   - GPIO0（BOOT）、GPIO45（Flash 電壓）：strapping，不接
// 燒錄請用「TTL」那個 USB-C。OTG 口的 GPIO19/20 已拿去接編碼器。
#pragma once

// 電源：PD 行動電源 → CH224K 誘騙 9 V → 開關 → 9V_SW（馬達）＋ Mini560 5 V（其他全部）
// 9 V 監測：9V_SW —100k— GPIO1 —33k— GND（9 V → 2.23 V；PD 沒成功只有 5 V → 1.24 V）
constexpr int PIN_V9      = 1;     // ADC1_CH0（ADC2 在 Wi-Fi 開啟時不能用）
constexpr float V9_RATIO  = (100.0f + 33.0f) / 33.0f;

// DRV8870 雙路模組（放底盤右側：端子朝車身中央、VM 在後端；VO 不接、可變電阻轉到最小）
//   OUT1/2 → 右馬達（車頭）  OUT3/4 → 左馬達（車尾）
constexpr int PIN_MR_IN1 = 47;     // 模組 IN1
constexpr int PIN_MR_IN2 = 38;     // 模組 IN2
constexpr int PIN_ML_IN1 = 14;     // 模組 IN3
constexpr int PIN_ML_IN2 = 21;     // 模組 IN4

// 霍爾編碼器（VCC 一定要 3.3 V：由 AMS1117-3.3 供電，不用驅動板 VO；每條訊號串 1 kΩ）
constexpr int PIN_ENC_LA = 19;     // 左馬達 A 相（OTG 口 D−）
constexpr int PIN_ENC_RA = 20;     // 右馬達 A 相（OTG 口 D+）
constexpr int PIN_ENC_LB = 3;      // 左馬達 B 相（選配；strapping 腳但預設 eFuse 下不影響開機）
constexpr int PIN_ENC_RB = 46;     // 右馬達 B 相（選配；⚠ 燒錄時必須為低電位，燒不進去就拔 J2）
constexpr bool USE_ENC_B = false;  // 先只用 A 相，方向取自馬達指令

// SG92R 頭部 Yaw（ESP32 直接輸出 50 Hz，不需要 LU9685 或伺服驅動板）
constexpr int PIN_SERVO  = 2;

// I2S0 全雙工：麥克風與功放共用 BCLK / WS
constexpr int PIN_I2S_BCLK = 39;   // INMP441 SCK ＋ MAX98357A BCLK
constexpr int PIN_I2S_WS   = 40;   // INMP441 WS  ＋ MAX98357A LRC
constexpr int PIN_I2S_DOUT = 41;   // → MAX98357A DIN
constexpr int PIN_I2S_DIN  = 42;   // ← INMP441 SD（L/R 接 GND＝左聲道）

// 板載 WS2812 RGB（狀態燈）
constexpr int PIN_RGB = 48;

// 機構與安全參數（與 web/index.html、cad/ares1_params.scad 相同）
constexpr int   HEAD_YAW_MAX_DEG = 45;     // 軟體限位；機械限位 ±55°
constexpr float ACCEL_LIMIT      = 2.4f;   // m/s²，穩定性計算建議值
constexpr float V9_WARN          = 8.3f;   // 9 V 掉太多：行動電源快沒電、線太細或接觸不良
constexpr float V9_STOP          = 7.0f;   // 停車：PD 沒成功（只有 5 V）或電壓崩了（DRV8870 在 6.5 V 以下欠壓）
constexpr float MOTOR_V_RATED    = 6.0f;   // JGA25-370 6 V 版，9 V 供電時 PWM 上限 = 6 / 9 ≈ 0.66
