# Brand Partner v2: foundation guide for feature engineers

Brand Partner v2 lives in `lib/v2/`. It is a clone of Atom Seller v2 (`C:\MyProject\atomseller\lib\v2`) with the brand's features. The design source of truth is the canvas, https://claude.ai/artifact/RCVYzKTyubLWbff3ztFxkq. Board numbers below (6.2, 9.5 and so on) are the canvas's.

`lib/main.dart` starts v2 (`BrandPartnerApp`). The v1 app (`lib/app.dart`, `lib/core`, `lib/data`, `lib/features`, `lib/widgets`) stays on disk for reference only. **Never import v1 from v2.** You may copy a v1 model into your feature folder and adapt it: `lib/data/models/*` already speaks the brand API.

## Rules

1. **Edit only your own feature folder** (`lib/v2/features/<yours>/`), including its `<feature>_routes.dart`.
2. Shared code is read-only for you: `lib/v2/app`, `lib/v2/core`, `lib/v2/design`, `lib/v2/widgets`, `lib/l10n`, `pubspec.yaml`, other features. That covers new route constants, a new widget, a new package and new arb strings. **Ask the lead for any shared change.** Don't work around it by copying shared code into your folder.
3. You can import another feature's public pieces (for example `features/sync/data/sync_providers.dart`) but never edit them.
4. Riverpod is written by hand. No codegen and no `build_runner`. Dart 3 patterns, `ApiResult` switches.
5. Before you hand over: run `C:\src\flutter\bin\flutter analyze`, which must show no errors, and `C:\src\flutter\bin\flutter test`.

## Folder layout

```
lib/
  main.dart                 starts v2
  l10n/app_en.arb           v2 strings (gen-l10n; lead owns it)
  v2/
    app/                    app.dart, router.dart, routes.dart (constants), guards.dart,
                            shell.dart (tabs/rail), route_params.dart, portal_links.dart
    core/                   api/, session/, access/, lock/, db/, net/, update/, services/,
                            format/, pdf/, prefs/
    design/                 tokens: AtomColors, AtomText, AtomSpace, AtomRadius, AtomSize…
    widgets/                shared components (import widgets.dart)
    features/
      auth/ help/ menu/ notifications/ settings/ states/ terms/ update/   (brought over, lead)
      home/ orders/ atompay/ bulk/ catalogue/ stock/ team/ outlets/
      account/ ask_atom/ sync/                                              (feature engineers)
```

Suggested inside a feature: `data/` (models, repository, providers), `ui/` (screens, parts) and `<feature>_routes.dart`.

## How a feature registers routes

Each feature has one routes file that `app/router.dart` spreads in. The router itself does not change when you add screens.

| File | Exports | Where it mounts |
|---|---|---|
| `home/home_routes.dart` | `homeTab`, `homeRoutes` | tab 1, and over the tabs |
| `orders/orders_routes.dart` | `ordersTab`, `ordersRoutes` | tab 2, and over the tabs |
| `bulk/bulk_routes.dart` | `bulkTab`, `bulkRoutes` | tab 3, and over the tabs |
| `catalogue/catalogue_routes.dart` | `catalogueTab`, `catalogueRoutes` | tab 4, and over the tabs |
| `atompay/atompay_routes.dart` | `atompayRoutes` | over the tabs |
| `stock/stock_routes.dart` | `stockRoutes` | over the tabs (`/stock/...`) |
| `sync/sync_routes.dart` | `syncRoutes`, `syncMenuRoutes` | over the tabs, and under `/menu` |
| `team/team_routes.dart` | `teamMenuRoutes` | under `/menu` (relative paths) |
| `outlets/outlets_routes.dart` | `outletsMenuRoutes` | under `/menu` |
| `account/account_routes.dart` | `accountMenuRoutes` | under `/menu` |
| `ask_atom/ask_atom_routes.dart` | `askAtomMenuRoutes` | under `/menu` |

Every screen starts as `AtomPlaceholderScreen(title:, board:)`. To build one, replace the builder in your routes file:

