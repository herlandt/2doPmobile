import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import '../models/politica_model.dart';
import '../models/actividad_model.dart';
import '../models/departamento_model.dart';
import 'auth_service.dart';

/// Servicio para manejar trámites y políticas
class TramitesService extends GetxService {
  final AuthService authService = Get.find<AuthService>();

  final String _baseUrl = Environment.apiUrl;

  // Observables
  final RxList<Politica> politicas = RxList<Politica>();
  final RxList<Actividad> actividades = RxList<Actividad>();
  final RxList<Departamento> departamentos = RxList<Departamento>();
  final Rx<Politica?> politicaActual = Rx<Politica?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  /// Obtener lista de políticas
  Future<List<Politica>> obtenerPoliticas({String? estado}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('📋 Obteniendo políticas...');
      print('   URL: $_baseUrl/politicas');
      if (estado != null) print('   Estado: $estado');

      final url = estado != null
          ? Uri.parse('$_baseUrl/politicas?estado=$estado')
          : Uri.parse('$_baseUrl/politicas');

      final response = await http.get(
        url,
        headers: authService.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('   Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        politicas.value =
            data.map((e) => Politica.fromJson(e as Map<String, dynamic>)).toList();

        print('✅ ${politicas.length} políticas cargadas');
        return politicas;
      } else {
        throw Exception('Error al obtener políticas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error obteniendo políticas: $e');
      errorMessage.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtener detalle de una política específica
  Future<Politica> obtenerPoliticaPorId(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('📋 Obteniendo política: $id');

      final response = await http.get(
        Uri.parse('$_baseUrl/politicas/$id'),
        headers: authService.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('   Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        politicaActual.value = Politica.fromJson(data);
        print('✅ Política cargada: ${politicaActual.value?.nombre}');
        return politicaActual.value!;
      } else {
        throw Exception('Error al obtener política: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error obteniendo política: $e');
      errorMessage.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtener lista de actividades
  Future<List<Actividad>> obtenerActividades() async {
    try {
      print('🎯 Obteniendo actividades...');

      final response = await http.get(
        Uri.parse('$_baseUrl/actividades'),
        headers: authService.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        actividades.value = data
            .map((e) => Actividad.fromJson(e as Map<String, dynamic>))
            .toList();

        print('✅ ${actividades.length} actividades cargadas');
        return actividades;
      } else {
        throw Exception('Error al obtener actividades: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error obteniendo actividades: $e');
      rethrow;
    }
  }

  /// Obtener actividad por ID
  Future<Actividad> obtenerActividadPorId(String id) async {
    try {
      print('🎯 Obteniendo actividad: $id');

      final response = await http.get(
        Uri.parse('$_baseUrl/actividades/$id'),
        headers: authService.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('✅ Actividad cargada');
        return Actividad.fromJson(data);
      } else {
        throw Exception('Error al obtener actividad: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error obteniendo actividad: $e');
      rethrow;
    }
  }

  /// Obtener lista de departamentos
  Future<List<Departamento>> obtenerDepartamentos() async {
    try {
      print('🏢 Obteniendo departamentos...');

      final response = await http.get(
        Uri.parse('$_baseUrl/departamentos'),
        headers: authService.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        departamentos.value = data
            .map((e) => Departamento.fromJson(e as Map<String, dynamic>))
            .toList();

        print('✅ ${departamentos.length} departamentos cargados');
        return departamentos;
      } else {
        throw Exception('Error al obtener departamentos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error obteniendo departamentos: $e');
      rethrow;
    }
  }

  /// Obtener departamento por ID
  Future<Departamento> obtenerDepartamentoPorId(String id) async {
    try {
      print('🏢 Obteniendo departamento: $id');

      final response = await http.get(
        Uri.parse('$_baseUrl/departamentos/$id'),
        headers: authService.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('✅ Departamento cargado');
        return Departamento.fromJson(data);
      } else {
        throw Exception('Error al obtener departamento: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error obteniendo departamento: $e');
      rethrow;
    }
  }

  /// Filtrar políticas localmente
  List<Politica> filtrarPoliticas(String busqueda) {
    if (busqueda.isEmpty) {
      return politicas;
    }

    final termino = busqueda.toLowerCase();
    return politicas
        .where((p) =>
            p.nombre.toLowerCase().contains(termino) ||
            p.descripcion.toLowerCase().contains(termino))
        .toList();
  }

  /// Obtener políticas por estado
  List<Politica> obtenerPorEstado(String estado) {
    return politicas.where((p) => p.estado == estado).toList();
  }

  /// Limpiar datos
  void limpiar() {
    politicas.clear();
    actividades.clear();
    departamentos.clear();
    politicaActual.value = null;
    errorMessage.value = '';
  }
}
