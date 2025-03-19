# Firebase Setup for Discount App

This document provides instructions on how to set up Firebase for the Discount App.

## Prerequisites

1. A Google account
2. Flutter SDK installed
3. Firebase CLI installed (optional, but recommended)

## Steps to Set Up Firebase

### 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter a project name (e.g., "Discount App")
4. Choose whether to enable Google Analytics (recommended)
5. Accept the terms and click "Create project"

### 2. Register Your App with Firebase

#### For Android:

1. In the Firebase console, click the Android icon to add an Android app
2. Enter your app's package name (e.g., `com.example.discount_app`)
3. Enter a nickname for your app (optional)
4. Enter your app's SHA-1 signing certificate (optional for now, but required for Google Sign-In)
5. Click "Register app"
6. Download the `google-services.json` file
7. Place the file in the `android/app` directory of your Flutter project

#### For iOS:

1. In the Firebase console, click the iOS icon to add an iOS app
2. Enter your app's bundle ID (e.g., `com.example.discountApp`)
3. Enter a nickname for your app (optional)
4. Enter your app's App Store ID (optional)
5. Click "Register app"
6. Download the `GoogleService-Info.plist` file
7. Place the file in the `ios/Runner` directory of your Flutter project

### 3. Configure Firebase in Your Flutter App

#### Using FlutterFire CLI (Recommended):

1. Install the FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Run the FlutterFire configure command:
   ```bash
   flutterfire configure --project=your-firebase-project-id
   ```

3. This will automatically generate the `firebase_options.dart` file with your Firebase configuration.

#### Manual Configuration (Alternative):

1. Replace the placeholder values in the `firebase_options.dart` file with your actual Firebase configuration values from the Firebase console.

### 4. Enable Authentication Methods

1. In the Firebase console, go to "Authentication" > "Sign-in method"
2. Enable the authentication methods you want to use:
   - Email/Password
   - Google
   - Facebook

#### For Google Sign-In:

1. Configure the OAuth consent screen in the Google Cloud Console
2. Add your SHA-1 certificate fingerprint to your Firebase project

#### For Facebook Sign-In:

1. Create a Facebook Developer account and register your app
2. Configure Facebook Login for your app
3. Add your Facebook App ID and App Secret to Firebase

### 5. Update Your App Code

The app code is already set up to use Firebase Authentication. You just need to:

1. Make sure you've added the correct Firebase configuration file
2. For Google Sign-In on Android, add your SHA-1 certificate to Firebase
3. For Facebook Sign-In, update your app's configuration with your Facebook App ID

## Testing Authentication

After setting up Firebase, you can test the authentication:

1. Run the app
2. Try signing in with the different methods
3. Check the Firebase Authentication console to see registered users

## Troubleshooting

- **Google Sign-In Issues**: Make sure you've added the correct SHA-1 certificate to Firebase
- **Facebook Sign-In Issues**: Verify your Facebook App ID and App Secret in Firebase
- **General Issues**: Check the Firebase documentation and Flutter Firebase plugins documentation

## Additional Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/docs/overview)
- [Firebase Authentication Documentation](https://firebase.google.com/docs/auth)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Flutter Facebook Auth](https://pub.dev/packages/flutter_facebook_auth) 