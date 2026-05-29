// Tests por endpoint de TramitesService.
//  - GET /politicas (+ ?estado=)
//  - GET /politicas/:id
//  - GET /actividades
//  - GET /actividades/:id
//  - GET /departamentos
//  - GET /departamentos/:id

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/tramites_service.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(registerCommonMocks);

  TramitesService nuevo() {
    final svc = TramitesService();
    Get.put<TramitesService>(svc);
    return svc;
  }

  http.Response okJson(dynamic data) =>
      http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});

  test('GET /politicas — obtenerPoliticas (sin filtro)', () async {
    final svc = nuevo();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      final out = await svc.obtenerPoliticas();
      expect(out.length, 1);
    }, handler: (req) {
      captured = req;
      return okJson([
        {
          'id': 'p1',
          'nombre': 'P',
          'descripcion': 'd',
          'estado': 'activa',
          'duracionDiasLimite': 0,
          'requiereAprobacion': false,
          'activo': true,
          'fechaCreacion': '',
        }
      ]);
    });

    expectEndpoint(captured!, 'GET', '/politicas');
  });

  test('GET /politicas?estado=activa — obtenerPoliticas con estado', () async {
    final svc = nuevo();
    Uri? capturedUrl;

    await withMockHttp(() async {
      await svc.obtenerPoliticas(estado: 'activa');
    }, handler: (req) {
      capturedUrl = req.url;
      return okJson([]);
    });

    expect(capturedUrl!.query.contains('estado=activa'), isTrue);
  });

  test('GET /politicas/:id — obtenerPoliticaPorId', () async {
    final svc = nuevo();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      final p = await svc.obtenerPoliticaPorId('p1');
      expect(p.id, 'p1');
    }, handler: (req) {
      captured = req;
      return okJson({
        'id': 'p1',
        'nombre': 'P',
        'descripcion': 'd',
        'estado': 'activa',
        'duracionDiasLimite': 0,
        'requiereAprobacion': false,
        'activo': true,
        'fechaCreacion': '',
      });
    });

    expectEndpoint(captured!, 'GET', '/politicas/p1');
  });

  test('GET /actividades — obtenerActividades', () async {
    final svc = nuevo();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      await svc.obtenerActividades();
    }, handler: (req) {
      captured = req;
      return okJson([]);
    });

    expectEndpoint(captured!, 'GET', '/actividades');
  });

  test('GET /actividades/:id — obtenerActividadPorId', () async {
    final svc = nuevo();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      try {
        await svc.obtenerActividadPorId('a1');
      } catch (_) {}
    }, handler: (req) {
      captured = req;
      return okJson({});
    });

    expectEndpoint(captured!, 'GET', '/actividades/a1');
  });

  test('GET /departamentos — obtenerDepartamentos', () async {
    final svc = nuevo();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      await svc.obtenerDepartamentos();
    }, handler: (req) {
      captured = req;
      return okJson([]);
    });

    expectEndpoint(captured!, 'GET', '/departamentos');
  });

  test('GET /departamentos/:id — obtenerDepartamentoPorId', () async {
    final svc = nuevo();
    http.BaseRequest? captured;

    await withMockHttp(() async {
      try {
        await svc.obtenerDepartamentoPorId('d1');
      } catch (_) {}
    }, handler: (req) {
      captured = req;
      return okJson({});
    });

    expectEndpoint(captured!, 'GET', '/departamentos/d1');
  });
}