```dart
GoRoute(
  path: V2Routes.orderPattern,                       // '/order/:uuid'
  builder: (_, state) => CashOrderScreen(uuid: textParam(state, 'uuid')),
  routes: [
    GoRoute(path: 'deliver', builder: (_, state) =>
        MarkDeliveredScreen(uuid: textParam(state, 'uuid'))),
  ],
),
```

- The tab root is `xxxTab`, a `GoRoute`, and the shell shows the tab bar only on its exact path. Put detail screens in `xxxRoutes`, which open over the tabs on the root navigator.
- Under `/menu`, child paths are relative (`'team'`, `':id'`).
- `route_params.dart` has `intParam(state, 'id')`, `intQuery(state, 'x')` and `textParam(state, 'uuid')`.
- Navigate by constant only: `context.push(V2Routes.dealOf(id))`. Use `context.go(...)` to switch tabs.
- A sheet such as Quick actions or the Outlet switcher can stay a route: build it with `pageBuilder` and a modal page in your routes file. It can also be shown with `showAtomSheet` from your screen.

### Route constants (`lib/v2/app/routes.dart`, class `V2Routes`)

The lead owns these. Ask for additions.

- **Way in:** `launch` `/`, `welcome`, `signIn`, `apply`, `quickSignIn`, `forgot`, `forgotCode`, `forgotNew`, `forgotDone`, `signedOut`, `agentPassword` (2.4), `setPin` (2.5), `chooseOutlet` (2.6), `gettingReady` (2.7), `terms`, `allowNotifications` (15.8), `tour` (16.7)
- **States:** `maintenance`, `updateRequired`, `stateRemoved`, `stateNoPlan`, `notInRole`, `restricted`
- **Tabs:** `home` `/home`, `orders` `/orders` (`atompayOrders` = `/orders?tab=atompay`), `bulk` `/bulk` (`bulkTab('sellers'|'website'|'deals')`), `products` `/products`. The list is in `tabs`.
- **Home:** `quickActions` (5.6), `outletSwitcher` (5.7), `search` (5.8)
- **Orders:** `orderPattern`, `orderOf(uuid)` (6.2), `orderDeliverOf` (6.3), `orderPaymentOf` (6.4), `orderCancelOf` (6.5), `orderMoveOf` (6.6), `orderReceiptOf` (6.7)
- **AtomPay:** `atompayPattern`, `atompayOf(uuid)` (6.9), `atompayHandoverOf` (6.10)
- **Bulk:** `sellerRequestPattern`, `sellerRequestOf(id)` (7.2), `sellerRequestQuoteOf` (7.4), `bulkRequestPattern`, `bulkRequestOf(id)` (7.3), `bulkQuoteOf` (7.4), `bulkStatusOf` (7.5), `bulkWonOf` (7.6), `dealPattern`, `dealOf(id)` (7.7), `dealDeliverOf` (7.8), `dealPaymentOf` (7.9)
- **Catalogue:** `productNew`, `productEditPattern`, `productEditOf(id)` (8.2), `brandPage` (8.3)
- **Stock:** `stock` (9.1/9.2), `stockList(show:)` (9.3), `productStockOf(id)` (9.4), `stockIn(productId:, serial:)` (9.5), `stockMove` (9.6), `stockAdjust` (9.7), `scanSerial` (9.8), `stockHistory` (9.9), `warehouses` (9.10)
- **Menu:** `menu` (12.1)
- **Team:** `team` (11.1), `teamAdd` (11.2), `teamAdded` (11.3), `teamMemberOf(id)` (11.4), `teamRoles` (11.5), `roleEdit(roleId:)` (11.6)
- **Outlets:** `outlets` (11.7), `outletAdd` (11.8), `outletOf(id)` (11.9)
- **Account:** `plan` (12.6), `addonSwitchOf(Addon)` (12.7), `paidOf(bill:)` (12.8), `reports` (12.4), `reportOf(name)` (12.5), `profile` (16.1), `shopSettings` (18.2), `dailySummary` (18.12), `rateApp` (18.10)
- **Ask Atom:** `askAtom` (12.10)
- **Sync:** `sync` (10.1), `syncWaiting` (10.2), `syncAttention` (10.3), `syncClash` (10.4), `syncRunning` (10.5), `syncUpdate` (10.6), `syncPhones` (10.7)
- **Notifications:** `notifications`, `notificationSettings`, `notificationMessage`
- **Help:** `help`, `faqs`, `faqAnswer`, `support`, `supportThread`, `ecosystem`, `privacy`, `termsRead`
- **Settings:** `settings`, `settingsStep('password'|'language'|'devices'|'feedback'|'data'|'close-account'|'security'|'pin'|'permissions'|'storage')`

