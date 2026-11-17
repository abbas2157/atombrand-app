# Store submission: Google Play and App Store

> What has to be true before the first upload, and what to enter in Play Console and App Store Connect. The signing, icon and Firebase setup is in [RELEASE.md](RELEASE.md).
> Last updated: 2026-10-07

## 1. Already done in the app

| Requirement | Where |
|---|---|
| In-app account deletion (App Store 5.1.1(v), Play account-deletion policy) | More → **Delete account** → password → `POST me/delete` |
| Privacy policy reachable in the app | Welcome → "Terms & Privacy Policy"; More → **Privacy policy** |
| No placeholder features (App Store 2.1) | Removed the dead Apple/Facebook sign-in buttons and the "Soon" rows (Bank & payouts, Team members) |
| Sign-in options that pass review (App Store 4.8) | Email/phone + password everywhere. Google is Android only, and only in builds given `GOOGLE_SERVER_CLIENT_ID` |
| iOS privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy`: no tracking; data types match §3.2 |
| iOS export compliance | `ITSAppUsesNonExemptEncryption = false` (HTTPS only), so App Store Connect doesn't ask per build |
| iOS push | `Runner.entitlements` (`aps-environment`) and `UIBackgroundModes: remote-notification` |
| iOS permission texts | Camera and Photos explain what they're used for |
| iPhone only | `TARGETED_DEVICE_FAMILY = 1`: no iPad screenshots or iPad layout review |
| Android target API | targetSdk 36 (Flutter default), which meets Play's current requirement |
| Android advertising ID | `AD_ID` permission removed in the manifest, so "Advertising ID: No" is accurate |
| Android backups | `allowBackup="false"`, so the sign-in token isn't copied to Google Drive backups |

## 2. Blockers outside the app

Do these before you submit. Reviewers test them.

1. **Backend: `POST me/delete`** ([BRAND_APP.md §8.2](../BRAND_APP.md)). Until it's live, Delete account shows a server error, and both stores reject that.
2. **Privacy policy page** (`https://atomshop.pk/privacy-policy`). It must name the Atombrand app and say:
   - what it collects (§3.2);
   - that push tokens go to Firebase;
   - how to delete an account, in the app and on the web;
   - what is kept after deletion, and for how long;
   - a contact email.

   It must be a public, non-PDF page that isn't geo-blocked.
3. **Account deletion web page.** Play also requires a URL where someone can ask for deletion without the app, for example `https://atomshop.pk/delete-account`. A short form, or instructions with a support email, is enough. It must name "Atombrand / AtomShop", list the steps, and say what is deleted and what is kept.
4. **Review account.** Create an active brand login, for example `appreview@atomshop.pk`, and set it up with:
   - a published brand page and a few products (live and pending);
   - at least one cash retail order and one bulk request.

   Don't block it or delete it while a review is open. Reviewers may test Delete account, so keep a second login ready, or be ready to restore it.
5. **Developer accounts.**
   - **Play:** register as an **organization** (needs a D-U-N-S number). New *personal* accounts must run a closed test with 12+ testers for 14 days before they can publish to production.
   - **Apple:** an Apple Developer Program membership as an organization (also D-U-N-S). The seller name shown on the store is the legal entity.
6. **Signing and Firebase:** [RELEASE.md](RELEASE.md) §1 (upload keystore) and §3 (Firebase, APNs key). The iOS App ID `pk.atomshop.atombrandApp` needs the Push Notifications capability. Automatic signing in Xcode adds it.
7. **A Mac for iOS builds.** Building and uploading an iOS app needs macOS: a Mac with Xcode, or a macOS CI runner (Codemagic, GitHub Actions `macos-latest`).

## 3. Google Play Console

### 3.1 App content (Policy → App content)

| Section | Answer |
|---|---|
| Privacy policy | `https://atomshop.pk/privacy-policy` |
| App access | **All or some functionality is restricted.** Add the review account's login and password, with the note in §5 |
| Ads | No |
| Content rating | Category *Utility, Productivity, Communication, or Other*; answer No to violence, sexual content, gambling, etc. Users can't talk to each other in the app. Expected result: Everyone / PEGI 3 |
| Target audience | 18 and over only. Not designed for children |
| News app | No |
| Data safety | §3.2 |
| Advertising ID | No |
| Government app | No |
| Financial features | None. The app doesn't lend, take payments or hold money; instalments happen on AtomShop.pk. If Play disagrees, choose the option closest to "other/merchant tools" |
| Health | No |
| Account deletion | Yes. In-app: More → Delete account. Web URL: the page from §2.3 |

### 3.2 Data safety (also the App Store "App Privacy" answers)

