/// Configuración de ambiente — apunta al backend Spring Boot.
///
/// Reglas según dónde corre la app:
///   • Producción (EC2 + nginx TLS)       → https://api.ficctuagrmbolivia.online/api
///   • Android USB / dispositivo físico   → IP de la PC en la red LAN
///   • Emulador Android (AVD)             → http://10.0.2.2:8080/api
///   • Chrome / Edge / Windows desktop    → http://localhost:8080/api
///
/// Cambia `apiUrl` según el caso de uso. Para encontrar tu IP local en Windows:
///     ipconfig | findstr IPv4
class Environment {
  /// Producción: el backend desplegado en AWS, detrás de nginx con TLS.
  static const String apiUrl = 'https://api.ficctuagrmbolivia.online/api';
  static const bool isProduction = true;

  // ─── Alternativas comentadas (descomenta la que necesites para desarrollo) ─
  // Producción (EC2 + dominio TLS):     'https://api.ficctuagrmbolivia.online/api'
  // Dispositivo físico por USB/WiFi:    'http://<IP-DE-TU-PC>:8080/api'
  // Emulador Android oficial:           'http://10.0.2.2:8080/api'
  // Web (Chrome/Edge) o Windows nativo: 'http://localhost:8080/api'
}

/// Configuración de producción (no se usa por ahora — referencia futura)
class EnvironmentProd {
  static const String apiUrl = 'https://api.ficctuagrmbolivia.online/api';
  static const bool isProduction = true;
}
