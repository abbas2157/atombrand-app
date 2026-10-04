# Atombrand app: Design System

> **What this file is:** the visual language of the Atombrand Flutter app (for AtomShop Brand Partners): tokens, where they live in code, and the layout rules for each group of screens. The API contract is in [BRAND_APP.md](BRAND_APP.md); this file only covers how things look.
> Last reviewed: 2026-10-03

---

## 1. Brand

The identity comes from the **Atombrand** logo: a charcoal **A** and a red **B** on white, with the wordmark and the tagline *Connect. Sell. Grow.*

| Asset | File | Use |
|---|---|---|
| Mark (AB monogram) | `assets/brand/mark.png` | Top bar of every auth screen (26 px high) |
| Lockup (mark + wordmark + tagline) | built in code by `BrandLogo.lockup()` | Splash (150 px high). `assets/brand/lockup.png` is no longer used: its wordmark still reads "AtomBrands". |

- Both are transparent PNGs cropped from the master logo. The A and the wordmark are charcoal, so on dark backgrounds the logo sits on a **white rounded tile**; `BrandLogo` does this automatically in dark mode.
- In code, use `BrandLogo.mark()` / `.inline()` (mark + "Atombrand" in the UI font) / `.lockup()` (`auth_scaffold.dart`), never `Image.asset` directly. The one exception is the mark on the phone in `ProductsIllustration`.
- Don't recolour, stretch or add effects to the logo.
- **Still to do:** the Android/iOS launcher icon and native launch screen are still Flutter defaults. They should use the mark on white.

## 2. Tokens (`lib/core/theme.dart`)

### 2.1 Colour: one palette for the whole app (since 2026-10-03)
Every screen uses `AppPalette` (indigo primary, orange accent, navy, soft neutrals) in a **light and a dark variant**. `BrandApp` builds `buildTheme(AppPalette.light)` and `buildTheme(AppPalette.dark)` and follows the **system setting**. In widgets read `AppPalette.of(context)`; never write a raw hex, and never assume light. The full token table is in §3.1. The signed-in screens add:

| Token | Light | Dark | Use |
|---|---|---|---|
| `page` | `#F5F6FA` | `#0D0E1A` | Scaffold behind cards |
| `card` | `#FFFFFF` | `#171A2C` | Cards, sheets, dialogs, bottom nav |
| `header` / `onHeader` / `onHeaderMuted` | `#10122B` / white / `#A6AAC2` | `#151728` / `#F1F2F8` / `#A6AAC2` | App bars and the dashboard header |
| `divider` | `#EEF0F5` | `#242740` | Hairlines inside cards |
| `cardShadow` | soft two-layer shadow | none | Cards |

### 2.2 Status colours (`Tone` pairs: text on a soft fill)

| Tone | Light fg / bg | Used for |
|---|---|---|
| `neutral` (slate) | `#475569` / `#EEF1F5` | Pending, Lost; anything unknown |
| `info` (blue) | `#2F55B8` / `#E6EDFB` | Verification, Instalments, Contacted, product In review |
| `warning` (amber) | `#8A4B08` / `#FDF0D5` | Processing, product On hold |
| `positive` (green) | `#127A55` / `#E3F4EC` | Delivered, Completed, Live, Won |
| `negative` (red) | `#B42318` / `#FDE7E5` | Cancelled, Out of stock, overdue |
| `lead` (orange) | `#B04600` / `#FFEBDC` | New Lead |
| `violet` (purple) | `#6B3FA0` / `#F1E8FB` | Quoted |
| `indigo` | `#4136C9` / `#EEEDFD` | Icon tiles only |

Each tone has its own dark pair in `AppPalette.dark`. `StatusBadge` maps statuses to tones; payment plans use an outlined neutral pill ("3 mo", "Paid in full"). Chips never wrap or truncate.

### 2.3 Type
**Inter** for signed-in screens (Google Fonts, pinned to `google_fonts` 8), **Poppins** for the auth screens (§3.1). Prices and counts use tabular figures.

| Role | Size / weight | Where |
|---|---|---|
| Screen title (signed in) | 18 / 600 | `titleLarge` |
| Card title | 16 / 600 | `DashTitle` |
| KPI / total | 20 / 700 | dashboard |
| Body | 14–15 / 400 | `bodyMedium` / `bodyLarge` |
| Caption | 12 / 400, `muted` | `bodySmall` |

At most three font sizes per card.

### 2.3.1 Icons
Lucide (`lucide_icons_flutter`, ISC): 24 px grid, 2 px round strokes, used through `AppIcons` (`lib/core/app_icons.dart`), never `Icons.*` directly. The active bottom tab uses the bolder 500 weight (Lucide has no filled set). Exceptions: a solid star for "featured" and the real Facebook / Apple marks on the sign-in buttons.