The guards (`guards.dart` with `routeRules` in `routes.dart`) apply three rules. Owner-only routes and missing permissions go to Not in your role. A route whose add-on is off goes Home. The way-in steps run in order.

## Calling the API

- **Client:** `ref.read(apiClientProvider)` (`core/app_providers.dart`). Its base is `https://atomshop.pk/api/brand-app/`, so paths are relative: `'orders'`, `'bulk-orders/$id/status'`, `'sync/check'`. A local server is `--dart-define=ATOM_SERVER=http://localhost/atomshop/`.
- **Headers:** every call sends `Authorization: Bearer`, `X-Outlet` (the outlet chosen; none means all outlets), `X-Atom-Brand-App: 2`, `X-Atom-Platform` and `X-Atom-Build`.
- **Methods:** `get<T>(path, query:, parse:)`, `post<T>(path, body:, parse:)`, `postForm<T>(path, fields:, files: {'screenshot': File})` for multipart, `getPdf(path)` returning bytes and filename, and `getBytes(url)`. **The client never throws.** It returns `ApiResult<T>`:

```dart
switch (await api.post('orders/$uuid/status', body: {...}, parse: CashOrder.fromJson)) {
  case ApiOk(:final value): ...
  case ApiErr(:final failure): showAtomToast(context, kind: AtomToastKind.bad, message: sayFailure(l, failure));
}
```

- **`ApiFailure.kind`** is one of: `offline`, `timeout`, `signedOut` (401), `mustChangePassword`, `notInRole` / `ownerOnly` (403), `featureOff` (403 with `data.feature_off`, and `failure.body['feature']` names the add-on), `readOnly` (`billing_state: readonly`), `restricted`, `packageRemoved`, `noPlan`, `notFound`, `validation` (`failure.fieldErrors['field']`), `conflict`, `maintenance` (503) or `server`. App-wide kinds are already handled by the session and access controllers and the router; your screen only needs to show a message.
- **Lists:** the brand server pages as `{items, pagination:{current_page,last_page,per_page,total}}`. Parse with `ApiPage.fromJson(data, Item.fromJson)` (`core/api/api_page.dart`). It gives `items`, `hasMore`, `total` and `extra`, which holds sibling keys such as `unread_count`.
- **JSON:** the `Json` helpers in `api_client.dart` (`Json.map`, `list`, `str`, `integer` and `flag`) read the server's loose types. Use them in `fromJson`.
- **Retry:** the root `ProviderScope(retry: apiRetry)` does not retry definite answers such as 4xx. A `FutureProvider` that fails shows the error. Use `ref.invalidate(provider)` for Try again.
- **Messages:** `sayFailure(l, failure)` (`widgets/atom_failure.dart`) says "no signal" for offline and timeouts, then falls back to the server's message, then to "Something went wrong".
- **Screen states:** `AtomLoadingRows` / `AtomLoadingCard` (skeletons), `AtomErrorState(onRetry:)`, `AtomMessageState` (empty lists, 13.1), `AtomNote` (inline problem or info) and `showAtomToast` (ok / wait / bad).
- **PDFs:** `core/pdf/server_pdf.dart` (`handOverServerPdf`) and `AtomPdfButton` share a server-built PDF such as a receipt, quote or invoice.
- **Portal links:** `appRouteForPortalUrl(url)` (`app/portal_links.dart`) turns a `/brand-portal/...` link into an app route.

## Session, permissions, add-ons, billing

- **Session:** `ref.watch(sessionProvider)` is `SessionLoading`, `SignedOut` or `SignedIn(session)`. The shortcut is `ref.read(sessionProvider.notifier).current`, a `BrandSession?`.
  - `BrandSession` holds `name`, `email`, `phone`, `brandId`, `brandName`, `brandLogo`, `brandSlug`, `who`, `outletId`, `outletName`, `outlets` (`List<Outlet>`) and `multiOutlet`.
  - Switch outlet with `sessionProvider.notifier.selectOutlet(id, name)`. Null means all outlets. Every later call carries `X-Outlet`.
