/*******************************************************
   ESP32 - 3 CHANNEL AC CURRENT METER

   CT: 100A / 50mA
   Burden: 18 Ohm

   CT1 -> GPIO34
   CT2 -> GPIO35
   CT3 -> GPIO32

   Firebase Realtime Database:
   /current/CT1
   /current/CT2
   /current/CT3
   /current/ts   (server timestamp, used by app for offline detection)

   Upload: every 10 seconds
   No-load cutoff: below 0.10A = 0.00A

   Credentials live in secrets.h (gitignored).
   Copy secrets.example.h -> secrets.h and fill in values.
*******************************************************/

#define ENABLE_USER_AUTH
#define ENABLE_DATABASE

#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <FirebaseClient.h>
#include "secrets.h"


// =====================================================
// FIREBASE OBJECTS
// =====================================================

UserAuth user_auth(API_KEY, USER_EMAIL, USER_PASSWORD);

FirebaseApp app;

WiFiClientSecure ssl_client;

using AsyncClient = AsyncClientClass;

AsyncClient aClient(ssl_client);

RealtimeDatabase Database;


// =====================================================
// CT INPUT PINS
// =====================================================

#define CT1_PIN 34
#define CT2_PIN 35
#define CT3_PIN 32


// =====================================================
// CT PARAMETERS
// =====================================================

const float BURDEN_RESISTOR = 18.0;
const float CT_RATIO = 2000.0;


// =====================================================
// CALIBRATION
// =====================================================

const float CAL1 = 0.863;
const float CAL2 = 0.863;
const float CAL3 = 0.863;


// =====================================================
// ADC PARAMETERS
// =====================================================

const float ADC_REFERENCE = 3.3;
const float ADC_MAX = 4095.0;


// =====================================================
// SAMPLING
// =====================================================

const int OFFSET_SAMPLES = 4000;
const int RMS_SAMPLES    = 4000;


// =====================================================
// THRESHOLDS
// =====================================================

const float NOISE_THRESHOLD = 6.0;

// Anything below 0.10A is treated as zero
const float NO_LOAD_CUTOFF = 0.10;

const float MIN_VALID_OFFSET = 1500.0;
const float MAX_VALID_OFFSET = 2500.0;


// =====================================================
// AVERAGING
// =====================================================

const int CURRENT_AVERAGE_COUNT = 5;


// =====================================================
// FIREBASE SEND INTERVAL
// =====================================================

const unsigned long FIREBASE_INTERVAL = 10000;

unsigned long lastFirebaseSend = 0;


// =====================================================
// ADC OFFSETS AND CHANNEL STATUS
// =====================================================

float offset1 = 0;
float offset2 = 0;
float offset3 = 0;

bool ct1Valid = false;
bool ct2Valid = false;
bool ct3Valid = false;


// =====================================================
// FIREBASE CALLBACK
// =====================================================

void processData(AsyncResult &aResult)
{
  if (!aResult.isResult())
    return;

  if (aResult.isError())
  {
    Serial.printf(
      "Firebase error: %s, code: %d\n",
      aResult.error().message().c_str(),
      aResult.error().code()
    );
    return;
  }

  Serial.println("Firebase update successful");
}


// =====================================================
// WIFI CONNECTION
// =====================================================

void connectWiFi()
{
  Serial.println();
  Serial.println("Connecting to WiFi...");

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  while (WiFi.status() != WL_CONNECTED)
  {
    Serial.print(".");
    delay(500);
  }

  Serial.println();
  Serial.println("WiFi Connected");

  Serial.print("ESP32 IP: ");
  Serial.println(WiFi.localIP());
}


// =====================================================
// CALCULATE ADC OFFSET
// =====================================================

float calculateOffset(int pin)
{
  long long total = 0;

  for (int i = 0; i < OFFSET_SAMPLES; i++)
  {
    total += analogRead(pin);
  }

  return (float)total / OFFSET_SAMPLES;
}


// =====================================================
// CHECK OFFSET
// =====================================================

bool validOffset(float offset)
{
  return (offset >= MIN_VALID_OFFSET && offset <= MAX_VALID_OFFSET);
}


// =====================================================
// CALCULATE RMS
// =====================================================

float calculateRMS(int pin, float offset)
{
  double sumSquares = 0;

  for (int i = 0; i < RMS_SAMPLES; i++)
  {
    int adcValue = analogRead(pin);
    float sample = (float)adcValue - offset;
    sumSquares += sample * sample;
  }

  return sqrt(sumSquares / RMS_SAMPLES);
}


// =====================================================
// CALCULATE ONE CURRENT READING
// =====================================================

float calculateCurrent(
  int pin,
  float offset,
  float calibration,
  bool channelValid
)
{
  // Invalid bias
  if (!channelValid)
  {
    return 0.0;
  }

  float adcRMS = calculateRMS(pin, offset);

  // Noise filter
  if (adcRMS < NOISE_THRESHOLD)
  {
    return 0.0;
  }

  // ADC -> RMS voltage
  float voltageRMS = adcRMS * ADC_REFERENCE / ADC_MAX;

  // Burden voltage -> CT secondary current
  float secondaryCurrent = voltageRMS / BURDEN_RESISTOR;

  // CT secondary -> primary
  float primaryCurrent = secondaryCurrent * CT_RATIO;

  // Calibration
  primaryCurrent *= calibration;

  // No-load cutoff
  if (primaryCurrent < NO_LOAD_CUTOFF)
  {
    primaryCurrent = 0.0;
  }

  return primaryCurrent;
}


