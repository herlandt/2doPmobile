import 'dart:async';
import 'dart:io';

/// Convierte cualquier error (Exception, error de red, timeout, código HTTP,
/// etc.) en un mensaje claro y accionable en español para mostrar al usuario.
///
/// Está pensado para los errores que lanzan los servicios de `lib/services`,
/// que típicamente hacen `throw Exception('Error al ... ${response.statusCode}')`
/// o lanzan excepciones propias como [SubidaException] / `DocException` cuyo
/// `toString()` ya es un texto legible.
///
/// Garantías:
///  - NUNCA lanza: cualquier fallo interno cae al mensaje por defecto.
///  - Solo usa imports estándar (`dart:io`, `dart:async`).
///
/// Orden de detección (de más específico a más genérico):
///  1. Excepción con mensaje ya legible (toString no empieza con "Exception:").
///  2. Error de red (SocketException / texto de DNS / conexión rechazada).
///  3. Timeout.
///  4. Código HTTP detectado como palabra en el texto.
///  5. Mensaje por defecto.
String mensajeAmigable(Object e) {
  try {
    // Texto base del error para inspeccionarlo con heurísticas.
    final String raw = e.toString();
    final String texto = raw.toLowerCase();

    // 1) Mensaje ya legible: excepciones propias como SubidaException cuyo
    // toString() NO lleva el prefijo "Exception:" devuelven su mensaje tal cual.
    // Se valida que sea una Exception, con contenido útil, y SIN un código HTTP
    // embebido — así las técnicas como "DocException(403, ...): ..." no se muestran
    // crudas: caen a la regla 4 y se mapean a un mensaje claro por su código.
    if (e is Exception &&
        !raw.startsWith('Exception:') &&
        _extraerCodigoHttp(raw) == null) {
      final limpio = raw.trim();
      if (limpio.isNotEmpty) return limpio;
    }

    // 2) Errores de red: sin conexión, DNS no resuelve o conexión rechazada.
    if (e is SocketException ||
        texto.contains('socketexception') ||
        texto.contains('failed host lookup') ||
        texto.contains('connection refused') ||
        texto.contains('connection closed') ||
        texto.contains('network is unreachable')) {
      return 'Sin conexión a internet. Revisa tu red e intenta de nuevo.';
    }

    // 3) Timeout: el servidor no respondió a tiempo.
    if (e is TimeoutException || texto.contains('timeoutexception')) {
      return 'El servidor tardó demasiado en responder. Intenta de nuevo.';
    }

    // 4) Código HTTP embebido en el texto (p. ej. "... ${response.statusCode}").
    final int? code = _extraerCodigoHttp(raw);
    if (code != null) {
      switch (code) {
        case 401:
          return 'Tu sesión expiró. Inicia sesión de nuevo.';
        case 403:
          return 'No tienes permiso para esta acción.';
        case 404:
          return 'No se encontró lo que buscabas.';
        case 409:
          return 'Conflicto con el estado actual.';
        case 413:
          return 'El archivo es demasiado grande.';
        case 400:
        case 422:
          return 'Datos inválidos. Revisa lo ingresado.';
        case 500:
        case 502:
        case 503:
        case 504:
          return 'El servidor no está disponible ahora. Intenta más tarde.';
      }
    }

    // 5) Nada coincidió.
    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  } catch (_) {
    // Robustez total: ante cualquier fallo interno, mensaje seguro.
    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }
}

/// Busca un código HTTP conocido como NÚMERO COMPLETO (palabra) dentro del
/// texto, evitando falsos positivos como "404" dentro de "14045". Devuelve el
/// primer código de la lista soportada que aparezca, o `null` si no hay ninguno.
int? _extraerCodigoHttp(String texto) {
  const codigos = <int>[
    400, 401, 403, 404, 409, 413, 422, 500, 502, 503, 504,
  ];
  for (final c in codigos) {
    // \b...\b -> el número no está pegado a otro dígito (límite de palabra).
    final patron = RegExp(r'\b' + c.toString() + r'\b');
    if (patron.hasMatch(texto)) return c;
  }
  return null;
}
