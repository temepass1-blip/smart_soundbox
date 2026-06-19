# Smart SoundBox App 🔊💸

A highly optimized Android application built with Flutter that acts as a **free, software-only alternative** to commercial UPI Soundboxes. 

Why pay a monthly subscription or rental fee for a physical soundbox when you can turn your Android phone or an old spare device into a smart, voice-announcing payment receiver?

## 🌟 Key Features

- **Multi-App Support:** Automatically intercepts notifications from **PhonePe, Google Pay (GPay), and Paytm**.
- **Bank SMS Support:** Reads incoming SMS messages to detect bank credits (e.g., SBI, HDFC).
- **Smart Duplicate Prevention:** Uses a 5-minute rolling cache. If you receive a PhonePe notification *and* a Bank SMS for the same ₹100 payment, the app is smart enough to announce it only **once**.
- **Sequential Voice Queue (FIFO):** If 10 customers pay at the exact same time, the app queues the TTS (Text-to-Speech) announcements so they don't overlap, speaking them one after another.
- **Transaction History & Analytics:** Silently logs every verified transaction into a local **SQLite** database. Features a dedicated UI to view past transactions, search by sender, and view a "Today's Collections" summary.
- **CSV Export:** One-click export of your transaction history to a CSV file for bookkeeping.
- **100% Offline & Private:** No cloud servers, no logins, no monthly fees. Your financial data never leaves your device.

## 🏗️ Technical Architecture

The app is broken down into modular core components:
1. **Notification Listener Service:** Runs in the background to capture Android notifications.
2. **Telephony SMS Receiver:** A Broadcast Receiver that listens to incoming SMS messages.
3. **Payment Parser (Regex Engine):** Extracts the `amount` and `sender` from messy notification texts while discarding promotional spam (cashbacks, loans).
4. **Transaction Manager:** The deduplication engine that compares incoming transactions against a time-based cache.
5. **Database Helper:** Manages the `sqflite` database for long-term storage.
6. **Voice Engine:** Wraps `flutter_tts` to handle Hindi language voice synthesis.

## 🚀 Installation & Setup

1. Clone this repository.
2. Ensure you have Flutter installed.
3. Run the following command to install dependencies:
   ```bash
   flutter pub get
   ```
4. Build and run the app on an Android device:
   ```bash
   flutter run
   ```

### Permissions Required
The app will prompt you for the following permissions to function correctly:
- **Notification Access:** To read payment alerts from UPI apps.
- **SMS Permissions:** To read bank credit messages.

## 🛠️ GitHub Actions (CI/CD)
This repository includes a `.github/workflows/build.yml` file. Every time code is pushed to the `main` branch, GitHub Actions will automatically build a release APK and upload it as an artifact.
