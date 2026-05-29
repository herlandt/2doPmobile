// Tests por endpoint de AuthService.
//  - POST /auth/login
//  - POST /auth/register-cliente
//  - GET  /usuarios/me

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/models/auth_model.dart';
import 'package:mobile/services/auth_service.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(registerCommonMocks);

  test('POST /auth/login — guarda token tras éxito', () async {
    final svc = Get.find<AuthService>();

    http.BaseRequest? captured;
    await withMockHttp(() async {
      final res = await svc.login(LoginRequest(email: 'a@x.com', password: 'p'));
      expect(res.token, 'TKN-OK');
    }, handler: (req) {
      captured = req;
      return http.Response(
        jsonEncode({
          'token': 'TKN-OK',
          'tipoToken': 'Bearer',
          'email': 'a@x.com',
          'nombre': 'A',
          'tipo': 'cliente',
          'usuario': {
            'id': 'u1',
            'email': 'a@x.com',
            'nombre': 'A',
            'rol': 'Cliente',
            'activo': true,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    expectEndpoint(captured!, 'POST', '/auth/login');
    expect(svc.getToken(), 'TKN-OK');
  });

  test('POST /auth/register-cliente — registrar', () async {
    final svc = Get.find<AuthService>();

    http.BaseRequest? captured;
    await withMockHttp(() async {
      await svc.registrar(RegisterRequest(
        email: 'b@x.com',
        password: 'pass',
        passwordConfirm: 'pass',
        nombre: 'B',
      ));
    }, handler: (req) {
      captured = req;
      return http.Response(
        jsonEncode({'message': 'OK', 'usuarioId': 'u9'}),
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    expectEndpoint(captured!, 'POST', '/auth/register-cliente');
  });

  test('GET /usuarios/me — obtenerDatosUsuario', () async {
    final svc = Get.find<AuthService>();

    http.BaseRequest? captured;
    await withMockHttp(() async {
      final u = await svc.obtenerDatosUsuario();
      expect(u, isNotNull);
    }, handler: (req) {
      captured = req;
      return http.Response(
        jsonEncode({'id': 'u1', 'email': 'a@x.com', 'nombre': 'A', 'rol': 'Cliente', 'activo': true}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    expectEndpoint(captured!, 'GET', '/usuarios/me');
  });
}
