// ARES-1 硬體上線測試（Arduino-ESP32 核心 3.x）
//
// ⚠ 這支程式「還沒有在實機上編譯測試過」，腳位全部依推估板型，
//    請先對照 ares1_pins.h 的說明確認你的 ESP32-S3-CAM 絲印再上傳。
//
// 電源是學員自備的 PD 行動電源 → CH224K 誘騙 9 V。注意：
//   - CH224K 第一次一定要先單獨量到 9.0 V 再接上車（出廠常是 20 V）。
//   - 9 V 不會隨行動電源電量慢慢掉；電量看行動電源自己的燈。GPIO1 量的是「PD 有沒有成功」。
//   - 行動電源電流太小會自動關機，所以這支程式不用 deep sleep。
//
// Arduino IDE 設定：開發板選 ESP32S3 Dev Module、Flash 16MB、PSRAM 選 OPI PSRAM、
//   USB CDC On Boot = Disabled，接「TTL」那個 USB-C 上傳（OTG 口的腳位拿去接編碼器了）。
//
// 序列埠指令（115200）：
//   w / s / a / d  前進／後退／左轉／右轉（放開不會自己停，按空白鍵停）
//   空白           停車
//   h              頭部 ±45° 掃描一次        c  頭部置中
//   t              喇叭嗶一聲                m  麥克風音量條 3 秒
//   b              讀 9 V 電源               e  編碼器計數與轉速（按一次印 3 秒）
#include <Arduino.h>
#include <ESP_I2S.h>
#include "ares1_pins.h"

// ---------------- 馬達（DRV8870：IN1=PWM、IN2=0 前進；反過來後退；兩腳 0 滑行） ----------------
constexpr uint32_t MOTOR_FREQ = 20000;   // 20 kHz，聽不到嘯叫
constexpr uint8_t  MOTOR_RES  = 10;      // 0–1023
constexpr float    MOTOR_MAX  = 0.66f;   // 6 V 馬達接 9 V：平均 ≈ 6 V。不要拿掉，馬達會過熱
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

// ---------------- 堵轉保護（20 W 行動電源撐不住兩邊同時堵轉） ----------------
// 指令 > 30% 但編碼器 0.3 s 都沒有脈衝 → 卡住了（或編碼器沒接），兩邊一起斷電。
constexpr bool     STALL_GUARD = true;     // 編碼器還沒接好時先改成 false
constexpr uint32_t STALL_MS    = 300;
constexpr float    STALL_CMD   = 0.30f;

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

// ---------------- 霍爾編碼器（先只數 A 相，方向取自馬達指令） ----------------
volatile uint32_t encL = 0, encR = 0;
void IRAM_ATTR isrEncL() { encL++; }
void IRAM_ATTR isrEncR() { encR++; }

void encoderBegin() {
  pinMode(PIN_ENC_LA, INPUT);            // 編碼器板本身有上拉；3.3 V 供電
  pinMode(PIN_ENC_RA, INPUT);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_LA), isrEncL, RISING);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_RA), isrEncR, RISING);
}

// ---------------- 狀態燈（板載 WS2812） ----------------
void statusLed(uint8_t r, uint8_t g, uint8_t b) { rgbLedWrite(PIN_RGB, r, g, b); }

bool stalled(float cur, volatile uint32_t &enc, uint32_t &last, uint32_t &t0, uint32_t now) {
  uint32_t e = enc;
  if (fabsf(cur) < STALL_CMD || e != last) { last = e; t0 = now; return false; }
  return now - t0 > STALL_MS;
}

// ---------------- 9 V 電源 ----------------
float readV9() {
  uint32_t mv = 0;
  for (int i = 0; i < 16; i++) mv += analogReadMilliVolts(PIN_V9);
  return mv / 16.0f / 1000.0f * V9_RATIO;
}
void powerReport(float v) {
  if (v < 3.0f)          Serial.printf("9 V = %.2f V：沒有接行動電源（只有 USB 供電，馬達不會動）\n", v);
  else if (v < V9_STOP)  Serial.printf("9 V = %.2f V：PD 沒成功！換一條 C-to-C 線，或換支援 PD（9V⎓2A）的行動電源\n", v);
  else if (v < V9_WARN)  Serial.printf("9 V = %.2f V：偏低，檢查接線或行動電源快沒電了\n", v);
  else                   Serial.printf("9 V = %.2f V：正常\n", v);
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
  encoderBegin();
  statusLed(0, 8, 0);
  bool ok = audioBegin();
  Serial.printf("\nARES-1 上線測試  I2S=%s\n", ok ? "OK" : "失敗（檢查腳位）");
  powerReport(readV9());
  Serial.println("w/s/a/d 移動、空白停、h 掃頭、c 置中、t 嗶聲、m 麥克風、b 9 V 電源、e 編碼器");
  if (ok) beep(1200, 120);
}

void loop() {
  static uint32_t last = millis(), lastBat = 0;
  static uint32_t encLastL = 0, encLastR = 0, stallT0L = 0, stallT0R = 0;
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
      case 'b': powerReport(readV9()); break;
      case 'e':
        for (int i = 0; i < 6; i++) {
          uint32_t l0 = encL, r0 = encR;
          delay(500);
          Serial.printf("編碼器 左 %lu（%+.0f 脈衝/s）  右 %lu（%+.0f 脈衝/s）\n",
                        (unsigned long)encL, (encL - l0) * 2.0f * (curL >= 0 ? 1 : -1),
                        (unsigned long)encR, (encR - r0) * 2.0f * (curR >= 0 ? 1 : -1));
        }
        break;
    }
  }

  if (now - lastBat > 1000) {
    lastBat = now;
    float v = readV9();
    if (v < V9_STOP && v > 3.0f) {             // > 3 V：只接 USB 時不誤判
      tgtL = tgtR = 0;
      statusLed(16, 0, 0);
      powerReport(v);
    } else if (v < V9_WARN && v > 3.0f) {
      statusLed(12, 6, 0);
      powerReport(v);
    }
  }
  if (STALL_GUARD && (stalled(curL, encL, encLastL, stallT0L, now) | stalled(curR, encR, encLastR, stallT0R, now))) {
    tgtL = tgtR = curL = curR = 0;
    statusLed(16, 0, 8);
    Serial.println("堵轉保護：編碼器 0.3 s 沒有脈衝，已斷電（卡住了？編碼器沒接就把 STALL_GUARD 改 false）");
  }
  updateMotors(dt);
  delay(5);
}
