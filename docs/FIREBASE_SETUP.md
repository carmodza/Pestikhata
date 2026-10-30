# Firebase setup

No Firebase project or credentials were supplied. The default configuration intentionally enables **local demo only**. Follow these steps with your own account; nothing in this repository creates billing resources automatically.

## 1. Project and apps

1. Create a Firebase project. Choose a suitable Firestore region before adding data; `asia-south1` is used for Functions in this project. Create Firestore in production mode and a Storage bucket. Cloud Functions and Storage may require the Blaze plan; configure budget alerts and API quotas.
2. Register Android and iOS apps with ID **`com.pestikhata.app`**, plus a Web app. Windows uses the Web project's API key and REST APIs, not FlutterFire's unsupported production Windows SDK.
3. Install Firebase CLI and FlutterFire CLI:

```powershell
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
firebase use --add
flutterfire configure --project=YOUR_PROJECT_ID --platforms=android,ios,web --out=lib/firebase_registered_options.dart
```

Keep the existing `lib/firebase_options.dart` environment adapter. The separate generated registration file helps identify app IDs. Place downloaded `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` where required by the providers; these are ignored by Git. Re-run platform registration if you change application IDs.

Copy `config/firebase.example.json` to **`config/firebase.json`** (ignored by Git) and populate:

| Key | Value |
| --- | --- |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_API_KEY` | Web/API key from this Firebase project |
| `FIREBASE_WEB_APP_ID` | Web app ID |
| `FIREBASE_ANDROID_APP_ID` | Android app ID |
| `FIREBASE_IOS_APP_ID` | iOS app ID |
| `FIREBASE_MESSAGING_SENDER_ID` | Project number / sender ID |
| `FIREBASE_AUTH_DOMAIN` | Usually `PROJECT_ID.firebaseapp.com` |
| `FIREBASE_STORAGE_BUCKET` | Exact bucket name from Firebase, including its suffix |
| `FUNCTIONS_BASE_URL` | `https://asia-south1-PROJECT_ID.cloudfunctions.net` |
| `AUTH_WEB_ORIGIN` | Your HTTPS deployed web origin, e.g. `https://PROJECT_ID.web.app` |
| `GOOGLE_WEB_CLIENT_ID` | OAuth Web application client ID ending in `.apps.googleusercontent.com`; required for Android Google sign-in |
| `GOOGLE_IOS_CLIENT_ID` | OAuth iOS client ID from `CLIENT_ID` in `GoogleService-Info.plist` |

These client configuration values are not Admin SDK credentials. Never put a service-account key, SMTP password or OTP pepper in Flutter defines. `lib/firebase_options.dart` reads the correct platform app ID. All live runs/builds need `--dart-define-from-file=config/firebase.json`.

## 2. Auth providers

