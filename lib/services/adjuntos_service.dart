import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import '../models/politica_model.dart';
import 'auth_service.dart';

class AdjuntosService extends GetxService {
  final AuthService authService = Get.find<AuthService>();
  final String _baseUrl = Environment.apiUrl;

  final RxBool isLoading = false.obs;

  /// Documentos requeridos agrupados por actividad para una política
  Future<List<ActividadDocumentos>> obtenerDocumentosRequeridos(String politicaId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/politicas/$politicaId/documentos-requeridos'),
      headers: authService.getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => ActividadDocumentos.fromJson(e)).toList();
    }
    throw Exception('Error al obtener documentos requeridos: ${response.statusCode}');
  }

  /// Sube la imagen de un documento para una actividad del trámite
  Future<Map<String, dynamic>> subirAdjunto({
    required String tramiteId,
    required String actividadId,
    required String documentoNombre,
    required File archivo,
  }) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse(
        '$_baseUrl/tramites/$tramiteId/adjuntos'
        '?actividadId=$actividadId'
        '&documentoNombre=${Uri.encodeComponent(documentoNombre)}',
      );

      final request = http.MultipartRequest('POST', uri);
      final token = authService.getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 201) {
        return json.decode(body) as Map<String, dynamic>;
      }
      throw Exception('Error al subir adjunto: ${streamed.statusCode}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Lista adjuntos de un trámite, opcionalmente filtrados por actividad
  Future<List<Map<String, dynamic>>> listarAdjuntos(
    String tramiteId, {
    String? actividadId,
  }) async {
    final query = actividadId != null ? '?actividadId=$actividadId' : '';
    final response = await http.get(
      Uri.parse('$_baseUrl/tramites/$tramiteId/adjuntos$query'),
      headers: authService.getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Error al obtener adjuntos: ${response.statusCode}');
  }
}
