# Discount Hub

A Flutter application for discovering and managing exclusive deals and discounts.

## Features

- User authentication (Email, Google, Facebook)
- Modern and intuitive UI
- Deal discovery and management
- Password reset functionality
- Social media integration

## Getting Started

### Prerequisites

- Flutter SDK
- Firebase project setup
- Android Studio / VS Code
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Risad-Raihan/DiscountApp.git
```

2. Navigate to the project directory:
```bash
cd DiscountApp
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Contributing

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Project Structure

```
lib/
  ├── components/         # Reusable UI components
  ├── models/             # Data models and providers
  ├── screens/            # App screens
  ├── services/           # API and local storage services
  ├── styles/             # Theme and styling
  ├── utils/              # Utility functions
  └── main.dart           # Entry point
```

## Firebase Setup

This app uses Firebase for authentication. To set up Firebase for this project:

1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/)
2. Register your app with Firebase (Android/iOS)
3. Download and add the Firebase configuration files to your project
4. Enable authentication methods (Email/Password, Google, Facebook)

For detailed instructions, see the [FIREBASE_SETUP.md](FIREBASE_SETUP.md) file.

## Authentication

The app supports the following authentication methods:

- Email and password
- Google Sign-In
- Facebook Login

Users can also:
- Create a new account
- Reset their password
- Sign out

## Dependencies

- provider: ^6.0.5 - For state management
- shared_preferences: ^2.1.1 - For local storage
- http: ^1.1.0 - For API requests
- intl: ^0.18.1 - For date formatting
- flutter_svg: ^2.0.7 - For SVG support
- firebase_core: ^2.15.1 - For Firebase initialization
- firebase_auth: ^4.7.3 - For Firebase authentication
- google_sign_in: ^6.1.4 - For Google Sign-In
- flutter_facebook_auth: ^6.0.1 - For Facebook Login

## Design

The app follows Material Design guidelines with a custom color scheme. It supports both light and dark themes.

## Future Enhancements

- User authentication ✅
- Cloud synchronization
- Barcode scanner for in-store discounts
- Push notifications for expiring discounts
- Share discounts with friends 