- **Who:** `session.who` gives `isOwner`, `roleKey`, `roleName`, `permissions`, `outletIds` (null means every outlet) and `mustChangePassword`. Check permissions with `who.can(BrandPermission.ordersPayment)`, `who.canAny([...])` and `who.worksIn(outletId)`.
  - The keys live in `core/session/session.dart`: `homeTotals`, `ordersView`, `ordersStatus`, `ordersPayment`, `ordersCancel`, `atompayView`, `bulkView`, `bulkQuote`, `bulkDeal`, `catalogueView`, `catalogueEdit`, `pageEdit`, `stockView`, `stockChange`, `stockManage`, `moneyReports`, `moneyExport` and `teamManage`.
  - The owner has `*`. Hide what the person can't do; never show it locked.
- **Add-ons and billing:** `ref.watch(accessProvider)` gives an `AccessState`.
  - `has(Addon.inventory | team | askAtom | alerts | offline)` is true when the add-on is in trial, active or legacy. `stateOf(addon)` returns an `AddonState`: `off`, `trial`, `active`, `lapsed` (read-only) or `legacy`.
  - `addons` is null until known, so leave add-on parts out until then.
  - `account` is the billing state: `ok`, `due`, `late`, `overdue`, `readOnly`, `restricted`, `removed` or `noPlan`. `blocksWrites` covers read-only and restricted. `daysLate`, `due` and `message` come with it.
  - The state is loaded on sign-in and resume from `GET me`, the owner's `GET billing` and `GET outlets`. Call `ref.read(accessProvider.notifier).refresh()` after a payment or an add-on switch.
- **Roles:** `roleCanSummary(l, permissions)` (`features/states/ui/state_screens.dart`) gives a "You can …" line. `showNotInRoleSheet(context)` and `showSaveError(...)` live in the same file.

## Design tokens and widgets

Import `design/design.dart` and `widgets/widgets.dart`. The look is Atom Seller v2's: navy `AtomColors.nav`, royal `AtomColors.primary`, Inter, and Lucide icons (`lucide_icons_flutter`).

