import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/domain/models.dart';
import '../../../firebase_options.dart';

class AppSession {
  const AppSession({
    required this.userId,
    required this.shopId,
    required this.shopName,
    required this.role,
    this.demo = false,
  });
  final String userId, shopId, shopName;
  final AppRole role;
  final bool demo;
  bool get hasShop => shopId.isNotEmpty;
  Json toJson() => {
    'userId': userId,
    'shopId': shopId,
    'shopName': shopName,
    'role': role.name,
    'demo': demo,
  };
  factory AppSession.fromJson(Json j) => AppSession(
    userId: j['userId'],
    shopId: j['shopId'],
    shopName: j['shopName'],
    role: AppRole.values.byName(j['role']),
    demo: j['demo'] ?? false,
  );
}

class ApiFailure extends DomainFailure {
  const ApiFailure(super.code, [this.status = 0]);
  final int status;
}

class AuthRepository {
  AuthRepository(this.storage);
  final FlutterSecureStorage storage;
  final String? desktopRequest = kIsWeb
      ? Uri.base.queryParameters['desktopSession']
      : null;
  final desktopCode = ValueNotifier<String?>(null);
  bool desktopCompleted = false;
  final _changes = StreamController<AppSession?>.broadcast();
  AppSession? session;
  String? _restIdToken, _restRefreshToken, _phoneVerificationId;
  DateTime _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(0);
  ConfirmationResult? _webConfirmation;
  bool _googleInitialized = false;
  Stream<AppSession?> get changes => _changes.stream;
  bool get configured => DefaultFirebaseOptions.configured;
  Future<void> initialize() async {
    final cached = await storage.read(key: 'session');
    if (cached != null) {
      try {
        session = AppSession.fromJson(jsonDecode(cached) as Json);
      } catch (_) {
        await storage.delete(key: 'session');
      }
    }
    _restRefreshToken = await storage.read(key: 'firebase_refresh_token');
  }

  Future<void> _set(AppSession? value) async {
    if (jsonEncode(session?.toJson()) == jsonEncode(value?.toJson())) return;
    session = value;
    if (value == null) {
      await storage.delete(key: 'session');
    } else {
      await storage.write(key: 'session', value: jsonEncode(value.toJson()));
    }
    _changes.add(value);
  }

  void _requireConfig() {
    if (!configured) throw const DomainFailure('firebaseNotConfigured');
  }

  Future<Json> publicCall(String name, Json body) => _request(
    Uri.parse('${DefaultFirebaseOptions.functionsBase}/$name'),
    body,
  );
  Future<Json> call(String name, Json body) async => _request(
    Uri.parse('${DefaultFirebaseOptions.functionsBase}/$name'),
    body,
    headers: {'Authorization': 'Bearer ${await token()}'},
  );

  static Future<Json> _request(
    Uri uri,
    Json body, {
    Map<String, String>? headers,
  }) async {
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json', ...?headers},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    Json result;
    try {
      result = jsonDecode(response.body) as Json;
    } catch (_) {
      throw ApiFailure('serverError', response.statusCode);
    }
    if (response.statusCode >= 400) {
      final error = result['error'];
      throw ApiFailure(
        error is Map
            ? error['message']?.toString() ?? 'serverError'
            : error?.toString() ?? 'serverError',
        response.statusCode,
      );
    }
    return result;
  }

