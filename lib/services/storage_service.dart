import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar almacenamiento local
class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  late SharedPreferences _preferences;

  /// Inicializar el servicio
  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// Guardar token
  Future<bool> saveToken(String token) async {
    return await _preferences.setString(_tokenKey, token);
  }

  /// Obtener token
  String? getToken() {
    return _preferences.getString(_tokenKey);
  }

  /// Guardar datos de usuario
  Future<bool> saveUserData(String userData) async {
    return await _preferences.setString(_userKey, userData);
  }

  /// Obtener datos de usuario
  String? getUserData() {
    return _preferences.getString(_userKey);
  }

  /// Limpiar todo (logout)
  Future<bool> clear() async {
    return await _preferences.clear();
  }

  /// Verificar si hay token
  bool hasToken() {
    return _preferences.containsKey(_tokenKey);
  }
}