- **Tokens:** `AtomColors` (palette; `AtomTone.blue/green/amber/rose/grey/purple` icon-tile tones), `AtomText` (type scale: `heading`, `listTitle`, `body`, `secondary`, `small`, `amount`…), `AtomSpace` (4…24, `gutter` 16, `inset` 14), `AtomRadius` (tag 6, control 10, card 14, sheet 20, pill), `AtomSize` (control heights, `tabletBreakpoint` 600, `splitBreakpoint`), `AtomDecor` / `AtomShadow` (card surfaces), `AtomIcon` sizes, `AtomBrandIcons.whatsapp` and `AtomTheme.light`.
- **Widgets:**
  - `AtomPlaceholderScreen`: the not-built-yet screen.
  - `AtomNavyHeader`, `AtomNavyIconButton`, `AtomAvatar`: the navy overview header (Home, money records).
  - `AtomPageHeader` + `AtomHeaderTab`: the white list header with tabs.
  - `AtomFlowBar` (`AtomFlowLeading.back/close/none`): the plain bar for flows and forms.
  - `AtomButton` (primary/outline/danger, `.small`, `saving:`), `AtomButtonPair`, `AtomButtonReason`: buttons, and the reason a button is disabled.
  - `AtomTextField`, `AtomField`, `AtomFieldError`, `AtomPasswordField`, `AtomCodeInput`: fields with label, hint and red error.
  - `AtomSelectField`, `AtomMultiSelectField`, `showAtomSelect`, `showAtomMultiSelect`, `AtomOption`: the searchable dropdown. **Every list choice uses it.**
  - `AtomChips` (2–4 fixed choices), `AtomSegmented`, `AtomChoiceGrid`, `AtomOptionCard`, `AtomRadio`, `AtomCheckbox`, `AtomSwitch`: choices and toggles.
  - `AtomNavRow`, `AtomRowGroup`, `AtomCountBadge`: Settings-style rows.
  - `AtomListRow`, `AtomListCard`, `SliverAtomListCard`, `AtomSliverPage`, `AtomListCardSlice`, `AtomInitials`, `AtomIconTile`, `AtomInfoLine`, `AtomInfoCard`, `AtomSummaryBar`, `AtomFilterChip`: lists and detail lines.
  - `AtomSection`, `AtomLink`, `AtomHeroCard`, `AtomKpi` / `AtomKpiGrid`, `AtomProgressBar`, `AtomTaskRow`, `AtomWeekChart`, `AtomScheduleRow`: dashboard pieces.
  - `AtomNote`, `AtomPill`, `AtomSectionLabel`: inline notes, status pills and section labels.
  - `showAtomSheet`, `AtomSheetHeader`, `showAtomConfirm`, `confirmLeaveWithoutSaving`, `AtomUnsavedGuard`, `showAtomToast`: sheets, dialogs, unsaved changes and toasts.
  - `AtomMoneyKeypad`, `AtomAmountDisplay`, `AtomPinPad`, `AtomPinDots`: money entry with the amount in words, and PIN.
  - `showPastDaySheet`: payment dates, never in the future.
  - `AtomPhoto`, `AtomThumb`, `AtomPdfButton`, `AtomSpinner`, `AtomPressable`: images, PDFs and the pressed state.
  - `AtomSplitView`, `AtomReadableWidth`, `AtomSelectedRow`: tablet list and detail (14.x).
  - `AtomTabBar`, `AtomRail`, `AtomDestination`: used by the shell only.
  - `AtomBrandTile`, `AtomAiMark`: the Brand Partner mark and the Ask Atom mark.
  - `AtomLoadingRows`, `AtomLoadingCard`, `AtomLoadingCaption`, `AtomMessageState`, `AtomErrorState`, `AtomTextLink`: screen states.
- **Formatting:** `core/format/money.dart` (Rs grouping, amount in words), `dates.dart` (`AtomDates`) and `ids.dart` (`AtomIds.normaliseMobile/formatMobile/isValidImei`, `MobileInputFormatter`, `whatsAppUri`).
- **Strings:** v2 strings live in `lib/l10n/app_en.arb` (`AppLocalizations.of(context)`). The arb is shared, so ask the lead to add keys. Until they land you may use plain English literals in your feature, and the lead moves them into the arb at merge.
- **Brand assets:** `assets/brand/mark.png` (Atombrand mark), `lockup.png`, `atomshop_logo.png` ("by Atomshop.pk") and the `eco_*.png` ecosystem marks.

## Offline (Offline add-on) and the outbox

The infrastructure is ported from Atom Seller and compiles. The Sync engineer owns `features/sync/`, and the backend `brand-app/sync/*` is being built now with the seller contract mirrored: `GET sync/check`, `GET sync/snapshot`, `GET sync/changes`, `GET sync/files` and `POST sync`.

- **The copy:** `core/db/atom_db.dart` is hand-written with no codegen. Every snapshot row is kept as JSON in `copy_rows (tbl, scope, id, updated_at, temp_id, data)`. Read it through `SyncStore` (`ref.read(syncStoreProvider)`):
  - `rows(table, shopId:)`, `row(table, id, shopId:)` and `watchRows(table, shopId:)` return maps. Parse them with your normal `fromJson`.
  - `patchRow` shows an offline change in the copy before the server confirms it. `addLocalRow` adds a row made offline.
  - The scope is `syncShopIdProvider`: the outlet id, or 0 for the whole brand.
