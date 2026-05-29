// Helpers compartidos por los tests de los servicios HTTP.
// Cada test usa http.runWithClient para interceptar las llamadas reales sin
// tocar la red. SharedPreferences se inicializa en memoria.

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/storage_service.dart';

/// Inicializa GetX con AuthService y StorageService reales pero con
/// SharedPreferences en memoria y un token fijo para tests.
Future<void> registerCommonMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({
    'auth_token': 'fake-token',
  });
  Get.reset();
  final storage = StorageService();
  await storage.init();
  await storage.saveToken('fake-token');
  Get.put<StorageService>(storage);
  Get.put<AuthService>(AuthService(storageService: storage), permanent: true);
}

/// Helper que envuelve el cuerpo del test con un cliente HTTP simulado.
/// El handler recibe la request y debe devolver la response.
Future<void> withMockHttp(
  Future<void> Function() body, {
  required FutureOr<http.Response> Function(http.Request req) handler,
}) {
  final client = MockClient((req) async => await handler(req));
  return http.runWithClient(body, () => client);
}

/// Atajo para confirmar que una request fue al endpoint esperado.
void expectEndpoint(http.BaseRequest req, String method, String pathSuffix) {
  expect(req.method, method);
  expect(req.url.path.endsWith(pathSuffix), isTrue,
      reason: 'esperado ...$pathSuffix pero fue ${req.url.path}');
}
