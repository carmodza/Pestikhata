# PestiKhata

Flutter shop management for Pakistani pesticide, fertilizer and seed shops: khata, roznamcha, stock, crops, godams, cash, expenses and rates. Material 3, light/dark/system themes, English and Roman Urdu.

## Start locally

Install Flutter stable (this workspace targets **3.47.8 / Dart 3.13.7**), then:

```powershell
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter run -d chrome
```

If using the workspace-local SDK, add `.tooling/flutter/bin` to your terminal PATH, or invoke `.tooling\flutter\bin\flutter.bat` directly. VS Code is configured to use that SDK when present. `tool/verify.ps1` runs generation, analysis, Flutter tests and backend checks.

Select **Try local demo**, then **Seed demo data** on Home. Settings contains the demo-data toggle. The demo uses its own `demo-local` shop partition and never syncs to Firebase. Live accounts start with an empty shop. No Firebase account or credentials are fabricated.

## Guides

- [Run and package Android, iOS, Windows and Web](docs/RUNNING.md)
- [Create and connect Firebase, deploy functions/rules/hosting](docs/FIREBASE_SETUP.md)
- [Architecture, accounting and offline conflict behavior](docs/ARCHITECTURE.md)
- [Verification results and release requirements](docs/VALIDATION.md)

## Main flows

Crop entries show both purchase and sale rates. Editing the applicable price updates the billed rate, which can still be overridden. **Rate later** is available on priced product, crop and diesel entries, including direct trades. Cash and ordinary expenses remain amount-based.

Tap a Farmer, Supplier or Godam source/destination chip to open its list immediately. Person lists include **Add new**. **Give payment** and **Receive payment** show the selected person's outstanding balance and pending bills; the amount is left blank. Payments settle the oldest open amounts first. Entries and exported ledgers include product/crop, quantity, unit and rate.

The internal shop location is labelled **Shop**. Incoming product stock receives an automatic batch number and an optional expiry date. Sales and godam transfers select stock automatically across available lots; no manual batch selection is required.

Direct entries between recorded people (for example Supplier → Farmer) update both khatas without moving Shop/Godam stock. Entered cash is received and paid onward through Shop, appearing in both cash-in and cash-out with no net cash change. These direct pass-through trades do not add shop profit. Entry icons show incoming movements in green, outgoing movements in red and direct entries in blue.

Open **More → Stock** for the merged Shop and Godam workspace. **Items** lists products/crops with an all-locations, shop-stock or individual-godam filter. **Godams & transfers** manages godams and stock movements. Existing records and location balances remain available, and legacy stock/location links open the merged workspace.

The center **Entry** button opens Cash, Pesticide/Fertilizer/Seed, Crops, Diesel and Other. Pick source and destination, then the person or godam where needed. All transaction writes first commit to Drift with a durable outbox record. Cash, person balances, stock, reports and daily balances are projections of the same journal.

For a purchase choose **Supplier → Shop/Godam**. For a sale choose **Shop/Godam → Farmer/Walk-in**. **Farmer → Shop** receives a khata payment; reverse it to pay that person. Internal stock movements are transfers. Cash between Walk-in and Shop also records owner capital or drawings; note the purpose. Diesel expenses use Shop as source and a supplier as destination for credit, or Walk-in for full cash payment.

Pending rates move stock immediately and record any cash advance. Home lists them for rate completion, which recalculates the priced balance without moving stock twice. Finalized entries keep their recorded rates until an owner explicitly edits the entry rate. Other corrections use void/re-entry. Voids retain the audit record and reverse projections.

## Included

- Riverpod state, go_router routes and owner route guards.
- Drift SQLite on native platforms; SQLite WASM and persistent browser storage on web.
- Farmer/supplier profiles and searchable khatas; PDF statement sharing through the operating system share/download flow.
- Batch/expiry inventory, configurable units, low stock, expiry and stock reconciliation alerts.
- Godam transfers, daily rates and history trends, dated expense/profit/crop/stock/udhar reports.
- Local JSON backup/merge restore, owner-only cloud backups, PDF and Excel exports.
- Phone SMS, numeric email OTP and Google sign-in; owner shop creation and single-use staff invitations.
- A Windows REST authentication/token-refresh and Firestore sync path with explicit browser approval for phone/Google sign-in.
- Atomic Firestore version preconditions, deterministic LWW conflict selection, automatic retries and visible sync state.
- Server-side membership management, per-shop security rules and OTP rate limiting.
- A generated offline web shell that caches local application assets without caching authenticated HTTP responses.

## Activation

Local demo and offline records are available without Firebase. Live sign-in, synchronization, invitations and cloud backup require a Firebase project plus an SMTP sender for numeric email codes. First sign-in and authorization changes require internet. Existing sessions keep their local shop data while offline. Revoked membership is enforced by the server on reconnection.

Native packaging/signing, live provider setup and the release acceptance checks in the guides must be completed before distributing this to real shops. This repository does not claim those external integrations are tested merely because source code exists.

