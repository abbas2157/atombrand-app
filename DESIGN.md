# AtomBrands app: Design System

> **What this file is:** the visual language of the AtomBrands (Brand Partner) Flutter app: tokens, where they live in code, and the layout rules for each group of screens. The API contract is in [BRAND_APP.md](BRAND_APP.md); this file only covers how things look.
> Last reviewed: 2026-10-02

---

## 1. Brand

The identity comes from the **AtomBrands** logo: a charcoal **A** and a red **B** on white, with the wordmark and the tagline *Connect. Sell. Grow.*

| Asset | File | Use |
|---|---|---|
| Mark (AB monogram) | `assets/brand/mark.png` | Top bar of every auth screen (26 px high) |
| Lockup (mark + wordmark + tagline) | `assets/brand/lockup.png` | Splash and Welcome (150 px high) |

- Both are transparent PNGs cropped from the master logo. Use them **only on light surfaces**: the A and the wordmark are charcoal and vanish on dark backgrounds.
- In code, use `BrandLogo.mark()` / `BrandLogo.lockup()` (`lib/features/auth/auth_scaffold.dart`), never `Image.asset` directly.
- Don't recolour, stretch or add effects to the logo. Keep at least the height of the B's bowl as clear space around it.
- **Still to do:** the Android/iOS launcher icon and native launch screen are still Flutter defaults. They should use the mark on white.

## 2. Tokens (`lib/core/theme.dart`)

### 2.1 Colour

| Token | Hex | Use |
|---|---|---|
| `primary` | `#BE1E2D` (logo red) | Primary buttons, links, focus rings, active tab, FAB, "new" badges |
| `primarySoft` | `#BE1E2D` @ 10% | Icon tiles, selected chips/segments, nav indicator |
| `accent` | `#1B1C1E` (logo charcoal) | App bar, dark highlights |
| `ink` | `#1B1C1E` | Primary text |
| `muted` | `#64748B` | Secondary text, labels, icons at rest |
| `background` | `#F6F7FB` | Scaffold (signed in); **field fill** on auth screens |
| `surface` | `#FFFFFF` | Cards, sheets, auth screens |
| `line` | `#E2E8F0` | Dividers, outlined buttons, input borders (signed in) |

Status colours (success, warning, danger, neutral, info) are in BRAND_APP.md §4.1 and stay as they are, so a status never reads as brand red. In particular:
- **Info is blue (`#3D5DAB`)**, for info banners and "Delivered"-type badges. Never use `primary` for informational messages.
- **Danger (`#B91C1C`) is close to the brand red.** Destructive actions must therefore always say what they do ("Cancel order", "Delete"), never rely on colour alone.

### 2.2 Type
**Inter** (Google Fonts, pinned to `google_fonts` 8): 400 / 500 / 600 / 700.

| Role | Size / weight | Where |
|---|---|---|
| Auth title | 26 / 700, −0.4 tracking, 1.2 line height | `authTitleStyle()` |
| Auth subtitle | 15 / 400, 1.5 line height, `muted` | `authSubtitleStyle()` |
| Screen title (signed in) | 18 / 600 | `titleLarge` |
| Body | 14–15 / 400 | `bodyMedium` / `bodyLarge` |
| Caption | 12 / 400, `muted` | `bodySmall` |

### 2.3 Shape & spacing
- Radii: cards **16**; signed-in buttons/inputs **12**; auth buttons/inputs/code boxes **14**; icon tiles **16**; chips and badges are pills.
- 4-pt grid. Screen padding 16 (signed in) / 24 (auth). Tap targets ≥ 44 px.
- Shadows: one soft card shadow only (`cardShadow`). Auth screens use none, except the pinned action panel on Welcome (soft upward shadow).

## 3. Auth screens (signed out)

Goal: calm, roomy and unmistakably AtomBrands. White page, one red action per screen, generous spacing, soft filled fields.

### 3.1 Welcome (`welcome_screen.dart`): a brand-partner landing page
This is an e-commerce app for brands, so Welcome sells the partnership as well as letting partners in. The content **scrolls**, and the ways in stay **pinned** at the bottom.