- **Reading offline:** `ref.watch(offlineCopyProvider)` gives an `OfflineCopy?` (`db`, `shopId`, `isOnline()`). It is null when the add-on is off or the copy is locked. When it is non-null and the phone is offline, read the copy instead of the API.
- **Saving offline:** `ref.read(offlineSavesProvider)` gives an `OfflineSaves?`. Call `save(action: 'order.payment', data: {...}, send: () => api.post(...), files: {...}, alsoHere: (store, shopId) => store.patchRow(...))`. It returns `SavedOnServer`, `SavedHere` (queued) or `SaveFailed`. After `SavedHere`, call `showSavedHereToast(context)` or `showSavedHere(...)` (`features/sync/ui/saved_here_sheet.dart`). Without the add-on, `offlineSavesProvider` is null: call the API directly.
- **Action keys:** the server's (`SyncActionKeys` in `core/db/outbox_actions.dart`): `order.status`, `order.cancel`, `order.payment`, `atompay.handover`, `deal.deliver`, `deal.payment`, `bulk.status`, `stock.in`, `stock.adjust`, `stock.transfer`. Build them with `OfflineAction` (see "Outbox action builders" below) rather than by hand.
- **App-wide parts:** `OfflineGate` (offline limit 3.4, hold 3.5, no internet 10.9, offline ended 10.10) is already wired in `app.dart`. `OfflineBar` (`features/sync/ui/offline_bar.dart`, the "Working offline" strip) is for your screen's header. `onlineProvider` is the phone's network.
- **Lock:** `core/lock` handles the PIN and fingerprint (`appLockProvider`), the quick sign-in and `ScreenGuard` (blocks screenshots on documents). The way in sets the PIN (2.5).

## What is already working from the brand app

- Splash ("Connect. Sell. Grow."), Welcome, Sign in (brand owner by email or phone, team member by mobile), Apply to list your brand (OTP and application), Forgot password (3 steps), team member's own password, PIN and fingerprint, Choose outlet and the first-time tour.
- Notifications inbox, settings and banner, routed by the brand `data.screen` values. Help, FAQs, support, ecosystem, privacy and terms. The Settings shell and its phone screens.
- The Menu (12.1–12.3): rows follow role, permissions and add-ons, and link to every feature route.
- The state screens: maintenance, update, removed, no plan, not in role, restricted, signed out and not found.
- The tab shell: Home · Orders · ＋ (Quick actions) · Bulk deals · Products, with a rail on tablets.

## Outbox action builders (Sync engineer)

The server's contract is `C:\xampp\htdocs\atomshop\docs\brand-app-sync.md`. Each outbox action replays the Brand App call it stands for, with that call's permission, outlet scope, billing and add-on checks, so `data` holds that call's own fields. Never write an action key or a `data` map by hand: build an `OfflineAction` (`core/db/outbox_actions.dart`) and queue it with `OfflineSaves.saveAction`.

```dart
final saves = ref.read(offlineSavesProvider);          // null without the Offline add-on
final action = OfflineAction.orderPayment(
  orderUuid: order.uuid, amount: 5000, method: 'cash',
  seenPaid: order.paid,                                 // what the person saw (§6.3)
  receipt: photo,                                       // files go by the server's field name
);
final saved = saves == null
    ? await repo.recordPayment(...)                     // online only, as before
    : await saves.saveAction(action,
        send: () => repo.recordPayment(...),            // the normal online call, tried first
        alsoHere: (store, shopId) => store.patchRow('orders', order.id, {...}, shopId: shopId));
switch (saved) {
  case SavedOnServer(): ...                             // the server took it
  case SavedHere(): showSavedHereToast(context);        // queued: no signal
  case SaveFailed(:final failure): ...                  // the server refused it
}
```

