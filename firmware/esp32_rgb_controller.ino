#include <Wire.h>
#include <U8g2lib.h>
#include <WiFi.h>
#include <time.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Preferences.h>

// === OLED Display ===
U8G2_SSD1306_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, /* reset=*/U8X8_PIN_NONE);

// === Wi-Fi Settings ===
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const long gmtOffset_sec    = 3 * 3600;
const int daylightOffset_sec = 0;

// === BLE UUIDs ===
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// === BLE Objects ===
BLECharacteristic* pCharacteristic;
BLEAdvertising* pAdvertising;

// === Pin Definitions ===
const int redPin   = 25;
const int greenPin = 26;
const int bluePin  = 27;
const int pirPin   = 13;
const int lightSensorPin = 34; // ADC pin for light sensor

// === Light Sensor Thresholds ===
const int lightThresholdLow  = 1250;  // below this is considered dark
const int lightThresholdHigh = 1500;  // above this is considered bright

// === State Variables ===
bool lightSensorEnabled = false;

// === Color Variables ===
uint8_t currentR = 255, currentG = 255, currentB = 255;
uint8_t savedR   = 255, savedG   = 255, savedB   = 255;
uint8_t lastR    = 255, lastG    = 255, lastB    = 255;  // for restoring after offTime

bool inMotionEffect      = false;
bool motionEffectEnabled = false;
unsigned long motionStartTime    = 0;
const unsigned long motionEffectDuration = 5000;

// === Timer Settings ===
bool     timerEnabled      = false;
int      onHour   = 7,   onMinute = 0;
int      offHour  = 23,  offMinute = 0;
uint8_t  activeDays = 0b01111110; // Tue–Sat

bool     isLightOnByTimer  = false;
bool     manualOverride    = false;
bool     activeTimerWindow = false;

Preferences prefs;

// === Apply RGB Color ===
void applyColor(uint8_t r, uint8_t g, uint8_t b) {
  ledcWrite(0, 255 - r);
  ledcWrite(1, 255 - g);
  ledcWrite(2, 255 - b);
}

// === BLE Characteristic Write Callback ===
class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) override {
    std::string value = pCharacteristic->getValue();

    // Motion effect commands
    if (value.length() == 1 && (uint8_t)value[0] == 0xA1) {
      motionEffectEnabled = true;
      return;
    }
    if (value.length() == 1 && (uint8_t)value[0] == 0xA0) {
      motionEffectEnabled = false;
      return;
    }

    // Light sensor control on/off
    if (value.length() == 1 && (uint8_t)value[0] == 0xB1) {
      lightSensorEnabled = true;
      Serial.println("Light sensor ENABLED");
      return;
    }
    if (value.length() == 1 && (uint8_t)value[0] == 0xB0) {
      lightSensorEnabled = false;
      Serial.println("Light sensor DISABLED");
      return;
    }

    // Timer enable/disable
    if (value.length() == 1 && (uint8_t)value[0] == 0xF0) {
      timerEnabled = true;
      prefs.putBool("timer", true);
      Serial.println("Timer ENABLED via BLE");
      return;
    }
    if (value.length() == 1 && (uint8_t)value[0] == 0xF1) {
      timerEnabled = false;
      prefs.putBool("timer", false);
      Serial.println("Timer DISABLED via BLE");
      return;
    }

    // Set ON time
    if (value.length() == 3 && value[0] == 0xF2) {
      onHour   = value[1];
      onMinute = value[2];
      prefs.putUChar("onH", onHour);
      prefs.putUChar("onM", onMinute);
      return;
    }
    // Set OFF time
    if (value.length() == 3 && value[0] == 0xF3) {
      offHour   = value[1];
      offMinute = value[2];
      prefs.putUChar("offH", offHour);
      prefs.putUChar("offM", offMinute);
      return;
    }
    // Set active days bitmask
    if (value.length() == 2 && value[0] == 0xF4) {
      activeDays = value[1];
      prefs.putUChar("days", activeDays);
      return;
    }

    // Color data from client
    if (value.length() == 3 && !inMotionEffect) {
      currentR = value[0];
      currentG = value[1];
      currentB = value[2];
      manualOverride = true;

      // Save if not black
      if (!(currentR == 0 && currentG == 0 && currentB == 0)) {
        prefs.putUChar("r", currentR);
        prefs.putUChar("g", currentG);
        prefs.putUChar("b", currentB);
      }

      // Always update last color
      lastR = currentR;
      lastG = currentG;
      lastB = currentB;

      // Prevent applying color between off and next on times
      if (timerEnabled && !activeTimerWindow) {
        Serial.println("Color saved but NOT applied (timer off)");
      } else {
        applyColor(currentR, currentG, currentB);
        Serial.println("Manual color applied");
      }
    }
  }
};

// === BLE Server Callbacks ===
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    Serial.println("Client connected");
  }
  void onDisconnect(BLEServer* pServer) override {
    Serial.println("Client disconnected, restarting advertising");
    delay(500);
    BLEDevice::startAdvertising();
  }
};

// === Wi-Fi and Time Setup ===
void connectToWiFi() {
  WiFi.begin(ssid, password);
  int retries = 0;
  while (WiFi.status() != WL_CONNECTED && retries++ < 20) {
    delay(500);
    Serial.print(".");
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWi-Fi connected");
    configTime(gmtOffset_sec, daylightOffset_sec, "pool.ntp.org");
  } else {
    Serial.println("\nWi-Fi connection failed");
  }
}