### 2.4 Shape & spacing
- Radii: cards **16**; buttons, inputs and code boxes **14**; icon tiles ≈ 28% of their size; chips and badges are pills.
- 4-pt grid. Screen padding 16 (signed in) / 24 (auth). Tap targets ≥ 48 px (text links ≥ 44).
- Shadows: `cardShadow` on cards in light mode only.

## 3. Auth screens (signed out)

Goal: minimal and trustworthy. Deep indigo with one orange accent, lots of white space, one primary action per screen. Reference mockups (light and dark, 375×812): the *Atombrand Auth Flow* design canvas.

**Light by default, dark when the system is dark**, like the rest of the app. `AuthTheme` takes the app's `AppPalette` and swaps in Poppins, the white (or dark) auth page and taller controls.

### 3.1 Tokens (`AppPalette` in `lib/core/theme.dart`)

| Token | Light | Dark | Use |
|---|---|---|---|
| `primary` | `#4136C9` | `#8F88FF` | Buttons, links, focus border, icons on focus |
| `onPrimary` | `#FFFFFF` | `#0D0E1A` | Text on primary |
| `primarySoft` / `primarySoft2` | `#F1F0FD` / `#E1DEFB` | `#17163A` / `#232055` | Illustration cards, icon tiles, filled code boxes, selected segment |
| `ring` | primary @ 16% | primary @ 22% | 4 px halo round a focused field |
| `accent` | `#FF7A1A` | `#FF9142` | Highlights only (illustrations, "Fair" strength bar). **Never as text on white** |
| `accentInk` | `#B04600` | `#FFB07A` | The accent when it has to be text (AA) |
| `bg` / `surface` / `field` | `#FFFFFF` / `#F5F6FA` / `#FFFFFF` | `#0D0E1A` / `#151728` / `#171A2C` | Page / soft panels / inputs |
| `border` | `#D9DCE6` | `#2D3048` | Inputs, outlined buttons, dividers |
| `text` / `muted` | `#10122B` / `#5B6078` | `#F1F2F8` / `#A6AAC2` | Text / secondary text, labels, icons at rest |
| `danger` (+ `dangerRing`) | `#C4213A` | `#FF6B81` | Inline errors, error border and halo, banners |
| `success` | `#127A55` | `#4FD3A0` | "Passwords match", "Strong", success ticks |

All text pairs pass WCAG AA (4.5:1) in both modes.

**Type:** **Poppins** (Google Fonts, pinned to `google_fonts` 8). Title 28/700, −0.5 tracking (`authTitleStyle(context)`); subtitle 15/400 `muted` (`authSubtitleStyle(context)`); field label 13/500; inline messages 13; buttons 16/600.

### 3.2 Controls
- **Text field (`AuthField`):** label *above* the field (optional muted suffix such as "(optional)"), 52 px high, radius 14, 1.5 px `border`, leading icon. **Focus:** `primary` border plus a 4 px `ring` halo, and the icon turns `primary`. **Error:** `danger` border and halo, with the message in red with an icon underneath. Password fields have a show/hide eye.
- **Validation:** nothing is flagged until the first submit; after that, fields re-validate as you type. Server field errors come in through `errorText`.
- **Primary button (`AuthButton`):** 54 px, radius 14, soft indigo shadow (light only). **Loading:** keeps its colour and shows a spinner with a verb ("Signing in…").
- **Secondary button:** outlined, 54 px, `field` fill, 1.5 px `border`.
- **Social row (`SocialLoginRow`):** three equal 52 px icon buttons: Google, Apple, Facebook, each with a semantic label. Only **Google** works (§3.4); Apple and Facebook show a "not available yet" toast.
- **Password strength (`PasswordStrengthMeter`):** four 4 px bars plus a hint and a label: Weak (`danger`) / Fair (`accent`, label in `accentInk`) / Good (`primary`) / Strong (`success`). The score counts length ≥ 8, mixed case, a digit and a symbol.
- **Code input:** 6 boxes, 56 px high, radius 14. Empty: `border`. Active: `primary` border + halo + caret. Filled: `primarySoft` fill.
- **Divider:** hairline – "or continue with" – hairline.
- Tap targets are at least 48 px for buttons and inputs, and 44 px for text links.

### 3.3 Layout (`AuthScaffold`)
Top: a 48 px back button (bordered, radius 14), or `BrandLogo.inline` when there's nowhere to go back to. Then an optional 56 px icon tile, title, subtitle, form, and an optional footer pushed to the bottom.

