// Tests del StorageService (sin red, sólo SharedPreferences).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
  });

  test('saveToken / getToken / hasToken', () async {
    expect(storage.getToken(), isNull);
    expect(storage.hasToken(), isFalse);
    await storage.saveToken('XYZ');
    expect(storage.getToken(), 'XYZ');
    expect(storage.hasToken(), isTrue);
  });

  test('saveUserData / getUserData', () async {
    await storage.saveUserData('{"id":"u1"}');
    expect(storage.getUserData(), '{"id":"u1"}');
  });

  test('clear elimina todo', () async {
    await storage.saveToken('T');
    await storage.clear();
    expect(storage.getToken(), isNull);
    expect(storage.hasToken(), isFalse);
  });
}
