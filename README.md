# 🚨 Emergency Alert System App

A cross-platform (Android & Web) **Emergency Alert System** built using **Flutter** and **Firebase**, designed to instantly notify emergency contacts and nearby hospitals during medical or life-threatening situations. It ensures **real-time alerts**, **GPS location sharing**, and **reliable communication** through SMS and WhatsApp.

---

## 📱 Features

- 🆘 **Panic Button** to send instant emergency alerts.
- 📍 **Real-time GPS Location Sharing** with alert.
- 👨‍👩‍👧‍👦 **Add Up to 3 Emergency Contacts** per user.
- ✉️ **SMS & WhatsApp Notifications** to contacts.
- 🏥 **Nearby Hospital Integration** using Google Places API.
- 🧾 **Optional Health Parameter Input** (e.g., blood group, history).
- 🔐 **Authentication** via Phone Number or Google Sign-In.
- 🗺️ **Alert Tracking on Map** and ability to delete old alerts.
- ✅ Battery optimized & permission-handled design.

---

## 🧱 Tech Stack

| Layer             | Technology Used                     | Purpose |
|------------------|-------------------------------------|---------|
| **Frontend**      | Flutter                             | Cross-platform UI (Android + Web) |
| **Backend**       | Firebase Firestore                  | Real-time database for alerts and user data |
|                   | Firebase Auth                       | User authentication (Phone & Google) |
|                   | Firebase Cloud Functions + Node.js  | SMS/WhatsApp alert sending via Msg91 or Twilio |
| **Location & Maps** | Geolocator, Google Maps, Google Places API | GPS & nearby hospital integration |

---

## 🧪 System Architecture

```plaintext
User
 └── Flutter App
     ├── Auth (Firebase Auth: Phone/Google)
     ├── Panic Button
     │    ├── Get Location (Geolocator)
     │    ├── Store Alert (Firestore)
     │    └── Trigger Cloud Function (Node.js)
     │          ├── Send SMS (Msg91)
     │          └── Send WhatsApp (Twilio API)
     ├── Nearby Hospitals (Google Places API)
     ├── Health Data (Optional Input Form)
     └── Alerts Dashboard (View/Delete Alerts)
