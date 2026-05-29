// Parte 2 — Historial de versiones de un DocumentoArchivo (CU-35).

class VersionDocumento {
  final String versionId;
  final int numeroVersion;
  final String autorId;
  final List<String> coautores;
  final String? comentarioCambio;
  final int tamanoBytes;
  final String? mimeType;
  final String? hashSha256;
  final DateTime? fechaCreacion;
  final bool esActual;

  VersionDocumento({
    required this.versionId,
    required this.numeroVersion,
    required this.autorId,
    required this.coautores,
    this.comentarioCambio,
    required this.tamanoBytes,
    this.mimeType,
    this.hashSha256,
    this.fechaCreacion,
    required this.esActual,
  });

  factory VersionDocumento.fromJson(Map<String, dynamic> json) {
    return VersionDocumento(
      versionId: json['versionId']?.toString() ?? '',
      numeroVersion: (json['numeroVersion'] as num?)?.toInt() ?? 1,
      autorId: json['autorId']?.toString() ?? '',
      coautores: (json['coautores'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      comentarioCambio: json['comentarioCambio']?.toString(),
      tamanoBytes: (json['tamanoBytes'] as num?)?.toInt() ?? 0,
      mimeType: json['mimeType']?.toString(),
      hashSha256: json['hashSha256']?.toString(),
      fechaCreacion: _parseDate(json['fechaCreacion']),
      esActual: json['esActual'] == true,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }
}
