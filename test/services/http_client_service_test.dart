// Tests del cliente HTTP genérico (HttpClientService).
//  - GET / POST / PUT / DELETE → propaga método y URL, incluye Authorization.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/http_client_service.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(registerCommonMocks);

  test('GET — propaga URL y header Authorization', () async {
    final client = HttpClientService();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      final r = await client.get('http://x.test/api/foo');
      expect(r.statusCode, 200);
    }, handler: (req) {
      captured = req;
      return http.Response('{}', 200, headers: {'content-type': 'application/json'});
    });

    expect(captured!.method, 'GET');
    expect(captured!.url.path, '/api/foo');
    expect(captured!.headers['Authorization'], startsWith('Bearer '));
  });

  test('POST — envía body', () async {
    final client = HttpClientService();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      await client.post('http://x.test/api/bar', body: '{"a":1}');
    }, handler: (req) {
      captured = req;
      return http.Response('{}', 200);
    });

    expect(captured!.method, 'POST');
    expect((captured as http.Request).body, '{"a":1}');
  });

  test('PUT — propaga método', () async {
    final client = HttpClientService();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      await client.put('http://x.test/api/baz', body: '{}');
    }, handler: (req) {
      captured = req;
      return http.Response('{}', 200);
    });

    expect(captured!.method, 'PUT');
  });

  test('DELETE — propaga método', () async {
    final client = HttpClientService();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      await client.delete('http://x.test/api/qux');
    }, handler: (req) {
      captured = req;
      return http.Response('{}', 200);
    });

    expect(captured!.method, 'DELETE');
  });
}