```
 ┌ scrolls ───────────────────────────────┐
 │        [ AB lockup ]          ╱╱       │ ← faint strokes, scroll away with the hero
 │   Put your brand in orbit.             │   28/700, centred
 │   BNPL marketplace pitch (muted)       │
 │ ┌ charcoal stats card ───────────────┐ │
 │ │ ▬ AtomShop today                   │ │
 │ │ 10K+ customers   4–5K orders/month │ │
 │ │ 360+ merchants   200K+ reach       │ │
 │ └────────────────────────────────────┘ │
 │ WHY BRANDS SELL ON ATOMSHOP            │ ← AuthSectionTitle
 │ [icon] title / one line   × 6          │ ← BenefitRow
 │ HOW IT WORKS                           │
 │ ① Apply ─ ② Review ─ ③ Go live         │ ← PartnerSteps
 │ BRANDS ALREADY LIVE  (OXY) (Atom Iron) │
 │ QUESTIONS?  [WhatsApp us] [email]      │ ← from GET config, hidden if absent
 └────────────────────────────────────────┘
 ┌ pinned panel (white, top hairline + soft shadow) ┐
 │ [ Sign in ] [ G Google ]    side by side, 54 px  │
 │ New to AtomShop? Become a partner                │
 └──────────────────────────────────────────────────┘
```
- **Copy** lives in `partner_content.dart`, taken from [atomshop.pk/brand-partners](https://atomshop.pk/brand-partners). Update it there when the website changes, and never inline it in widgets.
- The **stats card** is the only dark surface on auth screens: `accent` fill, radius 20, white figures, and a small red bar as the eyebrow.
- A signed-out notice (e.g. "account blocked") appears at the top of the pinned panel.

### 3.1.1 Become a partner and Application received
- **Become a partner:** an eligibility card comes first (`background` fill, radius 18) with *Who can apply* pills and *What we look for* green checklist lines. The form follows in three titled sections:
  - **About you:** name, WhatsApp mobile, email.
  - **Your business:** company, type, category, website, product count (hint: "at least 3").
  - **Partnership:** AtomShop share %, message.

  A one-line note under the button explains that the WhatsApp code comes next.
- **Application received:** a large green tick, "We'll be in touch within 2 business days", then `PartnerSteps` with step 1 ticked: *Application sent → Review → Your login arrives*.

### 3.2 Inner auth screens (`AuthScaffold`)
Sign in, Forgot password, Enter code, New password and Become a partner all use `AuthScaffold`:
1. **Top bar (48 px):** back button (44 px, `background` fill, radius 12) · centred AB mark · spacer.
2. **Icon tile** (optional): 56 px, `primarySoft` fill, `primary` icon. Used on every screen except Sign in.
3. **Title + subtitle**, left-aligned.
4. **Form**, then an optional **footer** (e.g. `PartnerLink`).

| Screen | Title | Icon |
|---|---|---|
| Sign in | Welcome back | none |
| Forgot password | Reset your password | `lock_reset` |
| Enter code | Enter your code / Verify your phone | `mark_email_unread` / `verified_user` |
| New password | Choose a new password | `password` |
| Become a partner | Become a partner | `handshake` |
| Application received | (message from the API) | `check` on success green |

### 3.3 Auth controls (`AuthTheme`)
`AuthTheme` wraps every auth screen and overrides the app theme locally:
- **Text fields:** filled `background`, no visible border at rest, **1.6 px red border on focus**, radius 14, 18 px vertical padding. Leading icons are `muted` at rest and turn `primary` on focus. Labels are `muted`; the floating label turns red.
- **Primary button:** 54 px high, radius 14, 15 px label. While busy it stays red at 55% with a white spinner (it never turns grey).
- **Secondary / Google button:** outlined, 54 px, `line` border, `ink` label.
- **Segmented control** (code channel): 46 px; the selected segment uses `primarySoft` + `primary`, the rest `ink`.
- **Code input:** 6 boxes, 58 px high, radius 14. Empty boxes use the `background` fill; the active box turns white with a red border.
- **"or" divider:** hairline + "or" caption, 20 px above and below.

### 3.4 Sign in with Google
- **Button:** "Continue with Google", with the four-colour G drawn by `GoogleLogo` (no image asset). On Sign in it sits **below** the password form, after the "or" divider. On Welcome it sits next to **Sign in** in compact form (label "Google").
- **Flow:** Google account picker → `POST auth/google {id_token, device_name, fcm_token?}` → same `{token, user, brand}` body as `auth/login`. The server must verify the ID token's audience (the Web client ID) and match a **brand** user by email.
- **Messages:**

| Situation | What the user sees |
|---|---|
| Picker closed | Nothing |
| Build has no client ID | Toast: "Google sign-in isn't set up in this version of the app yet." |
| Server has no `auth/google` endpoint (404) | Toast suggesting password sign-in |
| No brand account for that email (401), or account blocked (403) | The server's message, as a toast |

- **Config:** pass the OAuth **Web** client ID at build time with `--dart-define=GOOGLE_SERVER_CLIENT_ID=…`. Android also needs an Android OAuth client in the same Google Cloud project, registered with the app's package name and signing SHA-1.

## 4. Signed-in screens
These follow the tokens above with the standard theme (`buildTheme()`): charcoal app bar with white title, white cards on `background`, red primary actions, status badges per BRAND_APP.md §4.4. They will be redesigned next, using the same principles as the auth screens.

## 5. Checklist for a UI change
1. Colours come from `AppColors`; no raw hex in widgets.
2. One red primary action per screen.
3. Works at 360 px width and 130% font scale; nothing overflows.
4. Every icon-only button has a tooltip or semantic label.
5. State plainly what you did **not** check on a real device.