  Future<String> token() async {
    _requireConfig();
    if (DefaultFirebaseOptions.windows) {
      if (_restIdToken != null && DateTime.now().isBefore(_tokenExpiry)) {
        return _restIdToken!;
      }
      if (_restRefreshToken == null) {
        throw const ApiFailure('sessionExpired', 401);
      }
      final response = await http
          .post(
            Uri.parse(
              'https://securetoken.googleapis.com/v1/token?key=${DefaultFirebaseOptions.apiKey}',
            ),
            body: {
              'grant_type': 'refresh_token',
              'refresh_token': _restRefreshToken!,
            },
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw const ApiFailure('sessionExpired', 401);
      }
      final result = jsonDecode(response.body) as Json;
      _restIdToken = result['id_token'];
      _restRefreshToken = result['refresh_token'];
      _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
      await storage.write(
        key: 'firebase_refresh_token',
        value: _restRefreshToken,
      );
      return _restIdToken!;
    }
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) throw const ApiFailure('sessionExpired', 401);
    return (await current.getIdToken())!;
  }

  Future<void> requestEmailCode(String email) async {
    _requireConfig();
    await publicCall('requestEmailCode', {'email': email.trim()});
  }

  Future<void> verifyEmailCode(String email, String code) async {
    _requireConfig();
    final result = await publicCall('verifyEmailCode', {
      'email': email.trim(),
      'code': code.trim(),
    });
    await _customToken(result['token'] as String);
    await refreshProfile();
  }

  Future<void> _customToken(String customToken) async {
    if (DefaultFirebaseOptions.windows) {
      final result = await _request(
        Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${DefaultFirebaseOptions.apiKey}',
        ),
        {'token': customToken, 'returnSecureToken': true},
      );
      _restIdToken = result['idToken'];
      _restRefreshToken = result['refreshToken'];
      _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
      await storage.write(
        key: 'firebase_refresh_token',
        value: _restRefreshToken,
      );
    } else {
      await FirebaseAuth.instance.signInWithCustomToken(customToken);
    }
  }

  Future<void> sendPhoneCode(String phone) async {
    _requireConfig();
    if (DefaultFirebaseOptions.windows) {
      await desktopSignIn();
      return;
    }
    if (kIsWeb) {
      _webConfirmation = await FirebaseAuth.instance.signInWithPhoneNumber(
        phone,
      );
    } else {
      final completer = Completer<void>();
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            await refreshProfile();
            if (!completer.isCompleted) completer.complete();
          } catch (error) {
            if (!completer.isCompleted) completer.completeError(error);
          }
        },
        verificationFailed: (error) {
          if (!completer.isCompleted) completer.completeError(error);
        },
        codeSent: (id, _) {
          _phoneVerificationId = id;
          if (!completer.isCompleted) completer.complete();
        },
        codeAutoRetrievalTimeout: (id) {
          _phoneVerificationId = id;
          if (!completer.isCompleted) completer.complete();
        },
      );
      await completer.future;
    }
  }

  Future<void> verifyPhoneCode(String code) async {
    if (kIsWeb) {
      if (_webConfirmation == null) {
        throw const DomainFailure('requestCodeFirst');
      }
      await _webConfirmation!.confirm(code);
    } else {
      if (_phoneVerificationId == null) {
        throw const DomainFailure('requestCodeFirst');
      }
      await FirebaseAuth.instance.signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: _phoneVerificationId!,
          smsCode: code,
        ),
      );
    }
    await refreshProfile();
  }

  Future<void> google() async {
    _requireConfig();
    if (DefaultFirebaseOptions.windows) {
      await desktopSignIn();
      return;
    }
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } else {
      if (!_googleInitialized) {
        final serverId = DefaultFirebaseOptions.googleWebClientId;
        final iosId = DefaultFirebaseOptions.googleIosClientId;
        if (defaultTargetPlatform == TargetPlatform.android &&
            serverId.isEmpty) {
          throw const DomainFailure('firebaseNotConfigured');
        }
        await GoogleSignIn.instance.initialize(
          serverClientId: serverId.isEmpty ? null : serverId,
          clientId:
              defaultTargetPlatform == TargetPlatform.iOS && iosId.isNotEmpty
              ? iosId
              : null,
        );
        _googleInitialized = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: account.authentication.idToken),
      );
    }
    await refreshProfile();
  }

  Future<void> desktopSignIn() async {
    _requireConfig();
    final secretBytes = List.generate(32, (_) => Random.secure().nextInt(256));
    final secret = base64UrlEncode(secretBytes).replaceAll('=', '');
    final result = await publicCall('startDesktopSignIn', {'secret': secret});
    final id = result['sessionId'] as String;
    desktopCode.value = id.substring(id.length - 6).toUpperCase();
    final origin = Uri.parse(DefaultFirebaseOptions.webOrigin);
    if (origin.scheme != 'https' && origin.host != 'localhost') {
      throw const DomainFailure('firebaseNotConfigured');
    }
    final url = origin.replace(
      path: '/login',
      queryParameters: {'desktopSession': id},
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw const DomainFailure('browserFailed');
    }
    for (var attempt = 0; attempt < 100; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      final poll = await publicCall('pollDesktopSignIn', {
        'sessionId': id,
        'secret': secret,
      });
      if (poll['token'] != null) {
        desktopCode.value = null;
        await _customToken(poll['token'] as String);
        await refreshProfile();
        return;
      }
    }
    throw const DomainFailure('codeExpired');
  }

  Future<void> completeDesktop(String sessionId) async {
    await call('completeDesktopSignIn', {'sessionId': sessionId});
    desktopCompleted = true;
  }

  Future<void> refreshProfile() async {
    final result = await call('getProfile', {});
    await _set(
      AppSession(
        userId: result['userId'],
        shopId: result['shopId'] ?? '',
        shopName: result['shopName'] ?? '',
        role: result['role'] == 'owner' ? AppRole.owner : AppRole.staff,
      ),
    );
  }

  Future<void> createShop(String name) async {
    await call('createShop', {'name': name.trim()});
    await refreshProfile();
  }

  Future<void> joinShop(String code) async {
    await call('joinShop', {'code': code.trim()});
    await refreshProfile();
  }

  Future<void> enterDemo() => _set(
    const AppSession(
      userId: 'demo-owner',
      shopId: 'demo-local',
      shopName: 'Punjab Agri Traders',
      role: AppRole.owner,
      demo: true,
    ),
  );
  Future<void> signOut() async {
    if (configured && !DefaultFirebaseOptions.windows) {
      await FirebaseAuth.instance.signOut();
    }
    _restIdToken = null;
    _restRefreshToken = null;
    await storage.delete(key: 'firebase_refresh_token');
    await _set(null);
  }

  Future<void> dispose() {
    desktopCode.dispose();
    return _changes.close();
  }
}
