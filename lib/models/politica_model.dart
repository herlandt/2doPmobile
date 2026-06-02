/// Modelo de Política de Negocio / Trámite
class Politica {
  final String id;
  final String nombre;
  final String descripcion;
  final String estado; // borrador, activa, archivada
  final int duracionDiasLimite;
  final bool requiereAprobacion;
  final bool activo;
  final String fechaCreacion;

  Politica({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.estado,
    required this.duracionDiasLimite,
    required this.requiereAprobacion,
    required this.activo,
    required this.fechaCreacion,
  });

  factory Politica.fromJson(Map<String, dynamic> json) {
    return Politica(
      // M1: null-safe — un registro con id/nombre/descripcion null o ausente
      // ya no rompe el .map() de toda la lista (catálogo vacío).
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      estado: json['estado'] as String? ?? 'activa',
      duracionDiasLimite: json['duracionDiasLimite'] as int? ?? 0,
      requiereAprobacion: json['requiereAprobacion'] as bool? ?? false,
      activo: json['activo'] as bool? ?? true,
      fechaCreacion: json['fechaCreacion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'estado': estado,
      'duracionDiasLimite': duracionDiasLimite,
      'requiereAprobacion': requiereAprobacion,
      'activo': activo,
      'fechaCreacion': fechaCreacion,
    };
  }

  // CopyWith
  Politica copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? estado,
    int? duracionDiasLimite,
    bool? requiereAprobacion,
    bool? activo,
    String? fechaCreacion,
  }) {
    return Politica(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      duracionDiasLimite: duracionDiasLimite ?? this.duracionDiasLimite,
      requiereAprobacion: requiereAprobacion ?? this.requiereAprobacion,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}

/// Documentos requeridos de una actividad (para vista general de la política)
class ActividadDocumentos {
  final String actividadId;
  final String actividadNombre;
  final List<String> documentosRequeridos;

  ActividadDocumentos({
    required this.actividadId,
    required this.actividadNombre,
    required this.documentosRequeridos,
  });

  factory ActividadDocumentos.fromJson(Map<String, dynamic> json) {
    return ActividadDocumentos(
      // M1: null-safe (mismo motivo que en Politica.fromJson).
      actividadId: json['actividadId']?.toString() ?? '',
      actividadNombre: json['actividadNombre']?.toString() ?? '',
      documentosRequeridos: List<String>.from(json['documentosRequeridos'] as List? ?? []),
    );
  }
}

/// Respuesta con lista de políticas
class ListaPoliticas {
  final List<Politica> politicas;
  final int total;

  ListaPoliticas({
    required this.politicas,
    required this.total,
  });

  factory ListaPoliticas.fromJson(Map<String, dynamic> json) {
    return ListaPoliticas(
      politicas: (json['politicas'] as List?)
          ?.map((e) => Politica.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      total: json['total'] as int? ?? 0,
    );
  }
}
