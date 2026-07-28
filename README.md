# OORJA

**Efficient Energy. Intelligent Living.**

OORJA is an AI-powered Flutter application that helps Indian households understand, estimate, and optimize their electricity consumption. Users configure their home, add rooms and appliances, and get real-time estimates of their monthly energy usage, cost, and personalized AI-driven recommendations to save energy.

Built as a final-year B.Tech Computer Science capstone project.

---

## Features

- **Authentication** — Email/password login and registration with Firebase Auth
- **Home Setup** — Configure house type, family size, city, electricity provider, budget, and tariff
- **Rooms & Appliances** — Full CRUD for rooms and appliances with real-time Firestore sync and form validation
- **Dashboard**
  - Estimated monthly bill and units
  - Budget progress tracker
  - Energy Health Score
  - Room-wise consumption pie chart
  - Weekly usage trend bar chart
  - Top energy-consuming appliances
- **AI Insights** — Personalized, data-driven energy-saving recommendations (Gemini-powered, with a demo-mode fallback)
- **Energy Report** — Full monthly report covering home summary, budget summary, room-wise breakdown, top 5 appliances, energy health score, and carbon footprint
- **PDF Export** — Export and share the energy report as a PDF
- **Demo Data Generator** — One-tap generation of 6 rooms and ~20 realistic appliances for quick demos
- **Profile** — Full edit support for user and home details, plus logout

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| State Management | Provider |
| Backend | Firebase Authentication, Cloud Firestore |
| AI | Google Gemini API |
| Charts | fl_chart |
| PDF | pdf, printing |
| Local Dev | Firebase Emulator Suite |

---

## Architecture

- **MVVM-inspired** structure with a clear separation of concerns:
  - `models/` — data classes (`UserModel`, `HomeModel`, `RoomModel`, `ApplianceModel`, `ReportModel`, etc.)
  - `services/` — external integrations (`AuthService`, `GeminiService`, `PdfService`)
  - `repositories/` — Firestore read/write logic per collection
  - `providers/` — `ChangeNotifier`-based state management, one per feature area
  - `screens/` — UI screens
  - `utils/` — `CalculationEngine` (energy/cost/health-score math) and `DemoDataGenerator`
- All energy calculations (units, cost, health score, carbon footprint) are computed **locally** — Gemini is used only for generating natural-language recommendations, never for numeric calculations.

---

## Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- Node.js + Firebase CLI
- A Firebase project with Authentication and Firestore enabled
- A Gemini API key from [Google AI Studio](https://aistudio.google.com/apikey)

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/Mehak3360/oorja.git
   cd oorja
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Add your Gemini API key**
   Create a `.env` file in the project root:
   ```
   GEMINI_API_KEY=your_key_here
   ```

4. **Firebase setup**
   - Run `firebase login`
   - Confirm `firebase_options.dart` exists in `lib/` (generated via `flutterfire configure` if missing)

5. **Run with the Firebase Emulator Suite** (recommended for local development — no billing required)

   Terminal 1:
   ```bash
   firebase emulators:start
   ```

   Terminal 2:
   ```bash
   flutter run
   ```

6. **Try it out**
   - Register a new account
   - Complete home setup
   - Use **Generate Demo Data** on the Profile screen for a quick, realistic dataset
   - Explore the Dashboard, AI Insights, and Energy Report

---

## Project Structure

```
lib/
├── models/
├── services/
├── repositories/
├── providers/
├── screens/
├── theme/
├── utils/
├── firebase_options.dart
└── main.dart
```

---

## Team

Built by a two-person team with a clear backend/frontend split:
- **Backend** — Firebase architecture, models, services, repositories, state management, Gemini integration
- **Frontend** — UI/UX, screens, navigation, charts, PDF export

---

## Future Scope

The following were intentionally left out of this version and are documented as future enhancements:
- IoT integration (smart plugs, smart meters)
- OCR-based electricity bill scanning
- Voice assistant integration
- Weather-based usage correlation
- Solar optimization suggestions
- Community/social features