// Tests por endpoint de TramitesEnvioService.
//  - POST /workflow/iniciar
//  - POST /tramites/iniciar  (C2)

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/tramites_envio_service.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(registerCommonMocks);

  TramitesEnvioService nuevo() {
    return Get.put<TramitesEnvioService>(TramitesEnvioService());
  }

  test('POST /workflow/iniciar — enviarTramite', () async {
    final svc = nuevo();
    http.BaseRequest? captured;
    Map<String, dynamic>? body;

    await withMockHttp(() async {
      try {
        await svc.enviarTramite(politicaId: 'p1', clienteId: 'c1');
      } catch (_) {}
    }, handler: (req) {
      captured = req;
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({'tramiteId': 't1', 'codigo': 'TR-1', 'mensaje': 'ok'}),
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    // enviarTramite ahora apunta al mismo endpoint que iniciarTramiteC2
    // (/workflow/iniciar nunca existió en el backend; era un bug).
    expectEndpoint(captured!, 'POST', '/tramites/iniciar');
    expect(body!['politicaId'], 'p1');
    expect(body!['clienteId'], 'c1');
  });

  test('POST /tramites/iniciar — iniciarTramiteC2 (CU-07)', () async {
    final svc = nuevo();
    http.BaseRequest? captured;
    Map<String, dynamic>? body;

    await withMockHttp(() async {
      final out = await svc.iniciarTramiteC2('p1', 'c1');
      expect(out['id'], 't9');
    }, handler: (req) {
      captured = req;
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({'id': 't9', 'codigo': 'TR-9'}),
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    expectEndpoint(captured!, 'POST', '/tramites/iniciar');
    expect(body!['politicaId'], 'p1');
    expect(body!['clienteId'], 'c1');
  });
}
