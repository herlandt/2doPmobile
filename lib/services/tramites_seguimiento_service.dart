// Guía 4F - Servicio de Seguimiento de Trámites

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import '../models/tramite_resumen_model.dart';
import '../models/tramite_estado_model.dart';
import '../models/flujo_completo_model.dart';
import 'auth_service.dart';

class TramitesSeguimientoService extends GetxService {
  late AuthService authService;

  final String _baseUrl = '${Environment.apiUrl}';

  // Observables
  final RxList<TramiteResumen> misTramites = RxList<TramiteResumen>();
  final Rx<EstadoTramite?> estadoActual = Rx<EstadoTramite?>(null);
  final RxBool isLoading = RxBool(false);

  @override
  void onInit() {
    super.onInit();
    authService = Get.find<AuthService>();
    print('🔧 TramitesSeguimientoService inicializado');
  }

  /// Obtener lista de mis trámites
  /// Endpoint: GET /api/workflow/mis-tramites
  Future<List<TramiteResumen>> obtenerMisTramites() async {
    print('📋 Obteniendo mis trámites...');

    try {
      isLoading.value = true;

      final response = await http
          .get(
            Uri.parse('$_baseUrl/tramites/mis-tramites'),
            headers: authService.getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        misTramites.value = jsonList.map((j) => TramiteResumen.fromJson(j)).toList();
        print('✅ ${misTramites.length} trámites cargados');
        return misTramites;
      } else {
        print('❌ Error: ${response.statusCode}');
        throw Exception('Error al obtener trámites');
      }
    } catch (e) {
      print('❌ Error obteniendo trámites: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtener estado detallado de un trámite
  /// Endpoint: GET /api/workflow/{tramiteId}/estado
  Future<EstadoTramite> obtenerEstadoTramite(String tramiteId) async {
    print('📊 Obteniendo estado del trámite: $tramiteId');

    try {
      isLoading.value = true;

      final response = await http
          .get(
            Uri.parse('$_baseUrl/tramites/$tramiteId/estado'),
            headers: authService.getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        estadoActual.value = EstadoTramite.fromJson(jsonDecode(response.body));
        print('✅ Estado cargado: ${estadoActual.value?.estado}');
        return estadoActual.value!;
      } else {
        print('❌ Error: ${response.statusCode}');
        throw Exception('Error al obtener estado del trámite');
      }
    } catch (e) {
      print('❌ Error obteniendo estado: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtener el camino completo del trámite (todos los nodos del flujo)
  /// con documentos requeridos por cada actividad.
  /// Endpoint: GET /api/tramites/{tramiteId}/flujo-completo
  Future<FlujoCompleto> obtenerFlujoCompleto(String tramiteId) async {
    print('🛤️  Obteniendo flujo completo: $tramiteId');
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/tramites/$tramiteId/flujo-completo'),
            headers: authService.getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Response flujo: ${response.statusCode}');

      if (response.statusCode == 200) {
        return FlujoCompleto.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al obtener flujo (HTTP ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error obteniendo flujo: $e');
      rethrow;
    }
  }

  /// Calcular porcentaje de progreso basado en secciones completadas
  int calcularProgreso(EstadoTramite estado) {
    if (estado.expediente.secciones.isEmpty) return 0;

    final completadas =
        estado.expediente.secciones.where((s) => s.estado == 'completada').length;
    final progreso = (completadas / estado.expediente.secciones.length * 100).round();

    return progreso;
  }

  /// True si el trámite está en un estado terminal (ya no avanza)
  bool esEstadoTerminal(String estado) {
    const terminales = {
      'Aprobado', 'Rechazado', 'Cancelado',
      'completado', 'archivado', 'rechazado',
    };
    return terminales.contains(estado);
  }

  /// Progreso efectivo: 100 % para aprobados, real para el resto
  int progresoEfectivo(int progresoBackend, String estado) {
    if (estado == 'Aprobado' || estado == 'completado') return 100;
    if (esEstadoTerminal(estado) && progresoBackend == 0) return 100;
    return progresoBackend;
  }

  /// Color Flutter según estado del trámite
  Color getColorEstadoFlutter(String estado) {
    switch (estado) {
      case 'Aprobado':
      case 'completado':
        return Colors.green;
      case 'Rechazado':
      case 'rechazado':
        return Colors.red;
      case 'Cancelado':
      case 'archivado':
        return Colors.grey;
      case 'Observado':
      case 'Devuelto':
        return Colors.orange;
      case 'En proceso':
      case 'Derivado':
      case 'activo':
      case 'en_progreso':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }

  /// Obtener icono según tipo de evento
  String getIconoEvento(String tipo) {
    const iconos = {
      'creacion': '📝',
      'cambio_estado': '→',
      'aprobacion': '✅',
      'rechazo': '❌',
      'completacion': '✓',
      'archivo': '📎',
    };
    return iconos[tipo] ?? '•';
  }

  /// Obtener icono según estado
  String getIconoEstado(String estado) {
    const iconos = {
      // Estados backend
      'Aprobado': '✅',
      'Rechazado': '❌',
      'Cancelado': '🚫',
      'En proceso': '⏳',
      'Derivado': '↗️',
      'Observado': '⚠️',
      'Devuelto': '↩️',
      'Nuevo': '🆕',
      // Estados legacy
      'borrador': '📝',
      'en_progreso': '⏳',
      'completado': '✅',
      'archivado': '📦',
      'rechazado': '❌',
    };
    return iconos[estado] ?? '•';
  }

  /// Obtener texto legible del estado
  String getTextoEstado(String estado) {
    const textos = {
      // Estados backend reales
      'Aprobado': 'Aprobado',
      'Rechazado': 'Rechazado',
      'Cancelado': 'Cancelado',
      'En proceso': 'En Proceso',
      'Derivado': 'Derivado',
      'Observado': 'Observado',
      'Devuelto': 'Devuelto',
      'Nuevo': 'Nuevo',
      // Estados legacy
      'borrador': 'Borrador',
      'activo': 'En Proceso',
      'en_progreso': 'En Proceso',
      'completado': 'Completado',
      'archivado': 'Archivado',
      'rechazado': 'Rechazado',
    };
    return textos[estado] ?? estado;
  }

  /// Limpiar estado actual
  void limpiarEstado() {
    estadoActual.value = null;
    print('🧹 Estado limpiado');
  }

  // ─── C2: Expediente y Subsanación ────────────────────────────────────────

  /// C2 CU-17: Obtener expediente completo de un trámite
  /// Endpoint: GET /api/expedientes/tramite/{tramiteId}
  Future<Map<String, dynamic>> getExpediente(String tramiteId) async {
    print('📂 Obteniendo expediente del trámite: $tramiteId');
    final response = await http
        .get(
          Uri.parse('$_baseUrl/expedientes/tramite/$tramiteId'),
          headers: authService.getHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Error al cargar el expediente del trámite');
    }
  }

  /// C2 CU-17: Enviar corrección completando la sección activa del expediente
  /// Flujo: obtiene el expediente → localiza sección 'en_curso' → POST /completar
  Future<void> enviarCorreccion(String tramiteId, String notas) async {
    print('✏️ Enviando corrección para trámite: $tramiteId');

    final expediente = await getExpediente(tramiteId);
    final secciones = expediente['secciones'] as List<dynamic>? ?? [];

    final seccionActiva = secciones.firstWhere(
      (s) {
        final info = s['infoSeccion'] as Map<String, dynamic>?;
        return info?['estado'] == 'en_curso';
      },
      orElse: () => null,
    );

    if (seccionActiva == null) {
      throw Exception('No se encontró una sección activa para corregir.');
    }

    final seccionId = seccionActiva['infoSeccion']['id'];

    final response = await http
        .post(
          Uri.parse('$_baseUrl/expedientes/seccion/$seccionId/completar'),
          headers: authService.getHeaders(),
          body: json.encode({'notasOperativas': notas}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al enviar la corrección al sistema.');
    }
    print('✅ Corrección enviada correctamente');
  }

  // ─── C3: Línea de Tiempo y Cancelación ───────────────────────────────────

  /// C3 CU-21: Consultar línea de tiempo visual del trámite
  /// Endpoint: GET /api/tramites/{id}/linea-tiempo
  /// Respuesta: LineaTiempoResponse { tramiteId, estadoActual, hitos: [HitoDTO] }
  Future<Map<String, dynamic>> getLineaTiempoTramite(String tramiteId) async {
    print('📊 Obteniendo línea de tiempo: $tramiteId');
    final response = await http
        .get(
          Uri.parse('$_baseUrl/tramites/$tramiteId/linea-tiempo'),
          headers: authService.getHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('No se pudo cargar la línea de tiempo del trámite.');
    }
  }

  /// C3 CU-19: Cancelar trámite (desistimiento voluntario)
  /// Endpoint: POST /api/tramites/{id}/cancelar
  Future<void> cancelarTramite(String tramiteId, String motivo) async {
    print('🚫 Cancelando trámite: $tramiteId');
    final response = await http
        .post(
          Uri.parse('$_baseUrl/tramites/$tramiteId/cancelar'),
          headers: authService.getHeaders(),
          body: json.encode({'motivo': motivo}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('El trámite ya no puede ser cancelado en este momento.');
    }
    print('✅ Trámite cancelado');
  }
}