| Builder | Action · call | Required | Optional | `seen` | Files |
|---|---|---|---|---|---|
| `OfflineAction.orderStatus` | `order.status` · `POST orders/{uuid}/status` | `orderUuid`, `status` (`OrderSteps`: `Varification`, `Processing`, `Delivered`, `Completed`, `Cancelled`), `seenStatus`; Delivered: `receivedBy`; Cancelled: `reasons` or `reason` | `serial`, `codAmount`, `codMethod` (Delivered) | `{status}` (required) | `deliveredPhoto` → `delivered_photo` |
| `OfflineAction.orderCancel` | `order.cancel` · same call, Cancelled | `orderUuid`, `seenStatus`, `reasons` (keys of `cancel_reasons`) or `reason` | | `{status}` | |
| `OfflineAction.orderPayment` | `order.payment` · `POST orders/{uuid}/payment` (also the seller's payment on a handed-over AtomPay order) | `orderUuid`, `amount` > 0, `method` | `reference`, `paidOn` (a day) | `{paid}` when `seenPaid` is given | `receipt` |
| `OfflineAction.atompayHandover` | `atompay.handover` · `POST atompay/{uuid}/handover` | `orderUuid`, `receivedBy` | `serial`, `note`, `seenStep` (default `handover`) | `{step}` | `photo` |
| `OfflineAction.dealDeliver` | `deal.deliver` · `POST deals/{id}/deliver` | `dealId`, `items` `{dealItemId: (qty:, serials:)}` (lines with qty 0 are dropped), `receivedBy` | `note`, `deliveredOn` | | `photo` |
| `OfflineAction.dealPayment` | `deal.payment` · `POST deals/{id}/payment` | `dealId`, `amount` > 0, `method` (one of `deal_payment_methods`) | `reference`, `paidOn`, `seenPaid` | `{paid}` | `receipt` |
| `OfflineAction.bulkStatus` | `bulk.status` · `POST bulk-orders/{id}/status` | `requestId`, `status` (`BulkSteps`: `New Lead`, `Contacted`, `Lost`); Lost: `reason` | `comments`, `seenStatus` | `{status}` | |
| `OfflineAction.stockIn` | `stock.in` · `POST stock/in` | `variantId`, `warehouseId`, `qty` > 0 | `serials` (one per unit; none for auto-numbered products), `reference`, `note`, `movedOn` | | |
| `OfflineAction.stockAdjustOut` | `stock.adjust` (out) · `POST stock/adjust` | `unitId` or `serial` (a unit stocked in offline has no id yet), `reason`, `note` | `movedOn` | | |
| `OfflineAction.stockAdjustIn` | `stock.adjust` (in) | `variantId`, `warehouseId`, `reason`, `note` | `serial`, `movedOn` | | |
| `OfflineAction.stockTransfer` | `stock.transfer` · `POST stock/transfer` | `toWarehouseId`, and `unitIds` and/or `serials` | `note`, `movedOn` | | |

- A builder throws `ArgumentError` for a field the server would refuse as missing (no `seenStatus`, Delivered without `receivedBy`, Lost without a reason, serials that don't match `qty`…), so the mistake shows on your screen, not later in Needs attention.
- Dates are sent as `YYYY-MM-DD`; the action's `at` (the real time it happened) is sent in UTC, and the server dates payments, deliveries and stock by its day when no date is given.
- Online only, never queued (§6.4): quotes, won/lost, order move, product save, warehouses, tracking, team, outlets, settings, billing and Ask Atom (`SyncActionKeys.onlineOnly`). Call their endpoints directly.
- **Answers** (`SyncReasons`): `done` and `done_with_changes` leave the outbox (the download that follows brings the server's rows, auto numbers included). `needs_attention` with `server_error` / `busy` stays waiting and is resent. Every other reason goes to Needs attention (10.3) with the server's whole answer kept (`SyncStore.answerOf(id)`): `seen_changed` shows what the server has now and opens the record, `serial_clash` opens Fix a serial clash (10.4, `${V2Routes.syncClash}?id=<action id>`), the rest offer Try again (after a bill is paid or a permission given) or Discard.
- **Rows made offline:** pass `tempId:` to `saveAction` and add the stand-in with `store.addLocalRow(table, tempId:, fields:, shopId:)`; it goes when the action is applied.
- **Reading the copy:** table names are the snapshot's (`SyncStore.tables`): `account`, `outlets`, `team`, `products`, `orders`, `atompay_orders`, `order_payments`, `order_history`, `bulk_requests`, `quotes`, `deals`, `deliveries`, `deal_payments`, `warehouses`, `stock_products`, `stock_variants`, `stock_balances`, `stock_units`, `stock_holds`, `notifications`. A deleted order takes its `order_payments` and `order_history`; a deleted deal its `deliveries` and `deal_payments`.
- **Phone registration and wipe:** the Sync feature calls `sync/check` with this install's `device_id` right after sign-in and on every open (for every brand, add-on or not). `wipe: true` deletes the copy, its photos and this person's outbox, ends the session and shows Account on hold (3.5) with the server's reason; a 401 from any call deletes the same and goes to Signed out. Wrong PINs never wipe.
