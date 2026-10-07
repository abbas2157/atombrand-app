# Release setup: signing, icons, push

> One-time setup before the first Play Store / App Store build. Without it the app still builds and runs: release builds are signed with the debug key, and push is off.
> For the store consoles (privacy, data safety, review account, listing) see [STORE_SUBMISSION.md](STORE_SUBMISSION.md).
> Last updated: 2026-10-07

## 1. Android release signing

Gradle reads `android/key.properties`. If that file doesn't exist, the release build uses the **debug** key and logs a Gradle warning (shown with `flutter build -v`). A debug-signed build can't be uploaded to Play.

1. Create the upload keystore once. Keep it and its passwords somewhere safe (a password manager, not the repo). If you lose it, Play has to reset your upload key.
   ```sh
   keytool -genkey -v -keystore %USERPROFILE%\atombrand-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties`. It's git-ignored, and so are `*.jks` and `*.keystore`:
   ```properties
   storePassword=<store password>
   keyPassword=<key password>
   keyAlias=upload
   storeFile=C:\\Users\\<you>\\atombrand-upload.jks
   ```
   `storeFile` is absolute, or relative to `android/app/`.
3. `flutter build appbundle --release --dart-define=GOOGLE_SERVER_CLIENT_ID=…`, then upload to Play with **Play App Signing** on.
4. Add the upload key's SHA-1 (and Play's app-signing SHA-1) to Google Cloud for Google sign-in ([GOOGLE_SIGN_IN.md](GOOGLE_SIGN_IN.md) §2) and to Firebase (below).

On CI, write `key.properties` and the keystore from secrets before building.

## 2. Launcher icon

The AB mark on white (DESIGN.md §1). It's already generated for Android (including the adaptive icon) and iOS. To change it:

1. `dart run tool/make_launcher_icon.dart`. This rebuilds `assets/brand/launcher_icon.png` and `launcher_foreground.png` from `assets/brand/mark.png`.
2. `dart run flutter_launcher_icons`. This writes the mipmaps and the iOS `AppIcon` set (config in `pubspec.yaml`).
3. `git checkout ios/Runner.xcodeproj/project.pbxproj`. flutter_launcher_icons 0.14 wrongly rewrites `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`.

The native launch screen (the white flash before Flutter starts) is still plain white.

## 3. Push notifications (Firebase Cloud Messaging)

The app side is built (`lib/core/push.dart`):
- It registers the FCM token with `POST fcm-token` after sign-in and whenever the token rotates.
- It asks for notification permission once the user is in the main app.
- Tapping a push opens its order, bulk request or product.
- A push that arrives while the app is open shows an in-app banner and refreshes the badges.

It switches itself on when the Firebase config files exist:

1. In the [Firebase console](https://console.firebase.google.com/), create the project (or reuse the AtomShop one) and add:
   - **Android app** `pk.atomshop.atombrand_app`, with the debug, upload and Play SHA-1s. Download `google-services.json` to `android/app/`.
   - **iOS app** `pk.atomshop.atombrandApp`. Download `GoogleService-Info.plist` to `ios/Runner/` and add it to the Runner target in Xcode.
2. iOS only: upload an APNs auth key (Firebase → Project settings → Cloud Messaging). In Xcode, add the **Push Notifications** capability and **Background Modes → Remote notifications**.
3. Server: the backend needs this project's service account to send to brands (BRAND_APP.md §8.10).

Gradle applies the `google-services` plugin only when `android/app/google-services.json` exists, and otherwise logs "push notifications are off in this build" (shown with `-v`). Decide with the backend team whether the config files are committed or injected by CI. They aren't secret, but they are environment-specific.

**To check it works:** sign in on a device, confirm a row appears in the server's FCM tokens for that user, then send a test message from the Firebase console with data `screen=product`, `product_id=<id>`.
