# VROOM 🚗💨
**AI-Powered University Ride-Sharing & Carpooling Platform**

VROOM is a smart, student-tailored ride-sharing platform developed specifically for university communities (CUET - Chittagong University of Engineering and Technology). It connects students traveling along shared transit corridors (Campus <-> 2 No Gate, New Market, GEC, Bahaddarhat, Raozan, Pahartali) to eliminate empty seats, reduce commute expenses, and provide safe, reliable campus carpooling.

---

## ✨ Key Features

- 🔐 **Institutional Security**: Student ID validation, verified driver badges, and secure emergency SOS contacts.
- 🗺️ **Interactive Route Mapping**: Custom canvas-rendered transit routes with live campus stop highlights and driver tracking.
- 🤖 **AI-Powered Fare Estimation**: Distance-calibrated fare calculation integrated with Open-Meteo weather APIs (dynamic 1.25x rain surcharge).
- 🔢 **Boarding PIN Verification**: 4-digit security PIN generated for passengers to prevent unauthorized pickups.
- 📡 **Passenger Broadcast Radar**: Real-time radar HUD broadcasting ride requests to nearby student drivers.
- 💳 **Flexible Payment Integration**: Support for bKash, Nagad digital payments, and cash split-fare confirmation.

---

## 🛠️ Architecture & Tech Stack

- **Frontend**: Flutter (Dart 3), Provider pattern for reactive state management.
- **Backend**: Node.js, Express, NeonDB (PostgreSQL serverless), Vercel serverless functions.
- **AI / Services**: Gemini API fare intelligence, Open-Meteo weather API.

---

## 👥 Development Team

- **Md Redwan Mahmud (Red1)** ([@R3d1m](https://github.com/R3d1m)) - *Team Lead, App Architecture, State Management & Rider Workflow*
- **Syed Juman Al Mahmoud** ([@syed-juman](https://github.com/syed-juman)) - *Backend Development, NeonDB Schema & REST API Integration*
- **Khondoker Mubinul Islam Albab** ([@scattered-sand](https://github.com/scattered-sand)) - *Frontend Development, Campus UI Screens & Interactive Widgets*
