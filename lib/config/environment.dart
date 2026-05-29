/// Configuración de ambiente — apunta al backend Spring Boot.
///
/// Reglas según dónde corre la app:
///   • Android USB / dispositivo físico  → IP de la PC en la red LAN
///   • Emulador Android (AVD)             → 10.0.2.2 (alias del host)
///   • Chrome / Edge / Windows desktop    → localhost
///   • Producción (EC2)                   → 44.213.74.152
///
/// Cambia `apiUrl` según el caso de uso. Para encontrar tu IP local en Windows:
///     ipconfig | findstr IPv4
class Environment {
  /// Dispositivo Android conectado por USB en la misma red WiFi que la PC.
  static const String apiUrl = 'http://localhost:8080/api';
  static const bool isProduction = false;

  // ─── Alternativas comentadas (descomenta la que necesites) ────────────────
  // Emulador Android oficial:           'http://10.0.2.2:8080/api'
  // Web (Chrome/Edge) o Windows nativo: 'http://localhost:8080/api'
  // Producción EC2:                      'http://44.213.74.152:8080/api'
}

/// Configuración de producción (no se usa por ahora — referencia futura)
class EnvironmentProd {
  static const String apiUrl = 'https://api.tudominio.com/api';
  static const bool isProduction = true;
}
