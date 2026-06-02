// Guía 3F - Servicio de Envío de Trámites

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import '../models/formulario_model.dart';
import 'auth_service.dart';

class TramitesEnvioService extends GetxService {
  late AuthService authService;

  final String _baseUrl = '${Environment.apiUrl}';

  void _log(String m) {
    if (kDebugMode) print(m);
  }

  @override
  void onInit() {
    super.onInit();
    authService = Get.find<AuthService>();
    _log('🔧 TramitesEnvioService inicializado');
  }

  /// Obtener plantilla del formulario para una política
  /// En C1: Retorna una plantilla básica hardcodeada
  /// En C2: Vendría del backend
  Future<FormularioPlantilla> obtenerFormularioPlantilla(String politicaId) async {
    _log('📝 Obteniendo plantilla de formulario para política: $politicaId');

    try {
      // En C1, usamos una plantilla básica
      // En C2 se podría cargar del backend
      final plantilla = FormularioPlantilla.crearPlantillaBasica(politicaId);
      _log('✅ Plantilla cargada exitosamente');
      return plantilla;

      // TODO C2: Descomentar cuando el backend tenga GET /api/formularios/:politicaId
      /*
      final response = await http
          .get(
            Uri.parse('$_baseUrl/formularios/$politicaId'),
            headers: authService.getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final plantilla = FormularioPlantilla.fromJson(jsonDecode(response.body));
        print('✅ Plantilla cargada exitosamente');
        return plantilla;
      } else {
        print('❌ Error al cargar plantilla: ${response.statusCode}');
        // Fallback a plantilla básica
        return FormularioPlantilla.crearPlantillaBasica(politicaId);
      }
      */
    } catch (e) {
      _log('❌ Error obteniendo plantilla: $e');
      // Fallback a plantilla básica en caso de error
      return FormularioPlantilla.crearPlantillaBasica(politicaId);
    }
  }

  /// Enviar trámite al backend
  /// En C1: Solo enviamos politicaId y clienteId
  /// El backend inicia el motor de workflow
  Future<RespuestaTramite> enviarTramite({
    required String politicaId,
    required String clienteId,
    Map<String, dynamic>? datos,
    int prioridad = 3,
  }) async {
    _log('📤 Enviando trámite...');
    _log('   - politicaId: $politicaId');
    _log('   - clienteId: $clienteId');

    try {
      final body = {
        'clienteId': clienteId,
        'politicaId': politicaId,
        'prioridad': prioridad,
        if (datos != null) 'datos': datos,
      };

      _log('📡 POST /api/tramites/iniciar');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/tramites/iniciar'),
            headers: authService.getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      _log('📥 Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respuesta = RespuestaTramite.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
        _log('✅ Trámite enviado exitosamente');
        _log('   - ID: ${respuesta.tramiteId}');
        _log('   - Código: ${respuesta.codigo}');
        return respuesta;
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['message'] ?? errorBody['error'] ?? 'Error desconocido';
        _log('❌ Error del servidor: $errorMessage');
        throw Exception(errorMessage);
      }
    } on http.ClientException catch (e) {
      _log('❌ Error de conexión: $e');
      throw Exception('Error de conexión con el servidor');
    } catch (e) {
      _log('❌ Error inesperado: $e');
      rethrow;
    }
  }

  /// C2 CU-07: Iniciar trámite directamente sin formulario (flujo simplificado)
  /// Endpoint: POST /api/tramites/iniciar
  /// Body: { politicaId, clienteId }
  Future<Map<String, dynamic>> iniciarTramiteC2(
      String politicaId, String clienteId) async {
    _log('🚀 C2 - Iniciando trámite: politica=$politicaId cliente=$clienteId');

    final response = await http
        .post(
          Uri.parse('$_baseUrl/tramites/iniciar'),
          headers: authService.getHeaders(),
          body: jsonEncode({'politicaId': politicaId, 'clienteId': clienteId}),
        )
        .timeout(const Duration(seconds: 10));

    _log('📥 Response iniciar C2: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      final msg = errorBody['message'] ?? errorBody['error'] ?? 'Error al iniciar el trámite';
      throw Exception(msg);
    }
  }

  /// Guardar como borrador (Ciclo 2)
  /// TODO: Implementar en C2 cuando exista endpoint /api/borradores
  Future<Map<String, dynamic>> guardarBorrador({
    required String politicaId,
    required Map<String, dynamic> datos,
    String? clienteId,
  }) async {
    _log('💾 Guardando borrador...');
    // Funcionalidad para C2
    throw Exception('Funcionalidad de borradores disponible próximamente');
  }

  /// Obtener mis borradores (Ciclo 2)
  /// TODO: Implementar en C2
  Future<List<Map<String, dynamic>>> obtenerBorradores({String? clienteId}) async {
    _log('📋 Obteniendo borradores...');
    // Funcionalidad para C2
    throw Exception('Funcionalidad de borradores disponible próximamente');
  }

  /// Eliminar borrador (Ciclo 2)
  /// TODO: Implementar en C2
  Future<bool> eliminarBorrador(String borradorId) async {
    _log('🗑️ Eliminando borrador: $borradorId');
    // Funcionalidad para C2
    throw Exception('Funcionalidad de borradores disponible próximamente');
  }
}
