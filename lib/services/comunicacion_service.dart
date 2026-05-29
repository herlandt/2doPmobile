// C3 — Servicio de Comunicación: Notificaciones (CU-28) y Agente IA (CU-31)

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import 'auth_service.dart';

class ComunicacionService extends GetxService {
  late AuthService authService;

  final String _baseUrl = Environment.apiUrl;

  final RxList<dynamic> notificaciones = RxList<dynamic>();
  final RxBool isLoading = RxBool(false);

  @override
  void onInit() {
    super.onInit();
    authService = Get.find<AuthService>();
    print('🔧 ComunicacionService inicializado');
  }

  /// CU-28: Obtener notificaciones del usuario autenticado
  /// Endpoint: GET /api/notificaciones/mis-notificaciones
  Future<List<dynamic>> getMisNotificaciones() async {
    print('🔔 Obteniendo notificaciones...');
    try {
      isLoading.value = true;
      final response = await http
          .get(
            Uri.parse('$_baseUrl/notificaciones/mis-notificaciones'),
            headers: authService.getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Response notificaciones: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> lista = json.decode(utf8.decode(response.bodyBytes));
        notificaciones.value = lista;
        return lista;
      } else {
        throw Exception('Error al obtener notificaciones: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error notificaciones: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// CU-31: Consultar al Agente Conversacional de IA
  /// Endpoint: POST /api/agente/consultar
  /// Body: AgenteRequest { consulta, moduloActivo, tramiteIdOpcional? }
  Future<Map<String, dynamic>> consultarAgenteIA(
      String consulta, String moduloActivo,
      {String? tramiteIdOpcional}) async {
    print('🤖 Consultando agente IA: $consulta');
    try {
      final body = {
        'consulta': consulta,
        'moduloActivo': moduloActivo,
        if (tramiteIdOpcional != null) 'tramiteIdOpcional': tramiteIdOpcional,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/agente/consultar'),
            headers: authService.getHeaders(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 20));

      print('📥 Response agente: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        return {
          'respuesta':
              'Lo siento, el asistente virtual no está disponible en este momento.'
        };
      }
    } catch (e) {
      print('❌ Error agente IA: $e');
      return {'respuesta': 'Error de conexión con el asistente.'};
    }
  }
}
