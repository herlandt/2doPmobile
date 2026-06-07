// Tests por endpoint de AdjuntosService.
//  - GET /politicas/:id/documentos-requeridos
//  - GET /tramites/:id/documentos (+ ?actividadId=)
// (POST multipart de subirAdjunto requiere File real → omitido, validado
//  por análisis estático del servicio.)

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/adjuntos_service.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(registerCommonMocks);

  AdjuntosService nuevo() {
    final svc = AdjuntosService();
    Get.put<AdjuntosService>(svc);
    return svc;
  }

  test('GET /politicas/:id/documentos-requeridos — obtenerDocumentosRequeridos', () async {
    final svc = nuevo();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      final docs = await svc.obtenerDocumentosRequeridos('p1');
      expect(docs.length, 1);
    }, handler: (req) {
      captured = req;
      return http.Response(
        jsonEncode([
          {
            'actividadId': 'a1',
            'actividadNombre': 'Verificar',
            'documentosRequeridos': ['CI', 'Foto'],
          }
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    expectEndpoint(captured!, 'GET', '/politicas/p1/documentos-requeridos');
  });

  test('GET /tramites/:id/documentos — listarAdjuntos (sin filtro)', () async {
    final svc = nuevo();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      await svc.listarAdjuntos('t1');
    }, handler: (req) {
      captured = req;
      return http.Response('[]', 200, headers: {'content-type': 'application/json'});
    });

    expectEndpoint(captured!, 'GET', '/tramites/t1/documentos');
  });

  test('GET /tramites/:id/documentos?actividadId=… — listarAdjuntos (con filtro)', () async {
    final svc = nuevo();
    Uri? capturedUrl;

    await withMockHttp(() async {
      await svc.listarAdjuntos('t1', actividadId: 'a1');
    }, handler: (req) {
      capturedUrl = req.url;
      return http.Response('[]', 200, headers: {'content-type': 'application/json'});
    });

    expect(capturedUrl!.query.contains('actividadId=a1'), isTrue);
  });
}
