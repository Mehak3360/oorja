#pragma once

// Copy this file to "secrets.h" (same folder) and fill in the real values.
// "secrets.h" is gitignored and must never be committed.

#define WIFI_SSID       "your-wifi-name"
#define WIFI_PASSWORD   "your-wifi-password"

#define API_KEY         "your-firebase-web-api-key"
#define PROJECT_ID      "your-firebase-project-id"

// Use a separate Firebase Authentication user created only for the ESP32
#define USER_EMAIL      "esp32-device-email"
#define USER_PASSWORD   "esp32-device-password"

#define DATABASE_URL    "https://your-project-default-rtdb.region.firebasedatabase.app/"