// =====================================================
// AVERAGE CURRENT
// =====================================================

float averageCurrent(
  int pin,
  float offset,
  float calibration,
  bool channelValid
)
{
  if (!channelValid)
  {
    return 0.0;
  }

  double total = 0;

  for (int i = 0; i < CURRENT_AVERAGE_COUNT; i++)
  {
    total += calculateCurrent(pin, offset, calibration, channelValid);
  }

  float result = total / CURRENT_AVERAGE_COUNT;

  // Final no-load cutoff after averaging
  if (result < NO_LOAD_CUTOFF)
  {
    result = 0.0;
  }

  return result;
}


// =====================================================
// SEND CT1 + CT2 + CT3 + SERVER TIMESTAMP TO FIREBASE
// One JSON update, no total load
// =====================================================

void sendToFirebase(
  float current1,
  float current2,
  float current3
)
{
  // Firebase authentication check
  if (!app.ready())
  {
    Serial.println("Firebase app not ready");
    return;
  }

  // Check async queue
  if (aClient.taskCount() >= 8)
  {
    Serial.print("Firebase busy. Queue = ");
    Serial.println(aClient.taskCount());
    return;
  }

  // "ts" is replaced by Firebase with its own server time (ms),
  // so the app can tell if the ESP32 has stopped sending.
  String jsonString =
    "{\"CT1\":" + String(current1, 2) +
    ",\"CT2\":" + String(current2, 2) +
    ",\"CT3\":" + String(current3, 2) +
    ",\"ts\":{\".sv\":\"timestamp\"}}";

  object_t json(jsonString);

  Database.update<object_t>(
    aClient,
    "/current",
    json,
    processData,
    "currentUpdate"
  );

  Serial.println("Firebase update queued");

  Serial.print("Firebase Data: ");
  Serial.println(jsonString);
}


// =====================================================
// SETUP
// =====================================================

void setup()
{
  Serial.begin(115200);

  delay(1000);

  Serial.println();
  Serial.println("=================================");
  Serial.println(" ESP32 3-CHANNEL CURRENT METER");
  Serial.println(" NO TOTAL LOAD");
  Serial.println(" FIREBASE EVERY 10 SECONDS");
  Serial.println(" NO LOAD < 0.10A = ZERO");
  Serial.println("=================================");

  // ADC
  analogReadResolution(12);

  pinMode(CT1_PIN, INPUT);
  pinMode(CT2_PIN, INPUT);
  pinMode(CT3_PIN, INPUT);

  // WiFi
  connectWiFi();

  // SSL
  ssl_client.setInsecure();

  // Firebase initialization
  Serial.println();
  Serial.println("Initializing Firebase...");

  initializeApp(
    aClient,
    app,
    getAuth(user_auth),
    processData,
    "authTask"
  );

  app.getApp<RealtimeDatabase>(Database);

  Database.url(DATABASE_URL);

  // Offset calibration
  Serial.println();
  Serial.println("Calculating ADC offsets...");
  Serial.println("Make sure there is NO current.");

  delay(2000);

  offset1 = calculateOffset(CT1_PIN);
  offset2 = calculateOffset(CT2_PIN);
  offset3 = calculateOffset(CT3_PIN);

  ct1Valid = validOffset(offset1);
  ct2Valid = validOffset(offset2);
  ct3Valid = validOffset(offset3);

  Serial.println();
  Serial.println("ADC OFFSETS:");

  Serial.print("CT1 Offset = ");
  Serial.print(offset1, 2);
  Serial.println(ct1Valid ? "  OK" : "  ERROR");

  Serial.print("CT2 Offset = ");
  Serial.print(offset2, 2);
  Serial.println(ct2Valid ? "  OK" : "  ERROR");

  Serial.print("CT3 Offset = ");
  Serial.print(offset3, 2);
  Serial.println(ct3Valid ? "  OK" : "  ERROR");

  if (!ct1Valid) Serial.println("WARNING: CT1 bias problem!");
  if (!ct2Valid) Serial.println("WARNING: CT2 bias problem!");
  if (!ct3Valid) Serial.println("WARNING: CT3 bias problem!");

  Serial.println();
  Serial.println("System Ready");
  Serial.println("Firebase Upload = Every 10 Seconds");
  Serial.println("No Load Cutoff = 0.10A");
  Serial.println("=================================");
}


// =====================================================
// LOOP
// =====================================================

void loop()
{
  // Firebase background processing
  app.loop();

  // Send every 10 seconds
  if (millis() - lastFirebaseSend >= FIREBASE_INTERVAL)
  {
    lastFirebaseSend = millis();

    float current1 = averageCurrent(CT1_PIN, offset1, CAL1, ct1Valid);
    float current2 = averageCurrent(CT2_PIN, offset2, CAL2, ct2Valid);
    float current3 = averageCurrent(CT3_PIN, offset3, CAL3, ct3Valid);

    // Serial display: same values that go to Firebase
    Serial.println();
    Serial.println("--------------------------------");

    Serial.print("CT1 Current : ");
    Serial.print(current1, 2);
    Serial.println(" A");

    Serial.print("CT2 Current : ");
    Serial.print(current2, 2);
    Serial.println(" A");

    Serial.print("CT3 Current : ");
    Serial.print(current3, 2);
    Serial.println(" A");

    Serial.println("--------------------------------");

    sendToFirebase(current1, current2, current3);
  }

  delay(10);
}