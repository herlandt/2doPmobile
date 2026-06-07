import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import '../models/politica_model.dart';
import 'auth_service.dart';

/// Error de subida con un mensaje claro para mostrar al usuario.
/// `toString()` devuelve directamente ese mensaje (sin prefijo "Exception:"),
/// así la cola offline también guarda un texto legible.
class SubidaException implements Exception {
  final int statusCode;
  final String mensaje;
  final String detalleBackend;
  const SubidaException(this.statusCode, this.mensaje, this.detalleBackend);
  @override
  String toString() => mensaje;
}

/// Traduce el (statusCode, cuerpo) del backend a un mensaje claro en español.
/// Códigos reales del GlobalExceptionHandler: 400 IllegalArgument (incl.
/// DOC_HASH_DUPLICADO), 403 AccessDenied, 404 trámite, 500 IllegalState/S3,
/// 503 almacenamiento. El mensaje del backend viaja en el campo JSON `error`.
SubidaException mapearErrorSubida(int code, String body) {
  final detalle = _extraerMensajeBackend(body);
  String m;
  switch (code) {
    case 403:
      m = 'No tienes permiso para subir documentos en esta actividad.';
      break;
    case 404:
      m = 'El trámite no existe o ya no está disponible.';
      break;
    case 400:
      final d = detalle.toUpperCase();
      if (d.contains('DUPLICAD') || d.contains('HASH')) {
        m = 'Este documento ya fue subido antes (contenido idéntico).';
      } else {
        m = detalle.isNotEmpty ? detalle : 'No se pudo subir: datos inválidos.';
      }
      break;
    case 413:
      m = 'El archivo es demasiado grande. Usa una imagen más liviana.';
      break;
    case 503:
      m = 'Almacenamiento no disponible. Intenta de nuevo en unos minutos.';
      break;
    case 500:
      m = body.contains('S3')
          ? 'El almacenamiento de archivos no está disponible ahora mismo.'
          : 'Ocurrió un error en el servidor al subir el documento.';
      break;
    default:
      m = 'No se pudo subir el documento (código $code).';
  }
  return SubidaException(code, m, detalle);
}

/// Extrae el mensaje del cuerpo de error del backend (campo `error`/`message`).
String _extraerMensajeBackend(String body) {
  try {
    final j = json.decode(body);
    if (j is Map<String, dynamic>) {
      final v = j['error'] ?? j['message'] ?? j['mensaje'] ?? '';
      return v.toString();
    }
  } catch (_) {}
  return '';
}

class AdjuntosService extends GetxService {
  final AuthService authService = Get.find<AuthService>();
  final String _baseUrl = Environment.apiUrl;

  final RxBool isLoading = false.obs;

  /// Documentos requeridos agrupados por actividad para una política
  Future<List<ActividadDocumentos>> obtenerDocumentosRequeridos(String politicaId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/politicas/$politicaId/documentos-requeridos'),
      headers: authService.getHeaders(),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((e) => ActividadDocumentos.fromJson(e)).toList();
    }
    if (response.statusCode == 401) {
      await authService.logout();
      Get.offNamed('/login');
    }
    throw Exception('Error al obtener documentos requeridos: ${response.statusCode}');
  }

  /// Documentos requeridos del PRIMER nodo de una política (un solo objeto).
  /// Se usa al INICIAR el trámite para que el cliente adjunte antes de crearlo.
  /// Devuelve null si el endpoint responde vacío/null o sin documentos
  /// (política sin requisitos iniciales del cliente -> iniciar directo).
  Future<ActividadDocumentos?> obtenerDocumentosIniciales(String politicaId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/politicas/$politicaId/documentos-iniciales'),
      headers: authService.getHeaders(),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes).trim();
      if (body.isEmpty || body == 'null') return null;
      final decoded = json.decode(body);
      if (decoded is! Map<String, dynamic> || decoded.isEmpty) return null;
      return ActividadDocumentos.fromJson(decoded);
    }
    if (response.statusCode == 204 || response.statusCode == 404) return null;
    if (response.statusCode == 401) {
      await authService.logout();
      Get.offNamed('/login');
    }
    throw Exception('Error al obtener documentos iniciales: ${response.statusCode}');
  }

  /// Sube la imagen de un documento para una actividad del trámite.
  /// CU-33 — repositorio documental por TRÁMITE (S3): el backend resuelve/crea
  /// el repositorio 1:1 del trámite a partir del {tramiteId}. El nombre del
  /// documento requerido se usa como nombreLogico y tipoDocumento.
  Future<Map<String, dynamic>> subirAdjunto({
    required String tramiteId,
    required String actividadId,
    required String documentoNombre,
    required File archivo,
    String? documentoRequeridoId,
    String? corrigeDocumentoId,
  }) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/tramites/$tramiteId/documentos');

      final request = http.MultipartRequest('POST', uri);
      final token = authService.getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields['actividadId'] = actividadId;
      request.fields['tipoDocumento'] = documentoNombre;
      request.fields['nombreLogico'] = documentoNombre;
      request.fields['obligatorio'] = 'false';
      // Compuerta de documentos: indica qué requisito del nodo cumple.
      if (documentoRequeridoId != null) {
        request.fields['documentoRequeridoId'] = documentoRequeridoId;
      }
      // Caso OBSERVADO: id del documento marcado "mal" que este corrige; el
      // backend lo retira de documentosObservados al recibirlo.
      if (corrigeDocumentoId != null) {
        request.fields['corrigeDocumentoId'] = corrigeDocumentoId;
      }
      request.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 201 || streamed.statusCode == 200) {
        return json.decode(body) as Map<String, dynamic>;
      }
      throw mapearErrorSubida(streamed.statusCode, body);
    } finally {
      isLoading.value = false;
    }
  }

  /// Lista los documentos de un trámite, opcionalmente filtrados por actividad
  Future<List<Map<String, dynamic>>> listarAdjuntos(
    String tramiteId, {
    String? actividadId,
  }) async {
    final query = actividadId != null ? '?actividadId=$actividadId' : '';
    final response = await http.get(
      Uri.parse('$_baseUrl/tramites/$tramiteId/documentos$query'),
      headers: authService.getHeaders(),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.cast<Map<String, dynamic>>();
    }
    if (response.statusCode == 401) {
      await authService.logout();
      Get.offNamed('/login');
    }
    throw Exception('Error al obtener adjuntos: ${response.statusCode}');
  }
}
