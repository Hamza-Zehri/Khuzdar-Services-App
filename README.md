# Khuzdar Marketplace 🏙️

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

A hyperlocal service marketplace designed specifically for the community of **Khuzdar, Balochistan**. This application connects local "Hunar-mand" (skilled people) and shopkeepers with customers through a secure, privacy-focused platform.

---

## 🌟 Key Features

### 👤 For Customers
- **Skilled Finder**: Find Electricians, Plumbers, Tailors, and more within Khuzdar.
- **Privacy First**: Contact numbers remain hidden until both parties agree to work together.
- **Real-time Chat**: Negotiate and discuss requirements via a built-in chat system.
- **Ratings & Reviews**: Share your experience to help the community.
- **Urdu/English Support**: Locally optimized language options.

### 🛠️ For Service Providers
- **Register for Free**: List yourself as an individual provider or a shopkeeper.
- **Availability Toggle**: Switch between "Available" and "Busy" with one tap.
- **Direct Lead Management**: Chat with customers and manage service requests.
- **Performance Insights**: Build your reputation through customer reviews.

---

## 🎨 Balochistan-Inspired Design
The app features a unique **Teal & Gold** theme, inspired by the rich cultural heritage and landscapes of Balochistan, providing a premium and familiar aesthetic for local users.

---

## 🛠️ Technical Stack
- **Framework**: [Flutter](https://flutter.dev) (Cross-platform)
- **Backend / Database**: [Cloud Firestore](https://firebase.google.com/products/firestore) (Real-time NoSQL)
- **Authentication**: [Firebase Auth](https://firebase.google.com/products/auth) (Phone SMS Verification)
- **Presence System**: [Firebase Realtime Database](https://firebase.google.com/products/realtime-database)
- **Media Storage**: [Firebase Storage](https://firebase.google.com/products/storage)
- **Notifications**: [Firebase Cloud Messaging (FCM)](https://firebase.google.com/products/cloud-messaging)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Firebase Project setup

### Installation
1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Place your `google-services.json` in `android/app/`.
4. Run the app using:
   ```bash
   flutter run
   ```

### Building for Production
To generate a release APK:
```bash
flutter build apk --release
```

---

## 🔗 Ecosystem
Check out the companion application:
- **[Khuzdar Admin Panel](https://github.com/Hamza-Zehri/Khuzdar-Services-Admin-Panel)**: Centralized management and verification dashboard (Deployed on Firebase Hosting).

---

## 🛡️ Security & Privacy
This application utilizes **two-way agreement logic** for contact sharing. A provider's or customer's actual phone number is encrypted and only revealed on the UI after both parties explicitly tap "Agree" within a chat session.

---
*Created with ❤️ for Khuzdar.*
