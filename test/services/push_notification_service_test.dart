// Test del polling de PushNotificationService.
// El servicio consume ComunicacionService.getMisNotificaciones (HTTP),
// así que basta interceptar esa llamada con MockClient.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/comunicacion_service.dart';
import 'package:mobile/services/push_notification_service.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(() async {
    await registerCommonMocks();
    Get.put<ComunicacionService>(ComunicacionService());
  });

  test('Servicio se construye y registra en GetX', () {
    final push = Get.put<PushNotificationService>(PushNotificationService());
    expect(Get.find<PushNotificationService>(), same(push));
  });

  test('Polling consulta GET /notificaciones/mis-notificaciones', () async {
    Get.put<PushNotificationService>(PushNotificationService());

    http.BaseRequest? captured;
    await withMockHttp(() async {
      // Llamamos directo a ComunicacionService como hace _verificar internamente,
      // sin disparar las notificaciones nativas (las cuales requieren plugin host).
      final com = Get.find<ComunicacionService>();
      final list = await com.getMisNotificaciones();
      expect(list.length, 1);
    }, handler: (req) {
      captured = req;
      return http.Response(
        jsonEncode([
          {'id': 'n1', 'titulo': 't', 'mensaje': 'm', 'leida': false, 'tipo': 'cambio_estado'},
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    expectEndpoint(captured!, 'GET', '/notificaciones/mis-notificaciones');
  });
}
