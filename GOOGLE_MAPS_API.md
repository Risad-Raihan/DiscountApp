# Setting Up Google Maps API Key for Discount Hub

To enable the location search functionality in the Discount Hub app, you'll need to set up a Google Maps API key. Follow these steps:

## Step 1: Create a Google Cloud Project

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project or select an existing one.
3. Make note of your project ID.

## Step 2: Enable the Required APIs

1. In your Google Cloud project, go to "APIs & Services" > "Library".
2. Search for and enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
   - Places API

## Step 3: Create API Key

1. Go to "APIs & Services" > "Credentials".
2. Click "Create Credentials" > "API Key".
3. A new API key will be created. Make note of this key.

## Step 4: Add Restrictions (Optional but Recommended)

1. In the API key details page, click "Edit API key".
2. Under "Application restrictions", select "Android apps" and/or "iOS apps".
3. Add your app's package name and SHA-1 certificate fingerprint (for Android).
4. Under "API restrictions", restrict the key to only the APIs you enabled in Step 2.

## Step 5: Add the API Key to Your App

### For Android:

1. Open `android/app/src/main/AndroidManifest.xml`.
2. Find the `<meta-data>` tag with `com.google.android.geo.API_KEY` and replace `YOUR_API_KEY` with your actual API key:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY" />
```

### For iOS:

1. Open `ios/Runner/AppDelegate.swift` and add:

```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

2. Update your `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location when open to show nearby discounts.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to location to show nearby discounts.</string>
```

## Step 6: Add the API Key to Environment Variables (Optional)

For extra security, consider adding your API key to the `.env` file:

```
GOOGLE_MAPS_API_KEY=YOUR_ACTUAL_API_KEY
```

And then load it in your app using Flutter dotenv.

## Troubleshooting

- If you see a gray map, check if your API key is correctly added and that the Maps SDK for Android/iOS is enabled.
- If location services aren't working, check if the relevant permissions are included in your manifests.
- Make sure billing is enabled for your Google Cloud project to use the APIs. 