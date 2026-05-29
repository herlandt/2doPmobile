// Parte 2 — Documento del repositorio documental (CU-32 a CU-35).

class DocumentoArchivo {
  final String id;
  final String repositorioId;
  final String politicaId;
  final String tramiteId;
  final String actividadId;
  final String? nodoId;
  final String nombreLogico;
  final String tipoDocumento;
  final bool obligatorio;
  final String versionActualId;
  final int numeroVersionActual;
  final String? bloqueadoPor;
  final DateTime? fechaCreacion;
  final bool activo;

  DocumentoArchivo({
    required this.id,
    required this.repositorioId,
    required this.politicaId,
    required this.tramiteId,
    required this.actividadId,
    this.nodoId,
    required this.nombreLogico,
    required this.tipoDocumento,
    required this.obligatorio,
    required this.versionActualId,
    required this.numeroVersionActual,
    this.bloqueadoPor,
    this.fechaCreacion,
    required this.activo,
  });

  factory DocumentoArchivo.fromJson(Map<String, dynamic> json) {
    return DocumentoArchivo(
      id: json['id']?.toString() ?? '',
      repositorioId: json['repositorioId']?.toString() ?? '',
      politicaId: json['politicaId']?.toString() ?? '',
      tramiteId: json['tramiteId']?.toString() ?? '',
      actividadId: json['actividadId']?.toString() ?? '',
      nodoId: json['nodoId']?.toString(),
      nombreLogico: json['nombreLogico']?.toString() ?? '',
      tipoDocumento: json['tipoDocumento']?.toString() ?? 'OTRO',
      obligatorio: json['obligatorio'] == true,
      versionActualId: json['versionActualId']?.toString() ?? '',
      numeroVersionActual: (json['numeroVersionActual'] as num?)?.toInt() ?? 1,
      bloqueadoPor: json['bloqueadoPor']?.toString(),
      fechaCreacion: _parseDate(json['fechaCreacion']),
      activo: json['activo'] != false,
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

class PreviewDocumento {
  final String urlPreview;
  final String mimeType;
  final String? expiraEn;

  PreviewDocumento({
    required this.urlPreview,
    required this.mimeType,
    this.expiraEn,
  });

  factory PreviewDocumento.fromJson(Map<String, dynamic> json) {
    return PreviewDocumento(
      urlPreview: json['urlPreview']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      expiraEn: json['expiraEn']?.toString(),
    );
  }

  bool get esImagen => mimeType.startsWith('image/');
  bool get esPdf => mimeType == 'application/pdf';
}
