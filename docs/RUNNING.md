# Run and package

## Common preparation

Shop and godam stock are available under **More → Stock**. Use **Items** to search stock by location, or **Godams & transfers** to add godams and transfer stock.

The shop location is now named **Shop**. Batch numbers are automatic, with optional expiry controls shown only on incoming product stock. Sales and transfers select stock automatically. Direct entries between two people update both khatas, with cash received and paid onward through Shop. Icons are green for in, red for out and blue for direct entries.

Crop entries include purchase and sale rates. **Rate later** is available for product, crop and diesel entries throughout the app. Source/destination chips open their person/godam lists directly. Give/Receive Payment shows pending bills with a blank amount; entry lists and statements include quantities and rates.

Use Flutter stable 3.47.8, Dart 3.13.7, Node 22 and Git. Run commands from the project root:

```powershell
flutter doctor -v
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter analyze
flutter test
```

The generated Drift file and localization files are committed for convenient inspection, but regeneration is part of verification. Local demo does not need Firebase. For real accounts append `--dart-define-from-file=config/firebase.json` to every run/build.

On this PC, the workspace path contains a space. Use `tool\flutter.cmd` and `tool\dart.cmd` in place of `flutter`/`dart` to run the local SDK through Windows' existing short-path alias. This avoids a native-assets hook quoting issue in the current SDK. For another machine, install Flutter in a path without spaces, as Flutter recommends.

## Android

Install Android Studio's SDK, command-line tools and JDK 17 or a Flutter-supported newer JDK. Accept licenses, connect a device/emulator and verify `flutter doctor`.

```powershell
flutter doctor --android-licenses
flutter run -d android
flutter build apk --release --dart-define-from-file=config/firebase.json
flutter build appbundle --release --dart-define-from-file=config/firebase.json
```

Use the device ID from `flutter devices` if `-d android` is ambiguous. Configure a release keystore and Gradle signing; do not ship the template debug key. Add release SHA fingerprints to Firebase. Internet permission is required in the main Android manifest, not only debug. Database and cached records work without network after sign-in.

Copy `android/key.properties.example` to `android/key.properties` and supply your private keystore path, alias and passwords. Release tasks fail with a setup message until this file exists; debug runs do not need it. Keystore files and actual signing properties are ignored by Git.

## iOS (requires macOS)

Install Xcode, its command-line tools and supported CocoaPods. Open `ios/Runner.xcworkspace`, select a development team and confirm `com.pestikhata.app` (or your chosen ID consistently). Configure Firebase plist, Google URL scheme, APNs and phone-auth requirements.

```sh
flutter pub get
cd ios && pod install && cd ..
flutter run -d YOUR_IOS_DEVICE --dart-define-from-file=config/firebase.json
flutter build ipa --release --dart-define-from-file=config/firebase.json
```

The project can be authored on Windows, but Xcode signing, simulator testing and IPA compilation must run on macOS.

## Windows

Install Visual Studio 2022 or later with **Desktop development with C++**, CMake and a Windows SDK. VS Code alone does not provide the native compiler.

```powershell
flutter config --enable-windows-desktop
flutter run -d windows
flutter build windows --release --dart-define-from-file=config/firebase.json
```

Package the full release bundle, including dependent DLLs and data; do not copy just the EXE. Secure token storage and SQLite use native plugins. Configure a signed installer/MSIX for distribution. Numeric email login uses Firebase Auth REST directly; Google/phone use the hosted browser approval flow. The Windows process never initializes a FlutterFire Firebase app.

## Web

```powershell
flutter run -d chrome
flutter build web --release --no-web-resources-cdn
node tool/build_service_worker.mjs
```

Serve `build/web` over HTTPS or localhost. Firebase Hosting instructions are in the setup guide. First load online, wait for the offline shell to cache, sign into or open a demo shop, then test offline reload. Persistent SQLite files are scoped to origin/browser profile. Incognito, browser storage clearing and a changed hosting domain can remove local data; export regularly.

Google login popups and Drift shared-memory headers have browser compatibility tradeoffs. This project uses popup-compatible headers and persistent fallback storage. Prefer one active tab on Android web and test browser persistence on the actual shop hardware. Native Android/Windows clients provide a more predictable primary offline terminal.

## Verification and emulators

```powershell
.\tool\verify.ps1 -BuildWeb
cd functions
npm install
npm test
cd ..
npx firebase-tools emulators:exec --project demo-pestikhata --only firestore "npm --prefix functions run test:rules"
```

The Firestore emulator requires Java 21. Backend tests skip rule tests explicitly when no emulator is present; skipped tests are not a security verification result. GitHub Actions starts the emulator separately to test rules. Unit and repository tests use in-memory SQLite and do not contact a production Firebase project.

On this workspace, `.\tool\verify_rules.ps1` selects the locally installed portable Java and Firebase CLI automatically. `node tool/browser_smoke.mjs` checks the built web app in headless Chrome, including saved-data persistence after offline reload.

