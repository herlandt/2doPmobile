// Guía 3F - Modelo de Expediente Digital

class SeccionExpediente {
  final String id;
  final String nombre;
  final String estado; // bloqueada, en_curso, completada
  final Map<String, dynamic>? campos;

  SeccionExpediente({
    required this.id,
    required this.nombre,
    required this.estado,
    this.campos,
  });

  factory SeccionExpediente.fromJson(Map<String, dynamic> json) {
    return SeccionExpediente(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      estado: json['estado'] ?? 'bloqueada',
      campos: json['campos'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'estado': estado,
        'campos': campos,
      };
}

class ExpedienteDigital {
  final String id;
  final String codigo;
  final String clienteId;
  final String politicaId;
  final String tramiteId;
  final List<SeccionExpediente> secciones;
  final String estado;
  final String fechaCreacion;

  ExpedienteDigital({
    required this.id,
    required this.codigo,
    required this.clienteId,
    required this.politicaId,
    required this.tramiteId,
    required this.secciones,
    required this.estado,
    required this.fechaCreacion,
  });

  factory ExpedienteDigital.fromJson(Map<String, dynamic> json) {
    return ExpedienteDigital(
      id: json['id'] ?? '',
      codigo: json['codigo'] ?? '',
      clienteId: json['clienteId'] ?? '',
      politicaId: json['politicaId'] ?? '',
      tramiteId: json['tramiteId'] ?? '',
      secciones: json['secciones'] != null
          ? List<SeccionExpediente>.from(
              (json['secciones'] as List).map((s) => SeccionExpediente.fromJson(s)))
          : [],
      estado: json['estado'] ?? 'activo',
      fechaCreacion: json['fechaCreacion'] ?? json['fecha_creacion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'clienteId': clienteId,
        'politicaId': politicaId,
        'tramiteId': tramiteId,
        'secciones': secciones.map((s) => s.toJson()).toList(),
        'estado': estado,
        'fechaCreacion': fechaCreacion,
      };
}