**Keyboard rule:** the primary action must stay visible while typing. Screens whose action ends the form (Forgot password, Enter code, New password, Sign up) put it in `bottom:`, which is pinned and rides above the keyboard. Sign in keeps it in the flow and uses `scrollPadding` on its fields to scroll the button into view. Sign up collapses its pinned panel to just the button while the keyboard is open.

| Screen | Route | Notes |
|---|---|---|
| Welcome | `/welcome` | `BrandLogo.inline`, `ProductsIllustration` (AB mark on the phone), partner headline and pitch, three stat tiles (`PartnerContent.stats`), **Sign In** / **Create Account**, "By continuing, you agree to our *Terms & Privacy Policy*" (`PartnerContent.termsUrl`). There is no guest mode. A signed-out notice (e.g. account blocked) appears above the buttons |
| Sign in | `/sign-in` | Email or phone, password, *Forgot password?*, Sign In, social row, "Don't have an account? Sign up" |
| Sign up | `/sign-up` | Compact header. Name, email, phone (optional), password + strength, confirm (live match). Pinned: terms checkbox (its "Terms & Privacy Policy" opens `termsUrl`), Create Account, "Already have an account? Sign in". **UI only:** brands can't self-register (BRAND_APP.md §2), so a valid form opens a dialog that leads to `/apply` |
| Forgot password | `/forgot` | Email or phone + channel segments, pinned *Send Reset Code*. On success the screen switches to `InboxIllustration` + "Check your messages" with *Enter Code* / *Back to Sign In* / *send again* |
| Enter code | `/verify` | 6 boxes, "Didn't get a code? ⏱ Resend in 0:59", pinned *Verify* |
| New password | `/new-password` | Password + strength, confirm with live match, pinned *Save password* |
| Become a partner | `/apply` | See below |

Sign in ↔ Sign up swap with `pushReplacement`, so Back from either returns to Welcome.

### 3.3.1 Become a partner and Application received
- **Become a partner:** an eligibility card comes first (`surface` fill, radius 18) with *Who can apply* pills and *What we look for* green checklist lines. The form follows in three titled sections:
  - **About you:** name, WhatsApp mobile, email.
  - **Your business:** company, type, category, website, product count (hint: "at least 3").
  - **Partnership:** AtomShop share %, message.

  A one-line note under the button explains that the WhatsApp code comes next.
- **Application received:** a large green tick, "We'll be in touch within 2 business days", then `PartnerSteps` with step 1 ticked: *Application sent → Review → Your login arrives*.

### 3.4 Sign in with Google
- **Button:** the first icon in `SocialLoginRow` (Sign in and Sign up), with the four-colour G drawn by `GoogleLogo` (no image asset) and the semantic label "Continue with Google".
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
All of them use `buildTheme(palette)`: navy app bar (`header`), cards on `page`, indigo primary actions, status pills per §2.2, and a bottom nav whose active tab sits in a soft indigo pill. They follow the system light/dark setting.

### 4.1 Home dashboard (`dashboard_screen.dart`, `dashboard_widgets.dart`)
Reference mockups (Default, Loading, Empty): the *Atombrand Home Dashboard* design canvas. Goal: at a glance, how sales are going and what needs action today. Calm, not cluttered.

Top to bottom:
1. **Header** (`header` navy, light status bar): brand logo (48 px circle), "Hi, {brand}", "Here's your store today", and a bell with the unread count that opens `/notifications`.
2. **Period switch** (Today / 7 days / 30 days): 48 px segments on a soft track. Shown only when the API sends `periods`.
3. **KPI grid** (2×2 `KpiCard`): icon tile, ▲/▼ `TrendChip`, 20/700 number, muted label. Each card opens its filtered list. Fallbacks: without `periods` the cards show all-time order value and orders in the last 30 days; without `orders.pending` the third card shows live products.
4. **Needs attention** (`AttentionCard`): rows of 56 px or more (icon, message, count pill, chevron) for verification, new bulk leads, out of stock and in review. Rows with 0 are hidden; with none left, the card says "You're all caught up."
5. **Sales chart** (`SalesChartCard`): period total, trend, bars (latest bar in `primary`, the rest in `primarySoft2`). Shown only with `periods.*.series`.
6. **Latest orders**: up to 4 `DashOrderCard`s (64 px thumb, name, price, plan + status pills, date) and a "See all" link.
7. **Top products**: rank, thumb, name, "N sold", thin `primary` bar relative to the top seller.
8. **Instalment recovery** (`RecoveryCard`): ring with % recovered, financed and recovered amounts, and an overdue row. Shown only with `recovery`.

