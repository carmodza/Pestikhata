import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pestikhata/core/data/shop_repository.dart';
import 'package:pestikhata/core/database/app_database.dart';
import 'package:pestikhata/core/domain/models.dart';
import 'package:pestikhata/features/auth/data/auth_repository.dart';
import 'package:pestikhata/features/backup/data/backup_service.dart';

class _Auth extends AuthRepository {
  _Auth() : super(const FlutterSecureStorage());
  @override
  bool get configured => true;
  @override
  Future<String> token() async => 'id-token';
}

void main() {
  late AppDatabase db;
  late ShopRepository repository;
  late _Auth auth;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ShopRepository(db, 'shop', 'device', AppRole.owner, 'owner');
    auth = _Auth();
  });
  tearDown(() async {
    await db.close();
    await auth.dispose();
  });

  test(
    'cloud backup lists every page, authenticates and orders newest first',
    () async {
      var requests = 0;
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Firebase id-token');
        expect(request.url.queryParameters['prefix'], 'shops/shop/backups/');
        requests++;
        if (requests == 1) {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'name': 'shops/shop/backups/old.json',
                  'updated': '2026-10-29T10:00:00Z',
                },
              ],
              'nextPageToken': 'second',
            }),
            200,
          );
        }
        expect(request.url.queryParameters['pageToken'], 'second');
        return http.Response(
          jsonEncode({
            'items': [
              {
                'name': 'shops/shop/backups/new.json',
                'updated': '2026-10-30T10:00:00Z',
              },
            ],
          }),
          200,
        );
      });
      addTearDown(client.close);
      final service = BackupService(
        repository,
        auth,
        client: client,
        storageBucket: 'test-bucket',
      );
      final files = await service.list();
      expect(requests, 2);
      expect(files.map((f) => f.name), [
        'shops/shop/backups/new.json',
        'shops/shop/backups/old.json',
      ]);
    },
  );
  test(
    'cloud upload contains a same-shop backup and restore preserves its data',
    () async {
      await repository.savePerson(
        const Person(id: 'farmer', name: 'Ali', kind: PartyKind.farmer),
      );
      final saved = await repository.backup();
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Firebase id-token');
        if (request.method == 'POST') {
          expect(
            request.url.queryParameters['name'],
            startsWith('shops/shop/backups/'),
          );
          expect((jsonDecode(request.body) as Json)['shopId'], 'shop');
          return http.Response('{}', 200);
        }
        expect(request.url.queryParameters['alt'], 'media');
        return http.Response(saved, 200);
      });
      addTearDown(client.close);
      final service = BackupService(
        repository,
        auth,
        client: client,
        storageBucket: 'test-bucket',
      );
      await service.upload();
      await service.restoreCloud(
        const CloudBackup('shops/shop/backups/saved.json', ''),
      );
      expect((await repository.snapshot()).people.single.name, 'Ali');
      await expectLater(
        service.restoreCloud(
          const CloudBackup('shops/other/backups/private.json', ''),
        ),
        throwsA(isA<DomainFailure>()),
      );
    },
  );
}