// === Timer Logic ===
#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c"
#define BYTE_TO_BINARY(byte)  \
  ((byte)&0x80? '1':'0'), \
  ((byte)&0x40? '1':'0'), \
  ((byte)&0x20? '1':'0'), \
  ((byte)&0x10? '1':'0'), \
  ((byte)&0x08? '1':'0'), \
  ((byte)&0x04? '1':'0'), \
  ((byte)&0x02? '1':'0'), \
  ((byte)&0x01? '1':'0')

void checkTimerTrigger() {
  if (!timerEnabled) {
    Serial.println("Timer is disabled");
    return;
  }

  struct tm timeInfo;
  if (!getLocalTime(&timeInfo)) {
    Serial.println("Failed to obtain time");
    return;
  }
  int hour    = timeInfo.tm_hour;
  int minute  = timeInfo.tm_min;
  int weekday = (timeInfo.tm_wday + 6) % 7;

  activeTimerWindow =
    (hour > onHour || (hour == onHour && minute >= onMinute)) &&
    (hour < offHour || (hour == offHour && minute < offMinute));

  Serial.printf("Current time: %02d:%02d, weekday: %d\n", hour, minute, weekday);
  Serial.printf("Active days mask: 0b" BYTE_TO_BINARY_PATTERN "\n", BYTE_TO_BINARY(activeDays));
  Serial.printf("On time: %02d:%02d | Off time: %02d:%02d\n", onHour, onMinute, offHour, offMinute);

  if (!(activeDays & (1 << weekday))) {
    Serial.println("Today is not an active day");
    return;
  }

  if (hour == onHour && minute == onMinute && !isLightOnByTimer) {
    manualOverride   = false;
    applyColor(lastR, lastG, lastB);
    isLightOnByTimer = true;
    Serial.printf("Timer ON: R=%d G=%d B=%d\n", lastR, lastG, lastB);
  } else if (hour == offHour && minute == offMinute && isLightOnByTimer) {
    manualOverride   = false;
    lastR = currentR; lastG = currentG; lastB = currentB;
    applyColor(0, 0, 0);
    isLightOnByTimer = false;
    Serial.printf("Timer OFF. Saved color: R=%d G=%d B=%d\n", lastR, lastG, lastB);
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(pirPin, INPUT);
  Wire.begin(19, 18);

  u8g2.begin();
  u8g2.clearBuffer();
  u8g2.setFont(u8g2_font_ncenB08_tr);
  u8g2.drawStr(20, 35, "Welcome");
  u8g2.sendBuffer();

  ledcAttachPin(redPin, 0); ledcSetup(0, 5000, 8);
  ledcAttachPin(greenPin, 1); ledcSetup(1, 5000, 8);
  ledcAttachPin(bluePin, 2); ledcSetup(2, 5000, 8);

  prefs.begin("color", false);
  currentR     = prefs.getUChar("r", 255);
  currentG     = prefs.getUChar("g", 255);
  currentB     = prefs.getUChar("b", 255);
  lastR = currentR; lastG = currentG; lastB = currentB;
  timerEnabled = prefs.getBool("timer", false);
  onHour   = prefs.getUChar("onH", 7);
  onMinute = prefs.getUChar("onM", 0);
  offHour  = prefs.getUChar("offH", 23);
  offMinute= prefs.getUChar("offM", 0);
  activeDays= prefs.getUChar("days", 0b01111110);
  prefs.end();

  applyColor(currentR, currentG, currentB);
  connectToWiFi();

  BLEDevice::init("ESP32_RGB_CONTROL");
  BLEServer* pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE
  );
  pCharacteristic->setCallbacks(new MyCallbacks());

  uint8_t initColor[3] = { currentR, currentG, currentB };
  pCharacteristic->setValue(initColor, 3);

  pService->start();
  pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->start();

  Serial.println("BLE advertising started");
}

void loop() {
  static unsigned long lastCheck = 0;
  if (millis() - lastCheck > 60000) {
    checkTimerTrigger();
    lastCheck = millis();
  }

  int motion = digitalRead(pirPin);
  if (motionEffectEnabled && motion == HIGH && !inMotionEffect) {
    inMotionEffect = true;
    savedR = currentR; savedG = currentG; savedB = currentB;
    applyColor(currentR, currentG, currentB);
    motionStartTime = millis();
  }
  if (inMotionEffect && millis() - motionStartTime > motionEffectDuration) {
    applyColor(savedR, savedG, savedB);
    inMotionEffect = false;
  }

  static unsigned long lastLightCheck = 0;
  const unsigned long checkInterval = 500; // check every 0.5 seconds

  if (lightSensorEnabled && millis() - lastLightCheck >= checkInterval) {
    lastLightCheck = millis();
    int lightValue = analogRead(lightSensorPin);
    Serial.printf("Light level = %d\n", lightValue);

    if (lightValue <= lightThresholdLow) {
      applyColor(currentR, currentG, currentB);
      Serial.printf("Sensor triggered dark: applying current color R=%d G=%d B=%d\n", currentR, currentG, currentB);
    } else if (lightValue >= lightThresholdHigh) {
      applyColor(currentR, currentG, currentB);
      Serial.printf("Sensor triggered bright: applying current color R=%d G=%d B=%d\n", currentR, currentG, currentB);
    }
  }
}