**States:** first load shows skeleton cards (`Bone` + `Shimmer`, which stays still under reduced motion). A brand with no products and no orders gets the new-seller state: `EmptyStoreIllustration`, "No orders yet", **Add your first product**, and a 3-step *Getting started* card. Errors show `ErrorView` with *Try again*. Pull to refresh reloads the dashboard, the Bulk badge and the bell count.

The API fields behind 2, 3 (trends), 4 (verification), 5 and 8 are proposed in BRAND_APP.md §8.3.

### 4.3 Orders (`orders_screen.dart`, `order_tile.dart`)
Reference mockups: the *AtomShop Orders List* design canvas. Goal: find an order fast, see what needs action, and open it.

1. **Type switch** (Retail | Instalment): full width, 48 px. The active side is `primarySoft2` with a tick. Counts show when the API sends `type_counts`.
2. **Search** ("Search by product"): debounced 400 ms, with a clear button.
3. **Status chips**: a horizontal row from `config.statuses.order`. 36 px pills inside 48 px tap targets; the active one is soft indigo. Counts show with `counts`.
4. **Summary**: "N orders" from pagination, plus "· Rs. X total" with `total_value`.
5. **Cards** (`OrderTile`, also used on Home): 56 px thumb, name (2 lines max) with the status pill, "#117 · Lahore", then price (bold, tabular), plan pill ("Paid in full" green / "3 mo plan" outlined) and date. Instalment cards get a "Recovered N%" bar when the API sends `recovery_percent`. A 4 px `danger` stripe on the left marks orders that need action (`OrderSummary.needsAction`).
6. **Day groups**: sticky "TODAY / YESTERDAY / 30 SEP 2026" headers (`SliverMainAxisGroup`).