- **Google:** Enable Google in Firebase Authentication and set the support email. Add Android SHA-1/SHA-256 signing fingerprints for debug and release. Set `GOOGLE_WEB_CLIENT_ID` to the OAuth **Web application** client ID from Google Cloud Credentials (or the `oauth_client` with `client_type: 3` in the downloaded Android JSON). This app passes that value as `serverClientId`; merely copying the JSON into Android does not generate Gradle resources in this project. Set `GOOGLE_IOS_CLIENT_ID` to the iOS OAuth client ID. No client secret belongs in the app. See the maintained [Android package setup](https://pub.dev/packages/google_sign_in_android) and [iOS package setup](https://pub.dev/packages/google_sign_in_ios).

  On iOS, add `GoogleService-Info.plist` to the **Runner target** in Xcode, and register its `REVERSED_CLIENT_ID` under Runner → Info → URL Types → URL Schemes. Registering the URL scheme is still required when client IDs are supplied in Dart. Use values from your downloaded file; do not substitute the Web client ID for the iOS URL scheme.
- **Phone:** Enable Phone in Authentication, permit Pakistan in SMS region policy and configure reCAPTCHA/Play Integrity/APNs requirements for each platform. Add your hosting/custom domain under authorized domains. Use Firebase test phone numbers for integration tests instead of repeatedly sending real SMS. The app accepts E.164 numbers such as `+923001234567`.
- **Numeric email code:** Implemented by `requestEmailCode` and `verifyEmailCode`; this is not Firebase's email-link flow. Provide an authenticated SMTP sender you control. Codes are six digits, valid five minutes, HMAC-protected, single-use, limited to five verification attempts, and rate-limited by email/IP. After proof of email ownership the server issues a Firebase custom token.
- **Windows Google/phone:** The app opens the hosted login page, shows a matching six-character code, and waits for the user to explicitly approve in the browser. The desktop holds a separate 256-bit polling secret. The browser URL never contains an ID token, refresh token or custom token. The result is exchanged through Firebase Auth REST and the refresh token is stored using platform secure storage.

## 3. Functions and secrets

Install the Node 22 runtime locally for tooling. The deployed runtime is Node 22.

```powershell
cd functions
npm install
npm test
Copy-Item .env.example .env
cd ..
firebase functions:secrets:set SMTP_USER
firebase functions:secrets:set SMTP_PASSWORD
firebase functions:secrets:set OTP_PEPPER
```

Set a cryptographically random OTP pepper of at least 32 bytes. Edit Functions' `.env` with your SMTP host, port and verified `EMAIL_FROM`. Standard STARTTLS port 587 and TLS port 465 are supported. Deploy:

```powershell
firebase deploy --only functions,firestore:rules,firestore:indexes,storage
```

The Functions runtime service account must be able to sign Firebase custom tokens (configure **Service Account Token Creator** as needed) and access the configured secrets, Firestore and Auth. Do not use downloadable service-account keys in the client. The Admin SDK uses the runtime identity.

`firestore.indexes.json` includes TTL policies for expiring OTP challenges, invitations, desktop sessions and rate limits. Expiration is checked in server code as well; TTL deletion is asynchronous. Configure Firebase/Cloud Monitoring quotas, alerts and audit-log retention for your deployment.

## 4. Roles and tenant isolation

The first user chooses Create shop to become its owner. Each login has one server-managed `users/{uid}.shopId`. The owner creates single-use 48-hour staff invitation codes under More → Users. Staff enter a code on the Join shop screen. Users cannot assign their own shop or role with Firestore client writes.

`shops/{shopId}/members/{uid}` is the server authority. The rules enforce membership on every record read/write, prohibit hard deletion and staff tombstones/voids, validate envelopes and financial payloads, preserve immutable journal fields, and constrain client timestamps. Owner revocation removes membership and revokes refresh tokens. Cached disconnected data remains available until reconnection, as with other offline applications.

Storage rules allow only the shop owner to create/read JSON backup objects in that shop's path. Deployment may prompt to grant Storage's service agent permission to read Firestore membership for cross-service rules. Grant that documented Firebase permission if prompted.

## 5. Web build and hosting

```powershell
flutter build web --release --no-web-resources-cdn --dart-define-from-file=config/firebase.json
node tool/build_service_worker.mjs
firebase deploy --only hosting
```

The build must contain `sqlite3.wasm` and `drift_worker.dart.js`; they are checked in under `web/`. If upgrading Drift, download matching assets from its release or run `tool/fetch_drift_assets.ps1` after resolving dependencies. The offline shell is generated **after** the Flutter build. Keep `canvasKitBaseUrl` local so an internet connection is not needed to fetch the renderer on a cached session.

Hosting rewrites deep links to `index.html`, serves WASM with the correct MIME type and uses popup-compatible COOP. Add the deployed domain to Auth's authorized domains, update `AUTH_WEB_ORIGIN` if needed and rebuild clients.

## 6. Verify before live use

Deploy the current `firestore.rules` with this client version. Older deployed rules reject direct people-to-people entries, optional receipt expiry and the new immutable stock-allocation payload. Use `firebase deploy --only firestore:rules` when updating an already configured project.

Run two separate signed-in devices against a test project. Verify real SMS, numeric email, Google on each target platform, owner creation, staff invite/revocation, tenant isolation, offline saves/restart, conflicting rate edits, synchronization after reconnect and local/cloud restore. Then configure app signing, provider consent/domain verification, operational backups and monitoring before onboarding real shops.

Official references: [Flutter Firebase setup](https://firebase.google.com/docs/flutter/setup), [Firestore REST](https://firebase.google.com/docs/firestore/use-rest-api), [HTTP Functions](https://firebase.google.com/docs/functions/http-events), [Functions secrets](https://firebase.google.com/docs/functions/config-env), [Drift Web](https://drift.simonbinder.eu/platforms/web/).
