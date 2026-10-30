import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/auth/data/auth_repository.dart';
import '../../firebase_options.dart';
import '../domain/models.dart';

class RemoteChanges {
  const RemoteChanges(this.records, this.cursor);
  final List<RecordEnvelope> records;
  final String? cursor;
}

/// Uses Firebase's supported REST interfaces on Windows as well as other
/// platforms. Version preconditions make each LWW comparison atomic.
class FirestoreRest {
  FirestoreRest(this.auth, this.shopId, {http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  void close() => _client.close();
  final AuthRepository auth;
  final String shopId;
  String get root =>
      'projects/${DefaultFirebaseOptions.projectId}/databases/(default)/documents';
  String get path => '$root/shops/$shopId/records';
  Future<Map<String, String>> get _headers async => {
    'Authorization': 'Bearer ${await auth.token()}',
    'Content-Type': 'application/json',
  };
  Future<Json?> _get(String resource) async {
    final result = await _client
        .get(
          Uri.parse('https://firestore.googleapis.com/v1/$resource'),
          headers: await _headers,
        )
        .timeout(const Duration(seconds: 20));
    if (result.statusCode == 404) return null;
    if (result.statusCode != 200) {
      throw ApiFailure('syncFailed', result.statusCode);
    }
    return jsonDecode(result.body) as Json;
  }

  static Json encodeValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is num) return {'doubleValue': value};
    if (value is String) return {'stringValue': value};
    if (value is Map) {
      return {
        'mapValue': {
          'fields': value.map((k, v) => MapEntry(k.toString(), encodeValue(v))),
        },
      };
    }
    if (value is List) {
      return {
        'arrayValue': {'values': value.map(encodeValue).toList()},
      };
    }
    throw const DomainFailure('invalidBackup');
  }

  static dynamic decodeValue(Json value) {
    if (value.containsKey('integerValue')) {
      return int.parse(value['integerValue'].toString());
    }
    if (value.containsKey('doubleValue')) {
      return (value['doubleValue'] as num).toDouble();
    }
    if (value.containsKey('stringValue')) return value['stringValue'];
    if (value.containsKey('booleanValue')) return value['booleanValue'];
    if (value.containsKey('mapValue')) {
      return ((value['mapValue']['fields'] ?? <String, dynamic>{}) as Map).map(
        (k, v) =>
            MapEntry(k.toString(), decodeValue(Map<String, dynamic>.from(v))),
      );
    }
    if (value.containsKey('arrayValue')) {
      return ((value['arrayValue']['values'] ?? []) as List)
          .map((v) => decodeValue(Map<String, dynamic>.from(v)))
          .toList();
    }
    return null;
  }

  static RecordEnvelope decodeDocument(Json document) =>
      RecordEnvelope.fromJson(
        (document['fields'] as Map).map(
          (k, v) =>
              MapEntry(k.toString(), decodeValue(Map<String, dynamic>.from(v))),
        ),
      );
  Future<RemoteChanges> pull({String? since}) async {
    final records = <RecordEnvelope>[];
    Json? last;
    String? cursor = since;
    do {
      final query = <String, dynamic>{
        'from': [
          {'collectionId': 'records'},
        ],
        if (since != null)
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'committedAt'},
              'op': 'GREATER_THAN_OR_EQUAL',
              'value': {'timestampValue': since},
            },
          },
        'orderBy': [
          {
            'field': {'fieldPath': 'committedAt'},
            'direction': 'ASCENDING',
          },
          {
            'field': {'fieldPath': '__name__'},
            'direction': 'ASCENDING',
          },
        ],
        'limit': 300,
        if (last != null)
          'startAt': {
            'before': false,
            'values': [
              last['fields']['committedAt'],
              {'referenceValue': last['name']},
            ],
          },
      };
      final response = await _client
          .post(
            Uri.parse(
              'https://firestore.googleapis.com/v1/$root/shops/$shopId:runQuery',
            ),
            headers: await _headers,
            body: jsonEncode({'structuredQuery': query}),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw ApiFailure('syncFailed', response.statusCode);
      }
      final result = jsonDecode(response.body) as List;
      final documents = result
          .where((r) => r['document'] != null)
          .map((r) => Map<String, dynamic>.from(r['document']))
          .toList();
      for (final document in documents) {
        records.add(decodeDocument(document));
        final time =
            document['fields']['committedAt']['timestampValue'] as String;
        if (cursor == null ||
            DateTime.parse(time).isAfter(DateTime.parse(cursor))) {
          cursor = time;
        }
      }
      if (documents.length < 300) break;
      last = documents.last;
    } while (true);
    return RemoteChanges(records, cursor);
  }

  /// Returns the winning document. A concurrent edit retries the comparison,
  /// never blindly overwriting the other device's newly committed version.
  Future<RecordEnvelope> push(RecordEnvelope local) async {
    final resource = '$path/${local.entity}_${local.id}';
    for (var attempt = 0; attempt < 4; attempt++) {
      final remote = await _get(resource);
      if (remote != null) {
        final winner = decodeDocument(remote);
        if (!local.newerThan(winner)) return winner;
      }
      final response = await _client
          .post(
            Uri.parse('https://firestore.googleapis.com/v1/$root:commit'),
            headers: await _headers,
            body: jsonEncode({
              'writes': [
                {
                  'update': {
                    'name': resource,
                    'fields': local.toJson().map(
                      (k, v) => MapEntry(k, encodeValue(v)),
                    ),
                  },
                  'currentDocument': remote == null
                      ? {'exists': false}
                      : {'updateTime': remote['updateTime']},
                  'updateTransforms': [
                    {
                      'fieldPath': 'committedAt',
                      'setToServerValue': 'REQUEST_TIME',
                    },
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) return local;
      if (response.statusCode != 409 && response.statusCode != 400) {
        throw ApiFailure('syncFailed', response.statusCode);
      }
    }
    throw const ApiFailure('syncConflict', 409);
  }
}
