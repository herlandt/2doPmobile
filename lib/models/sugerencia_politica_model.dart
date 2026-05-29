// CU-40 — Sugerencia automática de política a partir de descripción libre.

class CandidatoPolitica {
  final String politicaId;
  final String nombre;
  final double confianza;

  CandidatoPolitica({
    required this.politicaId,
    required this.nombre,
    required this.confianza,
  });

  factory CandidatoPolitica.fromJson(Map<String, dynamic> json) {
    return CandidatoPolitica(
      politicaId: json['politicaId']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      confianza: (json['confianza'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SugerenciaPolitica {
  final String sugerenciaId;
  final String politicaSugeridaId;
  final double confianza;
  final List<CandidatoPolitica> top3;

  SugerenciaPolitica({
    required this.sugerenciaId,
    required this.politicaSugeridaId,
    required this.confianza,
    required this.top3,
  });

  factory SugerenciaPolitica.fromJson(Map<String, dynamic> json) {
    return SugerenciaPolitica(
      sugerenciaId: json['sugerenciaId']?.toString() ?? '',
      politicaSugeridaId: json['politicaSugeridaId']?.toString() ?? '',
      confianza: (json['confianza'] as num?)?.toDouble() ?? 0.0,
      top3: (json['top3'] as List<dynamic>? ?? [])
          .map((e) => CandidatoPolitica.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
