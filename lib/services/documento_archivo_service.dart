// CU-32 / CU-33 / CU-34 / CU-35 — Cliente del repositorio documental.
//
// El cliente móvil consume:
//  - GET  /tramites/{id}/documentos                   → lista por trámite
//  - GET  /documentos/{id}/preview                    → URL S3 firmada
//  - GET  /documentos/{id}/versiones                  → historial
//  - POST /repositorios/{id}/documentos (multipart)   → subir nuevo
//  - POST /documentos/{id}/versiones    (multipart)   → nueva versión
//
// En errores devuelve [DocException] con el código del backend cuando es
// un error de dominio (`DOC_*`).

import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../config/environment.dart';
import '../models/documento_archivo_model.dart';
import '../models/version_documento_model.dart';
import 'auth_service.dart';

class DocException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  DocException(this.statusCode, this.code, this.message);
  @override
  String toString() => 'DocException($statusCode, $code): $message';
}

class DocumentoArchivoService extends GetxService {
  final AuthService _auth = Get.find<AuthService>();
  final String _base = Environment.apiUrl;

  Future<List<DocumentoArchivo>> listarPorTramite(
    String tramiteId, {
    String? actividadId,
  }) async {
    final q = actividadId != null ? '?actividadId=$actividadId' : '';
    final resp = await http
        .get(
          Uri.parse('$_base/tramites/$tramiteId/documentos$q'),
          headers: _auth.getHeaders(),
        )
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode == 200) {
      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as List<dynamic>;
      return data
          .map((e) => DocumentoArchivo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _toException(resp);
  }

  Future<PreviewDocumento> preview(String documentoId) async {
    final resp = await http
        .get(
          Uri.parse('$_base/documentos/$documentoId/preview'),
          headers: _auth.getHeaders(),
        )
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode == 200) {
      return PreviewDocumento.fromJson(
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw _toException(resp);
  }

  Future<List<VersionDocumento>> listarVersiones(String documentoId) async {
    final resp = await http
        .get(
          Uri.parse('$_base/documentos/$documentoId/versiones'),
          headers: _auth.getHeaders(),
        )
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode == 200) {
      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as List<dynamic>;
      return data
          .map((e) => VersionDocumento.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _toException(resp);
  }

  /// Subir documento nuevo al repositorio. Lanza [DocException] con
  /// `DOC_PERMISO_DENEGADO` si el funcionario no tiene escritura en
  /// la actividad (CU-36) o `DOC_HASH_DUPLICADO` si ya existe.
  Future<Map<String, dynamic>> subirNuevo({
    required String repositorioId,
    required String tramiteId,
    required String actividadId,
    String? nodoId,
    required String tipoDocumento,
    required String nombreLogico,
    bool obligatorio = false,
    required File archivo,
  }) async {
    final uri = Uri.parse('$_base/repositorios/$repositorioId/documentos');
    final req = http.MultipartRequest('POST', uri);
    final token = _auth.getToken();
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.fields['tramiteId'] = tramiteId;
    req.fields['actividadId'] = actividadId;
    if (nodoId != null) req.fields['nodoId'] = nodoId;
    req.fields['tipoDocumento'] = tipoDocumento;
    req.fields['nombreLogico'] = nombreLogico;
    req.fields['obligatorio'] = obligatorio.toString();
    req.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));

    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 201 || streamed.statusCode == 200) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    throw DocException(
      streamed.statusCode,
      _extraerCode(body),
      'Subida falló: ${streamed.statusCode}',
    );
  }

  Future<Map<String, dynamic>> crearNuevaVersion({
    required String documentoId,
    required File archivo,
    String? comentarioCambio,
  }) async {
    final uri = Uri.parse('$_base/documentos/$documentoId/versiones');
    final req = http.MultipartRequest('POST', uri);
    final token = _auth.getToken();
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (comentarioCambio != null) {
      req.fields['comentarioCambio'] = comentarioCambio;
    }
    req.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));

    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 201 || streamed.statusCode == 200) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    throw DocException(
      streamed.statusCode,
      _extraerCode(body),
      'Versión falló: ${streamed.statusCode}',
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────

  DocException _toException(http.Response resp) {
    return DocException(
      resp.statusCode,
      _extraerCode(resp.body),
      resp.body,
    );
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
