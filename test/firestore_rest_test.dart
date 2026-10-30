import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pestikhata/core/domain/models.dart';
import 'package:pestikhata/core/sync/firestore_rest.dart';
import 'package:pestikhata/features/auth/data/auth_repository.dart';

class _TokenAuth extends AuthRepository {
  _TokenAuth() : super(const FlutterSecureStorage());
  @override
  Future<String> token() async => 'test-id-token';
}

void main() {
  RecordEnvelope record(
    int version, {
    String id = 'person',
    String device = 'device-a',
  }) => RecordEnvelope(
    id: id,
    entity: 'people',
    shopId: 'shop',
    payload: {'id': id, 'name': 'Ali', 'kind': 'farmer'},
    updatedAt: version,
    deviceId: device,
  );
  Json document(
    RecordEnvelope value, {
    String time = '2026-10-29T10:00:00.123456Z',
  }) => {
    'name':
        'projects/test/databases/(default)/documents/shops/shop/records/people_${value.id}',
    'updateTime': time,
    'fields': {
      ...value.toJson().map(
        (k, v) => MapEntry(k, FirestoreRest.encodeValue(v)),
      ),
      'committedAt': {'timestampValue': time},
    },
  };
  test('Firestore value codec preserves integers, nulls and nested maps', () {
    final value = {
      'amount': 9000000000000,
      'active': true,
      'nullable': null,
      'units': {'kg': 1.0},
      'list': [1, 'x'],
    };
    expect(FirestoreRest.decodeValue(FirestoreRest.encodeValue(value)), value);
  });
  test('stale local edit yields remote winner without a write', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      expect(request.method, 'GET');
      return http.Response(jsonEncode(document(record(20))), 200);
    });
    final remote = FirestoreRest(_TokenAuth(), 'shop', client: client);
    expect((await remote.push(record(10))).updatedAt, 20);
    expect(requests, 1);
    remote.close();
  });
  test(
    'atomic precondition race retries and observes the newer winner',
    () async {
      var reads = 0, writes = 0;
      final client = MockClient((request) async {
        if (request.method == 'GET') {
          reads++;
          return http.Response(
            jsonEncode(document(record(reads == 1 ? 10 : 30))),
            200,
          );
        }
        writes++;
        final body = jsonDecode(request.body) as Json;
        expect(body['writes'][0]['currentDocument']['updateTime'], isNotNull);
        expect(
          body['writes'][0]['updateTransforms'][0]['setToServerValue'],
          'REQUEST_TIME',
        );
        return http.Response('{}', 409);
      });
      final remote = FirestoreRest(_TokenAuth(), 'shop', client: client);
      expect((await remote.push(record(20))).updatedAt, 30);
      expect(reads, 2);
      expect(writes, 1);
      remote.close();
    },
  );
  test(
    'new record uses exists=false and a server timestamp transform',
    () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-id-token');
        if (request.method == 'GET') return http.Response('{}', 404);
        final body = jsonDecode(request.body) as Json;
        expect(body['writes'][0]['currentDocument'], {'exists': false});
        expect(
          body['writes'][0]['updateTransforms'][0]['fieldPath'],
          'committedAt',
        );
        return http.Response('{}', 200);
      });
      final remote = FirestoreRest(_TokenAuth(), 'shop', client: client);
      expect((await remote.push(record(20))).updatedAt, 20);
      remote.close();
    },
  );
  test('incremental pull filters on an inclusive server timestamp', () async {
    const since = '2026-10-29T09:00:00.000000Z';
    final client = MockClient((request) async {
      final query = (jsonDecode(request.body) as Json)['structuredQuery'];
      expect(query['where']['fieldFilter']['op'], 'GREATER_THAN_OR_EQUAL');
      expect(query['where']['fieldFilter']['value']['timestampValue'], since);
      return http.Response(
        jsonEncode([
          {'document': document(record(20))},
        ]),
        200,
      );
    });
    final remote = FirestoreRest(_TokenAuth(), 'shop', client: client),
        result = await remote.pull(since: since);
    expect(result.records.single.updatedAt, 20);
    expect(result.cursor, '2026-10-29T10:00:00.123456Z');
    remote.close();
  });
  test('pagination carries both timestamp and document-name cursor', () async {
    var page = 0;
    final client = MockClient((request) async {
      final query = (jsonDecode(request.body) as Json)['structuredQuery'];
      if (page++ == 0) {
        return http.Response(
          jsonEncode(
            List.generate(
              300,
              (i) => {'document': document(record(i, id: 'id-$i'))},
            ),
          ),
          200,
        );
      }
      expect(query['startAt']['before'], false);
      expect(query['startAt']['values'].length, 2);
      expect(
        query['startAt']['values'][1]['referenceValue'],
        endsWith('people_id-299'),
      );
      return http.Response(
        jsonEncode([
          {'document': document(record(301, id: 'last'))},
        ]),
        200,
      );
    });
    final remote = FirestoreRest(_TokenAuth(), 'shop', client: client);
    expect((await remote.pull()).records.length, 301);
    expect(page, 2);
    remote.close();
  });
}
