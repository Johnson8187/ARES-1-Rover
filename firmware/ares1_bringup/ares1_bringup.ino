// ARES-1 硬體上線測試（Arduino-ESP32 核心 3.x）
//
// ⚠ 這支程式「還沒有在實機上編譯測試過」，腳位全部依推估板型，
//    請先對照 ares1_pins.h 的說明確認你的 ESP32-S3-CAM 絲印再上傳。
//
// Arduino IDE 設定：開發板選 ESP32S3 Dev Module、PSRAM 選 OPI PSRAM、
//   用原生 USB 那個孔上傳時請開 USB CDC On Boot。
//
// 序列埠指令（115200）：
//   w / s / a / d  前進／後退／左轉／右轉（放開不會自己停，按空白鍵停）
//   空白           停車
//   h              頭部 ±45° 掃描一次        c  頭部置中
//   t              喇叭嗶一聲                m  麥克風音量條 3 秒
//   b              讀電池電壓
#include <Arduino.h>
#include <ESP_I2S.h>
#include "ares1_pins.h"

// ---------------- 馬達（DRV8870：IN1=PWM、IN2=0 前進；反過來後退；兩腳 0 滑行） ----------------
constexpr uint32_t MOTOR_FREQ = 20000;   // 20 kHz，聽不到嘯叫
constexpr uint8_t  MOTOR_RES  = 10;      // 0–1023
constexpr float    MOTOR_MAX  = 0.70f;   // 馬達電壓規格未確認前先限 70%（6 V 版在 8.4 V 屬超壓）
constexpr float    RAMP_PER_S = 4.0f;    // 0→全速 0.25 s，遠低於穩定性分析的 2.4 m/s² 上限
constexpr bool     INVERT_L   = false;   // 裝好後方向相反就改這兩個
constexpr bool     INVERT_R   = true;    // 左右馬達鏡像安裝，右邊預設反轉

float curL = 0, curR = 0, tgtL = 0, tgtR = 0;

void motorWrite(int in1, int in2, float v) {
  v = constrain(v, -1.0f, 1.0f) * MOTOR_MAX;
  uint32_t duty = (uint32_t)(fabsf(v) * ((1 << MOTOR_RES) - 1));
  if (v > 0.01f)       { ledcWrite(in1, duty); ledcWrite(in2, 0); }
  else if (v < -0.01f) { ledcWrite(in1, 0);    ledcWrite(in2, duty); }
  else                 { ledcWrite(in1, 0);    ledcWrite(in2, 0); }
}

void updateMotors(float dt) {
  auto step = [dt](float &cur, float tgt) {
    float d = tgt - cur, m = RAMP_PER_S * dt;
    cur += constrain(d, -m, m);
  };
  step(curL, tgtL);
  step(curR, tgtR);
  motorWrite(PIN_ML_IN1, PIN_ML_IN2, INVERT_L ? -curL : curL);
  motorWrite(PIN_MR_IN1, PIN_MR_IN2, INVERT_R ? -curR : curR);
}

// ---------------- 頭部伺服 SG92R ----------------
constexpr uint32_t SERVO_FREQ = 50;
constexpr uint8_t  SERVO_RES  = 14;          // 20 ms 週期 = 16384 格
constexpr int      SERVO_CENTER_US  = 1500;  // 待校正：頭正對前方時的脈寬
constexpr float    SERVO_US_PER_DEG = 10.5f; // SG9x 約 500–2400 µs 對 180°，待校正

void headYaw(float deg) {
  deg = constrain(deg, (float)-HEAD_YAW_MAX_DEG, (float)HEAD_YAW_MAX_DEG);
  float us = SERVO_CENTER_US + deg * SERVO_US_PER_DEG;   // 正值＝頭往車子左側轉；裝反就改正負號
  ledcWrite(PIN_SERVO, (uint32_t)(us / 20000.0f * ((1 << SERVO_RES) - 1)));
}

// ---------------- 電池 ----------------
float readVbat() {
  uint32_t mv = 0;
  for (int i = 0; i < 16; i++) mv += analogReadMilliVolts(PIN_VBAT);
  return mv / 16.0f / 1000.0f * VBAT_RATIO;
}

// ---------------- 音訊：I2S0 全雙工（麥克風與功放共用 BCLK/WS） ----------------
I2SClass i2s;
constexpr uint32_t SAMPLE_RATE = 16000;
int32_t audioBuf[2 * 256];                   // 立體聲 32-bit 槽位

