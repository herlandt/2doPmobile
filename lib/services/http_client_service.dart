import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'package:get/get.dart';

/// Cliente HTTP personalizado con manejo automático de tokens
class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();

  factory HttpClientService() {
    return _instance;
  }

  HttpClientService._internal();

  final authService = Get.find<AuthService>();

  /// Realizar GET request
  Future<http.Response> get(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: authService.getHeaders(),
      ).timeout(const Duration(seconds: 30));

      await _handleResponse(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Realizar POST request
  Future<http.Response> post(
    String url, {
    dynamic body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: authService.getHeaders(),
        body: body,
      ).timeout(const Duration(seconds: 30));

      await _handleResponse(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Realizar PUT request
  Future<http.Response> put(
    String url, {
    dynamic body,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: authService.getHeaders(),
        body: body,
      ).timeout(const Duration(seconds: 30));

      await _handleResponse(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Realizar DELETE request
  Future<http.Response> delete(String url) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: authService.getHeaders(),
      ).timeout(const Duration(seconds: 30));

      await _handleResponse(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Manejar respuesta HTTP
  Future<void> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      // Token expirado o inválido
      await authService.logout();
      Get.offNamed('/login');
      throw Exception('Sesión expirada');
    } else if (response.statusCode >= 500) {
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  }
}
