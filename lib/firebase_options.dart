import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Safe, unconfigured defaults. Supply --dart-define-from-file=config/firebase.json
/// after creating a project. Keep this adapter; generate FlutterFire's registration
/// output into a separate file as described in docs/FIREBASE_SETUP.md.
abstract final class DefaultFirebaseOptions {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const functionsBase = String.fromEnvironment('FUNCTIONS_BASE_URL');
  static const webOrigin = String.fromEnvironment('AUTH_WEB_ORIGIN');
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static bool get configured {
    if (apiKey.isEmpty || projectId.isEmpty || functionsBase.isEmpty) {
      return false;
    }
    if (windows) return true;
    return currentPlatform.appId.isNotEmpty &&
        currentPlatform.messagingSenderId.isNotEmpty;
  }

  static bool get windows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  static FirebaseOptions get currentPlatform => FirebaseOptions(
    apiKey: apiKey,
    projectId: projectId,
    appId: kIsWeb
        ? const String.fromEnvironment('FIREBASE_WEB_APP_ID')
        : defaultTargetPlatform == TargetPlatform.iOS
        ? const String.fromEnvironment('FIREBASE_IOS_APP_ID')
        : const String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: const String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    ),
    authDomain: const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: 'com.pestikhata.app',
  );
}