Collected: **yes**. Shared with third parties: **no** (Firebase is a service provider, which isn't "sharing"). Encrypted in transit: **yes**. Users can request deletion: **yes**.

| Data type (Play / Apple name) | Why | Required? | Notes |
|---|---|---|---|
| Name | App functionality, account management | Required | Profile, partner application |
| Email address | App functionality, account management | Required | Sign-in, password reset |
| Phone number | App functionality, account management | Required | Sign-in, WhatsApp codes |
| Other info / User ID | Account management | Required | Brand account ID, company name, website |
| Photos | App functionality | Optional | Product images, logo, banner, delivery proof. Only the photos the user picks |
| Other user-generated content | App functionality | Optional | Product details, brand story, bulk-request comments |
| Device or other IDs | App functionality (push) | Required | Firebase push token |

Not collected: location, contacts, financial info, health, messages, audio, files, browsing history, crash logs, diagnostics, advertising ID.

Apple: every type is **linked to the user**, **not used for tracking**, purpose **App Functionality**. This must match `ios/Runner/PrivacyInfo.xcprivacy`. Update both together.

### 3.3 Store listing

| Field | Value |
|---|---|
| App name (≤30) | Atombrand |
| Short description (≤80) | Orders, bulk enquiries and your catalogue for AtomShop brand partners. |
| Category | Business |
| Contact | Support email, `https://atomshop.pk` |
| App icon | 512×512 PNG. Export it from `assets/brand/launcher_icon.png` |
| Feature graphic | 1024×500 PNG/JPG, required |
| Phone screenshots | 2–8, at least 1080 px on the short side, 9:16. Take them with the review account (§2.4), not real customer data |

Full description draft (≤4000):

> Atombrand is the mobile app for brands that sell on AtomShop.pk, Pakistan's Buy Now, Pay Later marketplace.
>
> • See today's orders, open bulk enquiries and top products at a glance
> • Confirm, deliver or cancel retail orders, with proof-of-delivery photos
> • Reply to bulk enquiries and track each lead from new to won
> • Add and edit products, set stock and mark items out of stock
> • Update your public brand page: logo, banner, story and promo slides
> • Get a notification the moment a new order or enquiry comes in
>
> Atombrand is for approved AtomShop brand partners. New brands can apply in the app with "Become a partner".

### 3.4 Release

1. Build: `flutter build appbundle --release`. Add `--dart-define=GOOGLE_SERVER_CLIENT_ID=…` only once `POST auth/google` is live; without it the Google button is hidden.
2. Upload `build/app/outputs/bundle/release/app-release.aab` to **Internal testing** first, with **Play App Signing** on.
3. Open the pre-launch report and fix any crashes. Then promote the release to **Production** (or to a closed test, for a personal account).
4. Every upload needs a higher build number: bump `version: 1.0.0+N` in `pubspec.yaml`.

## 4. App Store Connect

### 4.1 App information

| Field | Value |
|---|---|
| Name (≤30) | Atombrand (must be unused on the store) |
| Subtitle (≤30) | Sell on AtomShop |
| Bundle ID | `pk.atomshop.atombrandApp` |
| Primary category | Business |
| Age rating | Answer "None" to everything; no unrestricted web access, no user chat. Expected result: 4+ |
| Content rights | No third-party content |
| Privacy policy URL | `https://atomshop.pk/privacy-policy` |
| App Privacy | §3.2 |
| Price | Free. No in-app purchase is needed: the app sells physical goods and digital services aren't involved (guideline 3.1.3(e)) |

### 4.2 Version page

- **Screenshots:** iPhone 6.9" (1320×2868 or 1290×2796), 1–10. Smaller sizes are scaled from these. iPhone only, so no iPad set.
- Promotional text, the description from §3.3, keywords (≤100 chars, for example `brand,seller,orders,catalogue,inventory,atomshop,bnpl,merchant,bulk`), support URL, marketing URL.
- **Build:** `flutter build ipa --release` on a Mac. Upload `build/ios/ipa/*.ipa` with Transporter, or Xcode → Organizer → Distribute. No export compliance prompt appears (see §1).

### 4.3 App Review information

- **Sign-in required:** yes. Enter the review account (§2.4).
- **Notes:** use the text in §5.
- **Contact:** a person who can answer within a day.

## 5. Notes for reviewers (both stores)

> Atombrand is a business tool for brands that sell on AtomShop.pk. AtomShop creates an account for each approved brand partner, so there is no open sign-up. New brands apply with "Become a partner", which sends an application for AtomShop to review.
>
> Demo account: <email> / <password>. It is a test brand with sample products, orders and bulk enquiries.
>
> Account deletion: More (bottom tab) → Delete account → enter the password.
> Privacy policy: More → Privacy policy.
>
> The app doesn't sell digital goods. Products are physical items sold on AtomShop.pk.

## 6. Before each submission

- [ ] `flutter analyze` and `flutter test` pass.
- [ ] Build number bumped in `pubspec.yaml`.
- [ ] Release signing used, not the debug key (no "key.properties not found" warning in `flutter build appbundle -v`).
- [ ] Review account signs in, and Delete account works against the live server (try it on a spare login).
- [ ] Privacy policy and deletion URLs open in a browser while signed out.
- [ ] Data safety / App Privacy answers still match `PrivacyInfo.xcprivacy` after any new feature or SDK.
