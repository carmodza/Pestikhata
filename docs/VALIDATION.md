# Verification and release status

Validated on 30 October 2026 in this Windows workspace using Flutter 3.47.8 / Dart 3.13.7 and Chrome 156. Backend compilation and unit tests ran with Node 24; deployment and CI use Node 22.

| Check | Result |
|---|---|
| `tool\flutter.cmd analyze --no-pub` | Passed, no issues |
| `tool\flutter.cmd test --timeout 90s` | 54 tests passed |
| `node tool/check_resources.mjs` | 285 matching English/Roman Urdu strings, JSON, SQLite WASM and icons passed |
| Backend helper tests | TypeScript compiled; 3 security helper tests passed; rules run separately in the emulator |
| `flutter build web --release --no-web-resources-cdn` | Passed |
| Generated offline service worker | Passed; caches local application resources |
| Chrome smoke test | Merged Stock tabs, location filtering, legacy Inventory/Godam redirects, all modules, languages/themes, desktop/mobile and offline reload passed |
| Firestore emulator tests | 12 passed, none skipped; tenant/role protections, direct trades, optional expiry and immutable stock allocations |

Tests cover exact paisa calculations, supplier/farmer balances, partial cash settlement, pending-rate completion, units, exact batch availability, godam transfers, immutable historical rates, owner/staff permissions, deterministic LWW, atomic outbox writes, stale acknowledgements, REST version-precondition retries and paginated pulls. An on-disk restart test verifies unsynced records, cash, khata and cursor persistence. Widget tests save cash and product entries through the center Entry control. PDF tests export 1,400 rows across more than twenty pages with bundled fonts and no network. Mock HTTP tests verify authenticated cloud backup upload/restore, tenant rejection and paginated archive listing; these do not replace a live Storage integration test.

The project includes fixes for product-selection price fields overwriting each other, staff editing finalized rates through Firestore, restored entries uploading before their catalog dependencies, stocked-item type changes, and hidden tap feedback inside frosted cards. Crop conversion rules live in the application layer: maan is 40 kg; bori is configured per crop.

Entry tests also cover generated receipt batches, optional expiry, automatic multi-lot allocation, expired-stock exclusion for automatic sales, godam transfers and returns, direct supplier/farmer and supplier/supplier khatas, gross cash-in/out with zero net direct cash, pending direct rates, atomic shortage rejection, allocation validation and backup replay. Widget tests save sale/receipt/direct entries and verify green/red/blue icons in both themes.

## Reproduce

```powershell
.\tool\verify.ps1 -BuildWeb
.\tool\verify_rules.ps1
node tool/browser_smoke.mjs
```

The rules script uses workspace-local Java/CLI when installed, otherwise Java from PATH and Firebase CLI through npx. It uses the `demo-pestikhata` emulator project. The browser script requires Chrome at its standard Windows installation path and a built web bundle with the generated service worker. Screenshots are written to `.tooling/previews/`.

## Release checks still required

- Supply Firebase configuration, enable Google/phone providers, configure SMTP and deploy functions, indexes, rules and hosting using [FIREBASE_SETUP.md](FIREBASE_SETUP.md). No live project is connected or deployed.
- Verify real OTP delivery, Google/phone sign-in on all target platforms, invitations/revocation, cross-device offline conflicts and cloud backups against your staging project.
- Build and test Android with Android SDK/JDK and release signing. This PC has no Android SDK.
- Build and test Windows with Visual Studio's C++ desktop workload. This PC has no Visual Studio native compiler.
- Build, sign and test iOS on macOS/Xcode.
- Test actual shop hardware/browser persistence, offline-cache installation and backup/restore before entering real accounts. Review costing and offline-concurrency behavior in [ARCHITECTURE.md](ARCHITECTURE.md).

The source and web bundle run locally. Native packaging and live Firebase integration are not release-verified by these checks.
