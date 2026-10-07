# Atombrand

Flutter app for AtomShop brand partners: orders, bulk enquiries, catalogue, inventory and brand page on mobile.
The product spec, design system and API contract are in [BRAND_APP.md](BRAND_APP.md).

## Run

```sh
flutter pub get
# Production API (default)
flutter run
# Local backend (XAMPP/Laragon) on your LAN
flutter run --dart-define=API_BASE=http://192.168.1.20/atomshop/api/brand-app
```

On local/testing servers the code responses (forgot password, partner application) include `debug_code`; debug builds show it on the code screen so you can test without WhatsApp.
Debug builds allow plain `http` for this; release builds do not.

Sign in with Google is off unless you pass the OAuth **Web** client ID: `--dart-define=GOOGLE_SERVER_CLIENT_ID=<id>.apps.googleusercontent.com`. Setup and the server endpoint it needs: [docs/GOOGLE_SIGN_IN.md](docs/GOOGLE_SIGN_IN.md).

```sh
flutter analyze
flutter test
```

## Layout

```
lib/
  core/       api_client (dio + envelope + 401/403 handling), session, router, theme, formatters, images, push
  data/       models/ (hand-written fromJson), repositories/ (one per API area)
  features/   auth, shell, dashboard, orders, bulk, catalogue, brand_page, profile
  widgets/    status_badge, stat_card, code_input, paged_list, common (cards, banners, empty states), feedback
```

State is Riverpod 3, routing is go_router with an auth redirect (`core/router.dart`).

## Not done yet

- **Push (F12):** built on `firebase_messaging`, but off until the Firebase config files are added
  (`google-services.json`, `GoogleService-Info.plist`). See [docs/RELEASE.md](docs/RELEASE.md) §3.
- **Release signing:** needs `android/key.properties` and the upload keystore ([docs/RELEASE.md](docs/RELEASE.md) §1).
- **Store submission:** compliance status, Data safety / App Privacy answers and review notes in [docs/STORE_SUBMISSION.md](docs/STORE_SUBMISSION.md).
- **Splash artwork:** the native launch screen is still plain white. The launcher icon is done.