**Interactions:** pull to refresh; infinite scroll; tap opens order detail; **long press** opens quick actions (Call customer, WhatsApp, Copy order #). The contact details are fetched from the order detail when the sheet opens and kept in memory only. When the detail has no contact, the row is disabled with "Not available for this order".

**States:** skeleton cards (`OrderTileBone` + `Shimmer`) on first load; "No orders match '…'" with *Clear search*; "No {status} orders" with *Show all orders*; "No orders yet / Orders from your store will appear here"; `ErrorView` on failure.

### 4.4 Order detail (`order_detail_screen.dart`, `order_detail_logic.dart`)
Reference mockups: the *AtomShop Order Detail* design canvas. Goal: understand one order fully: what was bought, the plan, how much is recovered, who the customer is, and where it stands. On instalment orders AtomShop does the work; the brand follows along and contacts the customer.

Top to bottom:
1. **App bar:** "Order #117", a copy button, and ⋮ with *Share order* (order facts only, never customer data) and *Report a problem* (support email or WhatsApp from `config`; hidden if neither is set).
2. **Info banner** (instalment or locked orders): soft blue with a lock. Shows `locked_reason`, otherwise "AtomShop handles verification, payments and recovery…". Dismissible.
3. **Product:** 88 px thumb, name, variant, PR number, status and plan pills, then Placed / Quantity / Channel.
4. **Progress:** Placed → Verification → Processing → Delivered → Completed. Reached steps are filled indigo with their date (from `history`). The next step has a ring and is highlighted. Cancelled orders show a red *Cancelled* card with the date and reason instead.
5. **Deal:** large total. On instalment orders: an advance vs financed bar, Plan, Paid so far, **Due now** (from the schedule, else `due_left`; red when above 0), and the recovery ring. On retail orders: the payment pill (and advance, if partial).
6. **Schedule:** one 56 px row per `instalments[]` entry: A / 1 / 2 badge, title, "Paid …" / "Due …" / "Was due …", amount and a pill. Paid is green, Due amber, Upcoming slate, Overdue red with a tinted row. The first payment still to come gets a **Next** tag and an indigo outline. Overdue is worked out in the app: unpaid and dated before today.
7. **Customer:** name with a Verified/Unverified pill, then label/value rows (long values wrap, right-aligned) and two equal outlined *Call* / *WhatsApp* buttons.
8. **Activity:** a timeline from `history` in plain words ("Order placed via Web", "Sent for verification"…), with who, received by, reason, the delivery photo and the time.
9. *Customer also bought*, then the pinned action bar (retail orders the brand can move on).

Loading shows skeleton cards; errors show `ErrorView`.

### 4.5 Bulk request (`bulk_dossier_screen.dart`, `bulk_logic.dart`)
Reference mockups: the *AtomShop Bulk Request Detail* design canvas. Goal: a focused sales workspace showing who the buyer is, what they want, and what to do next.

1. **Pipeline strip** (white, under the app bar): New Lead → Contacted → Quoted → Won, or Lost at the end in grey. The current stage dot and label take its status colour.
2. **Won banner** (Won only): green, "Deal won · 80 units · Rs. 14.56M" (the total comes from the latest quote) and when it was confirmed.
3. **Lead card:** business name (20/700) and status pill; a soft box with thumb, product and the quantity big ("80 units"); once quoted, **Your quote** (per unit, total, valid until). Then Phone / Location / Address / Channel / Received (and Reason when Lost). A New Lead shows "Waiting N days for a response": amber under 3 days, red from 3.
4. **Timeline:** empty state with a phone drawing, "No updates yet" and *Add update*. Otherwise one entry per comment, with an icon tinted by status, title ("Quote sent · Rs. 182,000 per unit"), note, time and author.
5. **Requester:** name with a Verified/Unverified pill and the label/value rows (guest buyers get one line instead).
6. **Dealings with your brand:** three stat tiles (lifetime value, orders, instalments paid / unpaid), past orders (3, then *See all*), and a trust hint ("New buyer, no completed orders yet" / "Reliable buyer, N orders delivered"; red when instalments are overdue).
7. **Pinned bar:** round outlined Call and WhatsApp, then a wide *Update status*. It stays in thumb reach.

**Update lead sheet:** 2×2 option cards (Contacted, Quoted, Won, Lost), each with an icon and a one-line description; the selected one takes its status colour with a tick. *Quoted* adds price per unit, quantity (prefilled), a live total and a valid-until date picker. *Lost* adds reason chips (Price too high, Bought elsewhere, Not reachable, Other → free text). Then Notes and *Save update*.

**Quotes are stored in the comment:** the API keeps only text (BRAND_APP.md §8.7), so a quote is saved as a first line `Quote: Rs. 182,000/unit × 80 = Rs. 14,560,000 · valid until 10 Oct 2026`, followed by the notes. `parseComment` reads it back. Don't change that format without migrating old comments.

### 4.6 Notifications (`/notifications`)
The inbox behind the bell (BRAND_APP.md §8.10): cards with a type icon (order indigo, bulk orange, product green), title (bold while unread), body, time ago and an unread dot. Tapping one marks it read and opens its order, bulk request or product. *Mark all read* sits in the app bar.

### 4.7 Catalogue · Products (`catalogue_screen.dart` › `ProductsTab`, `product_cards.dart`, `product_logic.dart`)
Reference mockups: the *AtomShop Catalogue Products* design canvas. Goal: see everything you sell, whether it's live, and what's wrong with it, without opening each product.

1. **Overview strip:** Total · Live · In review · Out of stock, from the dashboard's catalogue counts. Out of stock turns red above 0. Tapping a box filters the list.
2. **Search** ("Search products"), then **status chips** from `config.statuses.product`, with counts where the dashboard has them. The row fades at the right edge instead of cutting a chip off.
3. **Out of stock filter:** a red banner, "N products can't be bought. Update stock in Inventory →", which switches to the Inventory tab.
4. **Count + view toggle:** "N products" and list/grid (44 px buttons).
5. **List card** (`ProductListCard`): 72 px thumb (a dashed **Add photo** box when there is no picture; an orange star when featured), name (2 lines), PR · category, then price, status pill and stock: "12 in stock" muted, "Low · 3 left" amber, "Out of stock" red. **Availability is the status** (as in Inventory): a unit count of 0 on a Live product only means stock isn't tracked, so it shows nothing rather than a false alarm. **Problem line** under Out of Stock products, with *Update stock*.
6. **Grid card** (`ProductGridCard`): 128 px picture on top with the stock as a corner badge, then name, price and status.
7. **FAB** "Add product", extended at the top and shrinking to a round + once the list scrolls. The list ends with 96 px of room so the FAB never covers a price or stock line.

**Interactions:** tap opens Product detail; **long press** opens quick actions (Edit, Update stock (when allowed), Feature on / Remove from brand page, View on AtomShop when live); pull to refresh also reloads the dashboard counts.

**States:** skeleton cards; "Your catalogue is empty" with the box illustration and *Add product* (FAB hidden); "No products with this status" / "No products match '…'" with *Show all products*; `ErrorView`.

Product pills: Live green, In review blue, Out of stock red, On hold amber, Closed grey.

### 4.8 Catalogue · Inventory (`inventory_tab.dart`, `inventory_logic.dart`)
Reference mockups: the *AtomShop Catalogue Inventory* design canvas. Goal: keep stock right and switch selling on or off for many products fast (10 products in under a minute). **Nothing saves silently:** every switch, stepper and bulk action only changes a draft until *Save*.

1. **Stock health card:** a green / amber / red bar and "N in stock · N low · N out", with total units on the right. It counts only products the brand can manage and updates as you edit.
2. **Search** by name or PR number. The barcode button is hidden until products carry a `barcode` (§8.5).
3. **Filter:** All · In stock · Low · Out, each with a count of the matching products for the current search, so a count always equals its list. The tab loads every page so this holds.
4. **Action row:** "N products" and *Bulk edit*. In bulk mode it becomes "Select all (N)" and *Done*.
5. **Card** (`InventoryCard`): 52 px thumb, one-line name, PR and status pill, then two labelled controls: **Sell on site** (a switch with "On"/"Off" text, 48 px box) and **Units in stock** (− field +, all 48 px; type in the field). Then a stock line: "12 in stock" green, "Low · 3 left" amber, "Out of stock" red, "For sale · units not set" muted (a live product with 0 units isn't tracked; the field shows *Not set*). Units are locked while the product is off ("Turn on to set units"), and both controls are locked for products that aren't live yet ("Can sell after review").
6. **Edited:** a changed card gets an indigo border and an "Edited" dot. Turning a product on with 0 units tints it red with "On, but 0 units. Buyers see this as unavailable." and Save refuses until it has units (the API needs 1–1,000,000).
7. **Save bar** replaces the bottom nav while there are changes: "N changes · Not saved yet", *Discard* (with Undo on the toast) and *Save*. Save sends one `POST inventory/{id}` per changed product, then reloads and shows "Stock updated for N products". Back with unsaved changes asks "Discard changes?".
8. **Bulk mode:** cards become one-row checkboxes (68 px). A bar replaces the nav: "N selected · Clear" with *Set stock* · *Turn on* · *Turn off*. **Set stock** sheet: "Set to exact number" or "Add to current stock", a stepper field, a before → after preview, and a note when it turns products on. All bulk actions end bulk mode and leave a draft to save.

**States:** skeleton; "Nothing out of stock / All your products can be bought right now." (green check) and "Nothing running low" on an empty filter; "No products match '…'"; load error with *Try again*.

### 4.9 Product detail (`product_detail_screen.dart`, `product_detail_logic.dart`)
Reference mockups: the *AtomShop Product Detail* design canvas. Goal: one product at a glance (how buyers see it, whether it sells, price, stock, how it's doing), with every status saying what it means and what to do next.

1. **App bar:** back, "Product", a star (*Feature on brand page*, orange when featured) and ⋮ (View on atomshop.pk when live, Delete product). Duplicate, Put on hold, Close and Reopen join the menu once the API has them (§8.5).
2. **Gallery:** full width, 288 px on white, swipeable, with a "1/4" counter and dots; tap opens a full-screen viewer with pinch zoom. One photo adds "Add more photos to sell better · Add photos"; none shows an *Add photos* box. Closed products show their photos greyed.
3. **Status banner** (`StatusBanner`): Live, a one-line green "Live on atomshop.pk · View"; Out of stock, red with *Update stock* (scrolls to the stock card); Rejected, red with the reason, review date and *Fix & resubmit* (opens Edit; saving sends it for review); In review, blue "Usually takes 1–2 days"; On hold, amber; Closed, grey "hidden from buyers".
4. **Title block:** name (22 px bold), the detail page title muted, then chips: PR, category, "Brand: …" and the status.
5. **Price card:** price (28 px), minimum advance on the right, and a "How buyers see it" box ("From Rs. X/month · N months") only when the API sends `instalment_preview`.
6. **Options** (colours, storage, sizes with prices) when the product has any.
7. **Stock card:** big number with its state ("Low stock" amber, "Out of stock" red; "Not set · For sale" when untracked) and the `UnitsStepper`. A change shows "12 → 30 · not saved" with *Cancel* and *Save stock* (or *Mark out of stock* at 0); nothing saves until tapped. Locked with a reason for products that aren't live. "Updated …" from `updated_at`.
8. **Performance** (last 30 days: units sold, revenue, page views, bulk requests, and a 5-day-average sales line) only when the API sends `performance`; dimmed with "Paused while hidden" for closed or on-hold products.
9. **Key features:** the short description split into a checklist (on lines, bullets, `;` and commas, but never inside brackets or between digits); long lists show 8 and *Show all N*.
10. **Full description:** the HTML shown as headings, paragraphs and bullets, never tags; a paragraph that is only a comma list becomes bullets; hidden when it just repeats the key features. Cut to about 4 lines with *Read more*.
11. **Bottom bar:** *Preview* (the public page, when live) and *Edit product*, 52 px, above the home indicator.

### 4.10 Add / Edit product (`product_form_screen.dart`, `product_form_logic.dart`)
Reference mockups: the Add / Edit product HTML mockups (Add empty, mid-fill, validation errors, Edit with re-review banner, Sent for review, discard dialog). Goal: short, guided and forgiving for non-technical sellers; no HTML anywhere.

1. **One scrolling page, four numbered sections:** Photos → Basics → Price & stock → Description. Each section's number turns into a green check when complete. Add shows a progress strip under the app bar ("2 of 4 sections done · Next: Price").
2. **Banners:** Add, a dismissible blue "reviewed by AtomShop, usually 1–2 days"; after a failed submit, a red "N things to fix". Edit of a live product, amber: saving sends it back to review **and hides it until approved** (the API sets `Published → Pending`). Out of stock products get a blue note that stock stays as it is.
3. **Photos:** a large dashed *Add main photo (required)* slot with *Gallery* / *Take photo*; once set it shows the photo with *Replace* (and *Remove*/*Undo* for a newly picked one). More photos in a row of 76 px thumbs with × and a dashed *Add*, up to `config.uploads.gallery_max`. Removing an existing gallery photo only happens on save. Tip: white background, at least 800×800 px.
4. **Basics:** Title ✱ (0/255, "Brand, size and model work best"), Detail page title (optional), Category ✱ and Show under brand ✱ as fields that open a searchable bottom sheet (own brand prefilled).
5. **Price & stock:** Price ✱ and Min. advance ✱ side by side with an always-visible "Rs." and grouped digits as you type; "Advance can't be more than the price" shows as soon as it's true. Edit shows "Was Rs. X" under a changed price. *Options (optional)* folds colours, storage and sizes. Stock is a note: set it after approval (Add) or from the product page / Inventory (Edit). The "Buyers will see From Rs. X/month" preview waits for plan terms from the API.
6. **Description:** Key features ✱ as chips (type, Enter or a comma adds; × removes; "20L, 700W" adds two), stored as the comma list `short` has always been, with a 0/500 counter. Full description (optional) is a small block editor: each line is text, a heading or a bullet, styled as it will look; the toolbar (Bold, Heading, Bullet list) changes the focused line; Enter starts a new line. It saves as HTML the seller never sees.
7. **Bottom bar** (moves up with the keyboard): a line saying what's missing ("Add a main photo and a price to continue") or "Ready"; *Submit for review* looks disabled until complete but tapping it marks every gap in red and scrolls to the first. Edit: *Save changes (N)*, disabled until something changed; the line says it sends the product for review again.
8. **Leaving with changes:** "Discard changes?" with *Keep editing* (primary) and *Discard*.
9. **After adding:** a full-screen "Sent for review" with a check illustration, the product card, three steps (submitted → AtomShop checks → live, set stock) and *Add another* / *View product*.

### 4.11 More (`more_screen.dart`, `more_logic.dart`)
Reference mockups: the More HTML mockups (Default, Incomplete brand page, Sign-out sheet, Contact sheet). Goal: everything outside daily selling, easy to scan, grouped, rarely visited.

1. **Profile card:** round logo, brand name, user name and email, a store chip from `brand.status` ("Store live" green, "Under review" amber, "Suspended" red, none when unknown) and *Edit* (Profile). A strip of three numbers from the dashboard: Products · Orders, 30 days · Live (hidden if the dashboard fails).
2. **Brand page nudge** (only while incomplete): "Your brand page is N% complete", an orange progress bar, chips for Logo, Tagline, Banner and Story (✓ or +), a line naming what's missing ("Add a banner and story to build buyer trust.") and *Complete now*. Promo slides aren't counted: the server fills them with default copy.
3. **Grouped rows** (60 px, icon in primary, chevron; an external-link icon for anything that leaves the app; at most 5 per card):
   - *Your store:* Brand page (says what's missing), View public page (`atomshop.pk/brand/…`), Share store link (share sheet with the public URL).
   - *Account:* Profile, Change password, Bank & payouts and Team members (greyed, "Soon").
   - *Help & support:* Contact AtomShop (opens the contact sheet), Seller policies and terms.
4. **Sign out:** its own card with one red centred row. It always confirms in a sheet: "Sign out of OXY?", the email, "You'll need your email and password to sign in again…", *Cancel* / red *Sign out*.
5. **Contact sheet:** large WhatsApp ("Fastest", usually within 1 hour), Call (number spaced as +92 330 227 7522) and Email options from `config.support`, the hours, *Cancel*.
6. **Footer:** "Atombrand · v{appVersion}" (a test keeps it in step with pubspec).

Not built yet (no API): notification switches per type, language (Urdu), bank and payout details, team members, a help center link.

### 4.12 Brand page editor (`brand_page_screen.dart`, `brand_page_logic.dart`)
Reference mockups: the Brand page editor HTML mockups (Empty, Filled, Promo slide sheet, Preview, Upload error). Goal: non-designers see exactly what buyers will see while they edit.

1. **App bar:** back, "Brand page", *Preview* (eye). Leaving with unsaved changes asks "Discard changes?".
2. **Completeness:** "Your page is N% complete", a bar and chips for Logo, Banner, Tagline, Story (✓ or +; a + chip scrolls to its section). At 100% a green "Page complete" tag replaces the chips. The More nudge uses the same checklist (`brandChecklist`).
3. **Header, as on the public page:** a 16:6 banner (empty: "Add a banner · 1600×600 px, up to 4 MB"; set: the image with *Change*), the round logo overlapping its bottom-left edge with a camera badge ("Logo: square, up to 2 MB"), then the name and tagline, updating as you type. Too-large images get a red line under the header: "Image too large. Use a file under 4 MB. {file} is 6.8 MB. Try saving it as JPG…" (`ImageTooLarge` from `pickImage`).
4. **Public address:** a grey card with a lock and "Public address · read only", the short link, Copy and Share, and "The address and homepage placement are managed by AtomShop."
5. **About your brand:** Brand name ✱, Tagline (0/80, "Shown under your name"), Intro line (optional, `hero_intro`), Story (0/5000, plain text; a blank line starts a paragraph).
6. **Promo slides** (up to `max_slides`): gradient text cards (label, headline, text) as buyers see them, with an edit badge, and an *Add slide* tile; empty: "Promote offers like 'Eid Sale: 10% off Smart TVs'". Tapping opens a sheet with a live 16:9 preview, Label, Headline ✱, Text, *Delete slide* / *Done*.
7. **Featured products** (up to 6): numbered small cards with ×, *Add product* opens a searchable picker of live products. Changes are applied on save (each is the product's feature star).
8. **Contact:** Phone, Email, Website (optional; "oxy.pk" is saved as https://oxy.pk).
9. **Save bar:** "Save brand page" disabled until something changes, then *Discard* + *Save changes (N)*.
10. **Preview:** the draft as the buyer page (atomshop.pk header, banner, overlapping logo, name, tagline, intro, slide carousel, featured grid, story, contact) with a floating "Preview · Not yet saved" pill and ×.

### 4.13 Notifications (`notifications_screen.dart`, `notification_logic.dart`)
Reference mockups: the Notifications HTML mockups (Default, Bulk leads filter, Swipe, Empty, Settings). Goal: everything that needs attention, each row saying what happened and opening the right screen.

1. **App bar:** back, "Notifications", *Mark all read* (disabled when nothing is unread). No bottom nav. The settings gear waits for per-type preferences in the API.
2. **Filter chips:** All plus one chip per category that has notifications (Orders, Bulk leads, Payments, Stock, Products, AtomShop), each with its unread count; the row fades at the right edge.
3. **Needs your action** (on All, even when the inbox is empty): a soft red card, "N things need your action", with rows from data the app already has: new bulk leads to call (→ Bulk) and products out of stock (→ Catalogue filtered). Hidden when there's nothing.
4. **List:** grouped under sticky Today / Yesterday / This week / Earlier headers, in white grouped cards. A row: round category icon (orders indigo, leads orange, payments green, stock amber, products blue, AtomShop violet; urgent ones red), title (bold while unread, red when urgent, never cut), body clamped to 2 lines, time ("12:43 PM", "Yesterday", "28 Sep") and an unread dot (red when urgent). Unread rows have a light indigo tint.
5. **Interactions:** tap marks read and opens the order, lead or product; swipe left marks read (the row stays); long-press starts multi-select with *Select all* and *Mark N read*; pull to refresh; more loads as you scroll.
6. **Empty:** a bell with a green check, "No notifications yet", "New orders, leads and alerts will show up here." (not "all caught up": the action card above may still list work); a filter with nothing offers *Show all*.

## 5. Checklist for a UI change
1. Colours come from `AppPalette.of(context)`; no raw hex in widgets. Check light **and** dark.
2. One primary action per screen. Auth screens: check both light and dark.
3. Works at 360 px width and 130% font scale; nothing overflows.
4. Every icon-only button has a tooltip or semantic label.
5. State plainly what you did **not** check on a real device.
