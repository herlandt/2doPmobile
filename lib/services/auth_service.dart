import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final loginResponse = LoginResponse.fromJson(data);

        // Guardar token
        await storageService.saveToken(loginResponse.token);

        // Guardar datos de usuario
        if (data['usuario'] != null) {
          final usuario = Usuario.fromJson(data['usuario']);
          usuarioActual.value = usuario;
          await storageService.saveUserData(jsonEncode(usuario.toJson()));
          isAuthenticated.value = true;
        } else {
          // El backend no embebe el usuario: cargarlo con el token ya guardado.
          // Si falla (red caída), NO dejamos sesión a medias (autenticado sin usuario).
          final usuario = await obtenerDatosUsuario();
          if (usuario == null) {
            // Borramos el token ya guardado para no dejar sesión a medias
            // (token residual reusado en el próximo arranque).
            await logout();
            throw Exception(
              'No se pudo cargar el perfil. Verifica tu conexión e intenta de nuevo.',
            );
          }
          // obtenerDatosUsuario ya marcó isAuthenticated=true al cargar el usuario.
        }

        print('✅ Login exitoso, token guardado');
        return loginResponse;
      } else {
        final errorMsg =
            jsonDecode(utf8.decode(response.bodyBytes))['message'] ??
                'Error al iniciar sesión (${response.statusCode})';
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

      final response = await http
          .post(
            Uri.parse('$_apiUrl/register-cliente'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return RegisterResponse.fromJson(data);
      } else {
        throw Exception(
          jsonDecode(utf8.decode(response.bodyBytes))['message'] ??
              'Error al registrarse (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar el perfil propio (PUT /usuarios/me).
  /// El backend NO cambia email/tipo/rol/password con este endpoint.
  /// Actualiza [usuarioActual] con la respuesta del servidor.
  Future<Usuario> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String telefono,
    required String dni,
    required String direccion,
  }) async {
    final token = getToken();
    if (token == null) {
      throw Exception('No hay sesión activa');
    }

    final response = await http
        .put(
          Uri.parse('${Environment.apiUrl}/usuarios/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'nombre': nombre,
            'apellido': apellido,
            'telefono': telefono,
            'dni': dni,
            'direccion': direccion,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final usuario = Usuario.fromJson(data);
      usuarioActual.value = usuario;
      await storageService.saveUserData(jsonEncode(usuario.toJson()));
      return usuario;
    } else if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Inicia sesión de nuevo.');
    } else {
      final body = utf8.decode(response.bodyBytes);
      String msg = 'Error al actualizar el perfil (${response.statusCode})';
      try {
        msg = jsonDecode(body)['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
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

      final response = await http
          .get(
            Uri.parse('${Environment.apiUrl}/usuarios/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
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
        throw Exception('Error al obtener datos del usuario: ${response.statusCode}');
      }
    } catch (e) {
      // Error de red (timeout/conexión): no borramos la sesión ni el token,
      // pero evitamos quedar autenticados sin usuario cargado.
      isAuthenticated.value = false;
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
        // No marcamos isAuthenticated=true a ciegas: obtenerDatosUsuario()
        // lo pone en true solo tras un 200 con el usuario cargado.
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
