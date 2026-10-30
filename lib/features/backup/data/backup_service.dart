import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../../../core/data/shop_repository.dart';
import '../../../core/domain/models.dart';
import '../../auth/data/auth_repository.dart';

class CloudBackup {
  const CloudBackup(this.name, this.updated);
  final String name, updated;
}

class BackupService {
  const BackupService(
    this.repository,
    this.auth, {
    this.client,
    this.storageBucket,
  });
  final ShopRepository repository;
  final AuthRepository auth;
  final http.Client? client;
  final String? storageBucket;
  String get bucket =>
      storageBucket ?? const String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  Future<Map<String, String>> get _headers async => {
    // The Firebase Storage v0 endpoint uses the Firebase ID-token scheme.
    'Authorization': 'Firebase ${await auth.token()}',
  };
  Future<http.Response> _get(Uri uri) async =>
      (client?.get ?? http.get)(uri, headers: await _headers);
  void _requireCloud() {
    repository.requireOwner();
    if (auth.session?.demo == true || !auth.configured || bucket.isEmpty) {
      throw const DomainFailure('cloudUnavailable');
    }
  }

  Future<void> exportLocal() async {
    final json = await repository.backup();
    await FilePicker.platform.saveFile(
      fileName:
          'pestikhata-${repository.shopId}-${DateTime.now().millisecondsSinceEpoch}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(utf8.encode(json)),
    );
  }

  Future<void> restoreLocal() async {
    repository.requireOwner();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null) return;
    final bytes = result.files.single.bytes;
    if (bytes == null || bytes.length > 50 * 1024 * 1024) {
      throw const DomainFailure('invalidBackup');
    }
    await repository.restore(utf8.decode(bytes));
  }

  Future<void> upload() async {
    _requireCloud();
    final name =
        'shops/${repository.shopId}/backups/${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}.json';
    final uri = Uri.https('firebasestorage.googleapis.com', '/v0/b/$bucket/o', {
      'uploadType': 'media',
      'name': name,
    });
    final response = await (client?.post ?? http.post)(
      uri,
      headers: {...await _headers, 'Content-Type': 'application/json'},
      body: await repository.backup(),
    ).timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw ApiFailure('operationFailed', response.statusCode);
    }
  }

  Future<List<CloudBackup>> list() async {
    _requireCloud();
    final files = <CloudBackup>[];
    String? page;
    do {
      final uri =
          Uri.https('firebasestorage.googleapis.com', '/v0/b/$bucket/o', {
            'prefix': 'shops/${repository.shopId}/backups/',
            'maxResults': '100',
            'pageToken': ?page,
          });
      final response = await _get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw ApiFailure('operationFailed', response.statusCode);
      }
      final body = jsonDecode(response.body) as Json;
      files.addAll(
        ((body['items'] ?? []) as List).map(
          (i) => CloudBackup(i['name'] as String, i['updated'] as String),
        ),
      );
      page = body['nextPageToken'] as String?;
    } while (page != null && page.isNotEmpty);
    files.sort((a, b) => b.updated.compareTo(a.updated));
    return files;
  }

  Future<void> restoreCloud(CloudBackup backup) async {
    _requireCloud();
    if (!backup.name.startsWith('shops/${repository.shopId}/backups/')) {
      throw const DomainFailure('invalidBackup');
    }
    final uri = Uri.parse(
      'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(backup.name)}?alt=media',
    );
    final response = await _get(uri).timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw ApiFailure('operationFailed', response.statusCode);
    }
    if (response.bodyBytes.length > 50 * 1024 * 1024) {
      throw const DomainFailure('invalidBackup');
    }
    await repository.restore(utf8.decode(response.bodyBytes));
  }
}
