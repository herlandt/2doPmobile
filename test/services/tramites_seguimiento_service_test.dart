// Tests por endpoint de TramitesSeguimientoService.
//  - GET  /tramites/mis-tramites
//  - GET  /tramites/:id/estado
//  - GET  /expedientes/tramite/:id
//  - POST /expedientes/seccion/:id/completar  (vía enviarCorreccion)
//  - GET  /tramites/:id/linea-tiempo
//  - POST /tramites/:id/cancelar

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/tramites_seguimiento_service.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(registerCommonMocks);

  TramitesSeguimientoService nuevo() {
    return Get.put<TramitesSeguimientoService>(TramitesSeguimientoService());
  }

  http.Response jsonResponse(dynamic data, [int status = 200]) =>
      http.Response(jsonEncode(data), status, headers: {'content-type': 'application/json'});

  test('GET /tramites/mis-tramites — obtenerMisTramites', () async {
    final svc = nuevo();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      try {
        await svc.obtenerMisTramites();
      } catch (_) {}
    }, handler: (req) {
      captured = req;
      return jsonResponse([]);
    });

    expectEndpoint(captured!, 'GET', '/tramites/mis-tramites');
  });

  test('GET /tramites/:id/estado — obtenerEstadoTramite', () async {
    final svc = nuevo();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      try {
        await svc.obtenerEstadoTramite('t1');
      } catch (_) {}
    }, handler: (req) {
      captured = req;
      return jsonResponse({});
    });

    expectEndpoint(captured!, 'GET', '/tramites/t1/estado');
  });

  test('GET /expedientes/tramite/:id — getExpediente', () async {
    final svc = nuevo();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      final exp = await svc.getExpediente('t1');
      expect(exp['secciones'], isA<List>());
    }, handler: (req) {
      captured = req;
      return jsonResponse({'secciones': []});
    });

    expectEndpoint(captured!, 'GET', '/expedientes/tramite/t1');
  });

  test('POST /expedientes/seccion/:id/completar — enviarCorreccion', () async {
    final svc = nuevo();
    final List<http.BaseRequest> capturados = [];

    await withMockHttp(() async {
      await svc.enviarCorreccion('t1', 'reviso');
    }, handler: (req) {
      capturados.add(req);
      if (req.method == 'GET') {
        return jsonResponse({
          'secciones': [
            {
              'infoSeccion': {'id': 's1', 'estado': 'en_curso'},
            }
          ],
        });
      }
      return jsonResponse({'ok': true});
    });

    expect(capturados.length, 2);
    expect(capturados.first.method, 'GET');
    expect(capturados.last.method, 'POST');
    expect(capturados.last.url.path.endsWith('/expedientes/seccion/s1/completar'), isTrue);
  });

  test('GET /tramites/:id/linea-tiempo — getLineaTiempoTramite (CU-21)', () async {
    final svc = nuevo();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      await svc.getLineaTiempoTramite('t1');
    }, handler: (req) {
      captured = req;
      return jsonResponse({'tramiteId': 't1', 'hitos': []});
    });

    expectEndpoint(captured!, 'GET', '/tramites/t1/linea-tiempo');
  });

  test('POST /tramites/:id/cancelar — cancelarTramite (CU-19)', () async {
    final svc = nuevo();
    http.BaseRequest? captured;
    Map<String, dynamic>? body;

    await withMockHttp(() async {
      await svc.cancelarTramite('t1', 'cambio de planes');
    }, handler: (req) {
      captured = req;
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return jsonResponse({'ok': true});
    });

    expectEndpoint(captured!, 'POST', '/tramites/t1/cancelar');
    expect(body!['motivo'], 'cambio de planes');
  });
}
