// Tests por endpoint de ComunicacionService.
//  - GET  /notificaciones/mis-notificaciones  (CU-28)
//  - POST /agente/consultar                   (CU-31)

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/comunicacion_service.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(registerCommonMocks);

  test('GET /notificaciones/mis-notificaciones — getMisNotificaciones', () async {
    final svc = Get.put<ComunicacionService>(ComunicacionService());

    http.BaseRequest? captured;
    await withMockHttp(() async {
      final lista = await svc.getMisNotificaciones();
      expect(lista.length, 2);
    }, handler: (req) {
      captured = req;
      return http.Response(
        jsonEncode([
          {'id': '1', 'titulo': 'a', 'mensaje': 'b', 'leida': false},
          {'id': '2', 'titulo': 'c', 'mensaje': 'd', 'leida': true},
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    expectEndpoint(captured!, 'GET', '/notificaciones/mis-notificaciones');
  });

  test('POST /agente/consultar — consultarAgenteIA con acción', () async {
    final svc = Get.put<ComunicacionService>(ComunicacionService());

    http.BaseRequest? captured;
    Map<String, dynamic>? sentBody;
    await withMockHttp(() async {
      final res = await svc.consultarAgenteIA('hola', 'pantalla X',
          tramiteIdOpcional: 't1');
      expect(res['respuesta'], 'OK');
      expect(res['accion']['label'], 'Ir');
    }, handler: (req) {
      captured = req;
      sentBody = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'respuesta': 'OK',
          'accion': {'label': 'Ir', 'ruta': '/x', 'tipo': 'navegar'}
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    expectEndpoint(captured!, 'POST', '/agente/consultar');
    expect(sentBody!['consulta'], 'hola');
    expect(sentBody!['moduloActivo'], 'pantalla X');
    expect(sentBody!['tramiteIdOpcional'], 't1');
  });
}
