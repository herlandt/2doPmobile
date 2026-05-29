/// Modelo de Actividad
class Actividad {
  final String id;
  final String nombre;
  final String descripcion;
  final String departamentoId;
  final int duracionDiasLimite;
  final bool requiereAprobacion;
  final List<String> archivos;
  final List<String> documentosRequeridos;
  final bool activo;

  Actividad({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.departamentoId,
    required this.duracionDiasLimite,
    required this.requiereAprobacion,
    required this.archivos,
    required this.documentosRequeridos,
    required this.activo,
  });

  factory Actividad.fromJson(Map<String, dynamic> json) {
    return Actividad(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      departamentoId: json['departamentoId'] as String? ?? '',
      duracionDiasLimite: json['duracionDiasLimite'] as int? ?? 0,
      requiereAprobacion: json['requiereAprobacion'] as bool? ?? false,
      archivos: List<String>.from(json['archivos'] as List? ?? []),
      documentosRequeridos: List<String>.from(json['documentosRequeridos'] as List? ?? []),
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'departamentoId': departamentoId,
      'duracionDiasLimite': duracionDiasLimite,
      'requiereAprobacion': requiereAprobacion,
      'archivos': archivos,
      'documentosRequeridos': documentosRequeridos,
      'activo': activo,
    };
  }
}
