import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import '../models/auth_model.dart';
import '../models/usuario_model.dart';
import 'storage_service.dart';

/// Servicio de Autenticación
class AuthService extends GetxService {
  final StorageService storageService;

  AuthService({required this.storageService});

  // Observable del usuario actual
  final Rx<Usuario?> usuarioActual = Rx<Usuario?>(null);

  // Observable para estado de autenticación
  final RxBool isAuthenticated = false.obs;

  final String _apiUrl = '${Environment.apiUrl}/auth';

  @override
  void onInit() {
    super.onInit();
    print('🚀 Inicializando AuthService');
    // Intentar restaurar sesión al inicializar
    _restaurarSesion();
  }

  /// Login con email y contraseña
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final url = '$_apiUrl/login';
      print('🔗 URL: $url');
      print('📝 Enviando credenciales de login');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Respuesta de login recibida');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(data);

        // Guardar token
        await storageService.saveToken(loginResponse.token);

        // Guardar datos de usuario
        if (data['usuario'] != null) {
          final usuario = Usuario.fromJson(data['usuario']);
          usuarioActual.value = usuario;
          await storageService.saveUserData(jsonEncode(usuario.toJson()));
        } else {
          // Si el backend no devuelve el usuario embebido, cargarlo con el token ya guardado.
          await obtenerDatosUsuario();
        }

        isAuthenticated.value = true;
        print('✅ Login exitoso, token guardado');
        return loginResponse;
      } else {
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Error al iniciar sesión';
        print('❌ Error: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ Excepción en login: $e');
      isAuthenticated.value = false;
      rethrow;
    }
  }

  /// Registrar nuevo cliente
  Future<RegisterResponse> registrar(RegisterRequest request) async {
    try {
      // Validar que las contraseñas coincidan
      if (request.password != request.passwordConfirm) {
        throw Exception('Las contraseñas no coinciden');
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/register-cliente'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RegisterResponse.fromJson(data);
      } else {
        throw Exception(
          jsonDecode(response.body)['message'] ?? 'Error al registrarse',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener datos del usuario actual desde el backend
  Future<Usuario?> obtenerDatosUsuario() async {
    try {
      final token = getToken();
      if (token == null) {
        logout();
        return null;
      }

      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/usuarios/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final usuario = Usuario.fromJson(data);
        usuarioActual.value = usuario;
        await storageService.saveUserData(jsonEncode(usuario.toJson()));
        isAuthenticated.value = true;
        return usuario;
      } else if (response.statusCode == 401) {
        // Token expirado o inválido
        logout();
        return null;
      } else {
        throw Exception('Error al obtener datos del usuario');
      }
    } catch (e) {
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    await storageService.clear();
    usuarioActual.value = null;
    isAuthenticated.value = false;
  }

  /// Obtener token actual
  String? getToken() {
    return storageService.getToken();
  }

  /// Verificar si está autenticado
  bool verificarAutenticacion() {
    return storageService.hasToken() && usuarioActual.value != null;
  }

  /// Obtener usuario actual sin hacer llamada HTTP
  Usuario? getUsuarioActual() {
    return usuarioActual.value;
  }

  /// Restaurar sesión si existe token guardado
  Future<void> _restaurarSesion() async {
    try {
      print('🔄 Intentando restaurar sesión...');
      if (storageService.hasToken()) {
        print('✅ Token encontrado en storage');
        isAuthenticated.value = true;
        await obtenerDatosUsuario();
        print('✅ Sesión restaurada');
      } else {
        print('⚠️ No hay token guardado');
      }
    } catch (e) {
      print('❌ Error restaurando sesión: $e');
      logout();
    }
  }

  /// Crear headers HTTP con token si existe
  Map<String, String> getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    final token = getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
