// CU-40 (sugerir política) + CU-39 (dictar formulario) + CU-42 (ruta óptima)
// + CU-43 (riesgo de demora) — proxy al microservicio IA vía backend Spring.
//
// Si el microservicio IA está caído, el backend responde 503 con código
// `IA_NO_DISPONIBLE`; el caller debe degradar limpiamente.

import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../config/environment.dart';
import '../models/sugerencia_politica_model.dart';
import '../models/tramite_riesgo_model.dart';
import 'auth_service.dart';

class IaException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  IaException(this.statusCode, this.code, this.message);
  @override
  String toString() => 'IaException($statusCode, $code): $message';
}

class IaService extends GetxService {
  final AuthService _auth = Get.find<AuthService>();
  final String _base = Environment.apiUrl;

  final RxBool cargando = false.obs;

  // ── CU-40 · Sugerir política ───────────────────────────────────────────

  Future<SugerenciaPolitica> sugerirPolitica({
    required String descripcion,
    File? audio,
  }) async {
    cargando.value = true;
    try {
      final body = <String, dynamic>{'descripcion': descripcion};
      if (audio != null) {
        final bytes = await audio.readAsBytes();
        body['audioBase64'] = base64Encode(bytes);
      }
      final resp = await http
          .post(
            Uri.parse('$_base/tramites/sugerir-politica'),
            headers: _auth.getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        return SugerenciaPolitica.fromJson(
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>,
        );
      }
      throw _toIaException(resp);
    } finally {
      cargando.value = false;
    }
  }

  Future<void> confirmarSugerencia({
    required String sugerenciaId,
    required String politicaConfirmadaId,
  }) async {
    final resp = await http
        .post(
          Uri.parse('$_base/sugerencias/$sugerenciaId/confirmar'),
          headers: _auth.getHeaders(),
          body: jsonEncode({'politicaConfirmadaId': politicaConfirmadaId}),
        )
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw _toIaException(resp);
    }
  }

  Future<void> cancelarSugerencia(String sugerenciaId) async {
    final resp = await http
        .post(
          Uri.parse('$_base/sugerencias/$sugerenciaId/cancelar'),
          headers: _auth.getHeaders(),
        )
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw _toIaException(resp);
    }
  }

  // ── CU-39 · Dictar formulario ──────────────────────────────────────────

  Future<Map<String, dynamic>> dictarSeccion({
    required String seccionId,
    required File audio,
  }) async {
    final uri = Uri.parse('$_base/expedientes/secciones/$seccionId/dictar');
    final req = http.MultipartRequest('POST', uri);
    final token = _auth.getToken();
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.files.add(await http.MultipartFile.fromPath('audio', audio.path));

    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    throw IaException(
      streamed.statusCode,
      _extraerCode(body),
      'Dictado falló: ${streamed.statusCode}',
    );
  }

  // ── CU-42 · Ruta óptima ────────────────────────────────────────────────

  Future<RutaOptima> rutaOptima(String tramiteId) async {
    final resp = await http
        .post(
          Uri.parse('$_base/tramites/$tramiteId/ruta-optima'),
          headers: _auth.getHeaders(),
        )
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode == 200) {
      return RutaOptima.fromJson(
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw _toIaException(resp);
  }

  // ── CU-43 · Riesgo de demora ───────────────────────────────────────────

  Future<List<TramiteRiesgo>> enRiesgo({String? nivel}) async {
    final q = nivel != null ? '?nivel=$nivel' : '';
    final resp = await http
        .get(
          Uri.parse('$_base/tramites/en-riesgo$q'),
          headers: _auth.getHeaders(),
        )
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode == 200) {
      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as List<dynamic>;
      return data
          .map((e) => TramiteRiesgo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _toIaException(resp);
  }

  // ── helpers ────────────────────────────────────────────────────────────

  IaException _toIaException(http.Response resp) {
    final code = _extraerCode(resp.body);
    return IaException(resp.statusCode, code, resp.body);
  }

  String _extraerCode(String body) {
    try {
      final j = jsonDecode(body) as Map<String, dynamic>;
      final c = (j['code'] ?? j['error'] ?? '').toString();
      return c.isNotEmpty ? c : 'UNKNOWN';
    } catch (_) {
      return 'UNKNOWN';
    }
  }
}
