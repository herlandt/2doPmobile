// CU-42 / CU-43 — Predicción IA: riesgo de demora y ruta óptima.

enum NivelRiesgo { bajo, medio, alto, desconocido }

NivelRiesgo nivelDesdeString(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'bajo':
      return NivelRiesgo.bajo;
    case 'medio':
      return NivelRiesgo.medio;
    case 'alto':
      return NivelRiesgo.alto;
    default:
      return NivelRiesgo.desconocido;
  }
}

class TramiteRiesgo {
  final String tramiteId;
  final double probSuperarSla;
  final NivelRiesgo nivel;
  final List<String> razones;

  TramiteRiesgo({
    required this.tramiteId,
    required this.probSuperarSla,
    required this.nivel,
    required this.razones,
  });

  factory TramiteRiesgo.fromJson(Map<String, dynamic> json) {
    return TramiteRiesgo(
      tramiteId: json['tramiteId']?.toString() ?? '',
      probSuperarSla: (json['probSuperarSla'] as num?)?.toDouble() ?? 0.0,
      nivel: nivelDesdeString(json['nivel']?.toString()),
      razones: (json['razones'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class PasoOmitido {
  final String nodoId;
  final String motivo;

  PasoOmitido({required this.nodoId, required this.motivo});

  factory PasoOmitido.fromJson(Map<String, dynamic> json) {
    return PasoOmitido(
      nodoId: json['nodoId']?.toString() ?? '',
      motivo: json['motivo']?.toString() ?? '',
    );
  }
}

class RutaOptima {
  final List<String> rutaSugerida;
  final List<PasoOmitido> pasosOmitidos;
  final double confianza;
  final String? explicacion;

  RutaOptima({
    required this.rutaSugerida,
    required this.pasosOmitidos,
    required this.confianza,
    this.explicacion,
  });

  factory RutaOptima.fromJson(Map<String, dynamic> json) {
    return RutaOptima(
      rutaSugerida: (json['rutaSugerida'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      pasosOmitidos: (json['pasosOmitidos'] as List<dynamic>? ?? [])
          .map((e) => PasoOmitido.fromJson(e as Map<String, dynamic>))
          .toList(),
      confianza: (json['confianza'] as num?)?.toDouble() ?? 0.0,
      explicacion: json['explicacion']?.toString(),
    );
  }
}