bool audioBegin() {
  i2s.setPins(PIN_I2S_BCLK, PIN_I2S_WS, PIN_I2S_DOUT, PIN_I2S_DIN);
  return i2s.begin(I2S_MODE_STD, SAMPLE_RATE, I2S_DATA_BIT_WIDTH_32BIT, I2S_SLOT_MODE_STEREO);
}

void beep(int freq, int ms) {
  int left = SAMPLE_RATE * ms / 1000;
  float ph = 0, dph = 2 * PI * freq / SAMPLE_RATE;
  while (left > 0) {
    int k = min(left, 256);
    for (int i = 0; i < k; i++) {
      int32_t s = (int32_t)(sinf(ph) * 0.15f * 2147483647.0f);   // 15% 音量，避免電流尖峰
      audioBuf[2 * i] = s; audioBuf[2 * i + 1] = s;
      ph += dph; if (ph > 2 * PI) ph -= 2 * PI;
    }
    i2s.write((uint8_t *)audioBuf, k * 2 * sizeof(int32_t));
    left -= k;
  }
}

float micLevel() {
  size_t got = i2s.readBytes((char *)audioBuf, sizeof(audioBuf));
  int frames = got / (2 * sizeof(int32_t));
  if (frames == 0) return 0;
  double acc = 0;
  for (int i = 0; i < frames; i++) {
    float s = (audioBuf[2 * i] >> 8) / 8388608.0f;   // INMP441：24-bit 資料在 32-bit 槽位高位，左聲道
    acc += s * s;
  }
  return sqrtf(acc / frames);
}

// ---------------- 主程式 ----------------
void setup() {
  Serial.begin(115200);
  delay(300);
  ledcAttach(PIN_ML_IN1, MOTOR_FREQ, MOTOR_RES);
  ledcAttach(PIN_ML_IN2, MOTOR_FREQ, MOTOR_RES);
  ledcAttach(PIN_MR_IN1, MOTOR_FREQ, MOTOR_RES);
  ledcAttach(PIN_MR_IN2, MOTOR_FREQ, MOTOR_RES);
  updateMotors(0);
  ledcAttach(PIN_SERVO, SERVO_FREQ, SERVO_RES);
  headYaw(0);
  analogReadResolution(12);
  bool ok = audioBegin();
  Serial.printf("\nARES-1 上線測試  VBAT=%.2f V  I2S=%s\n", readVbat(), ok ? "OK" : "失敗（檢查腳位）");
  Serial.println("w/s/a/d 移動、空白停、h 掃頭、c 置中、t 嗶聲、m 麥克風、b 電池");
  if (ok) beep(1200, 120);
}

void loop() {
  static uint32_t last = millis(), lastBat = 0;
  uint32_t now = millis();
  float dt = (now - last) / 1000.0f;
  last = now;

  if (Serial.available()) {
    char c = Serial.read();
    const float V = 0.6f;
    switch (c) {
      case 'w': tgtL = V;  tgtR = V;  break;
      case 's': tgtL = -V; tgtR = -V; break;
      case 'a': tgtL = -V; tgtR = V;  break;
      case 'd': tgtL = V;  tgtR = -V; break;
      case ' ': tgtL = 0;  tgtR = 0;  break;
      case 'c': headYaw(0); break;
      case 'h':
        for (int d = 0; d <= HEAD_YAW_MAX_DEG; d += 3) { headYaw(d); delay(20); }
        for (int d = HEAD_YAW_MAX_DEG; d >= -HEAD_YAW_MAX_DEG; d -= 3) { headYaw(d); delay(20); }
        for (int d = -HEAD_YAW_MAX_DEG; d <= 0; d += 3) { headYaw(d); delay(20); }
        break;
      case 't': beep(880, 200); beep(1320, 200); break;
      case 'm':
        for (uint32_t t0 = millis(); millis() - t0 < 3000;) {
          int bars = constrain((int)(micLevel() * 400), 0, 40);
          Serial.printf("\r麥克風 |%-40.*s|", bars, "########################################");
        }
        Serial.println();
        break;
      case 'b': Serial.printf("VBAT = %.2f V\n", readVbat()); break;
    }
  }

  if (now - lastBat > 1000) {
    lastBat = now;
    float v = readVbat();
    if (v < VBAT_STOP && v > 3.0f) {           // > 3 V：只接 USB 時不誤判
      tgtL = tgtR = 0;
      Serial.printf("電池 %.2f V 過低，已停車，請換電池\n", v);
    } else if (v < VBAT_WARN && v > 3.0f) {
      Serial.printf("電池 %.2f V 偏低，準備回充\n", v);
    }
  }
  updateMotors(dt);
  delay(5);
}
