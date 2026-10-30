# Verification and release status

Validated on 30 October 2026 in this Windows workspace using Flutter 3.47.8 / Dart 3.13.7 and Chrome 156. Backend compilation and unit tests ran with Node 24; deployment and CI use Node 22.

| Check | Result |
|---|---|
| `tool\flutter.cmd analyze --no-pub` | Passed, no issues |
| `tool\flutter.cmd test --timeout 90s` | 63 tests passed |
| `node tool/check_resources.mjs` | 293 matching English/Roman Urdu strings, JSON, SQLite WASM and icons passed |
| Backend helper tests | TypeScript compiled; 3 security helper tests passed; rules run separately in the emulator |
| `flutter build web --release --no-web-resources-cdn` | Passed |
| Generated offline service worker | Passed; caches local application resources |
| Chrome smoke test | Existing stock/module coverage retained; focused crop rates, immediate source picker, pending-payment mobile screen and offline SQLite reload passed |
| Firestore emulator tests | 13 passed, none skipped; tenant/role protections, direct trades, optional expiry, immutable allocations and pending diesel rates |

Tests cover exact paisa calculations, supplier/farmer balances, partial cash settlement, pending-rate completion, units, exact batch availability, godam transfers, immutable historical rates, owner/staff permissions, deterministic LWW, atomic outbox writes, stale acknowledgements, REST version-precondition retries and paginated pulls. An on-disk restart test verifies unsynced records, cash, khata and cursor persistence. Widget tests save cash and product entries through the center Entry control. PDF tests export 1,400 rows across more than twenty pages with bundled fonts and no network. Mock HTTP tests verify authenticated cloud backup upload/restore, tenant rejection and paginated archive listing; these do not replace a live Storage integration test.

The project includes fixes for product-selection price fields overwriting each other, staff editing finalized rates through Firestore, restored entries uploading before their catalog dependencies, stocked-item type changes, and hidden tap feedback inside frosted cards. Crop conversion rules live in the application layer: maan is 40 kg; bori is configured per crop.

Entry tests also cover generated receipt batches, optional expiry, automatic multi-lot allocation, expired-stock exclusion for automatic sales, godam transfers and returns, direct supplier/farmer and supplier/supplier khatas, gross cash-in/out with zero net direct cash, pending direct rates, atomic shortage rejection, allocation validation and backup replay. Widget tests save sale/receipt/direct entries and verify green/red/blue icons in both themes.

Payment-summary tests verify partial settlements, oldest-open-bill matching, cash advances, supplier payables, opposite payment directions and unpriced/voided bills. UI tests cover immediate person/godam lists, blank-amount pending-payment forms, crop purchase/sale price linkage, and crop/diesel pending rates completed from Home. Shared entry rows and statement exports include products, quantities, units and rates.

## Reproduce

```powershell
.\tool\verify.ps1 -BuildWeb
.\tool\verify_rules.ps1
node tool/browser_smoke.mjs
```

Use `node tool/browser_smoke.mjs --entry-updates` for the focused crop/payment/source-picker and offline-reload browser checks. Screenshots include `crop-rates-mobile.png`, `pending-payment-mobile.png` and `source-picker-mobile.png` under `.tooling/previews/`.

The rules script uses workspace-local Java/CLI when installed, otherwise Java from PATH and Firebase CLI through npx. It uses the `demo-pestikhata` emulator project. The browser script requires Chrome at its standard Windows installation path and a built web bundle with the generated service worker. Screenshots are written to `.tooling/previews/`.

## Release checks still required

- Supply Firebase configuration, enable Google/phone providers, configure SMTP and deploy functions, indexes, rules and hosting using [FIREBASE_SETUP.md](FIREBASE_SETUP.md). No live project is connected or deployed.
- Verify real OTP delivery, Google/phone sign-in on all target platforms, invitations/revocation, cross-device offline conflicts and cloud backups against your staging project.
- Build and test Android with Android SDK/JDK and release signing. This PC has no Android SDK.
- Build and test Windows with Visual Studio's C++ desktop workload. This PC has no Visual Studio native compiler.
- Build, sign and test iOS on macOS/Xcode.
- Test actual shop hardware/browser persistence, offline-cache installation and backup/restore before entering real accounts. Review costing and offline-concurrency behavior in [ARCHITECTURE.md](ARCHITECTURE.md).

The source and web bundle run locally. Native packaging and live Firebase integration are not release-verified by these checks.
