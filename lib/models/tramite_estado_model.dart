// Guía 4F - Modelos para Estado Detallado de Trámites

class NodoActual {
  final String id;
  final String nombre;
  final String tipo; // inicio, actividad, decision, fork, join, fin
  final String? departamento;

  NodoActual({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.departamento,
  });

  factory NodoActual.fromJson(Map<String, dynamic> json) {
    return NodoActual(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? 'actividad',
      departamento: json['departamento'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'tipo': tipo,
    'departamento': departamento,
  };
}

class SeccionEstado {
  final String id;
  final String nombre;
  final String estado; // bloqueada, en_curso, completada
  final String? actividad;
  final String? departamento;
  final String? fechaInicio;
  final String? fechaCompletacion;

  SeccionEstado({
    required this.id,
    required this.nombre,
    required this.estado,
    this.actividad,
    this.departamento,
    this.fechaInicio,
    this.fechaCompletacion,
  });

  factory SeccionEstado.fromJson(Map<String, dynamic> json) {
    return SeccionEstado(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      estado: json['estado'] ?? 'bloqueada',
      actividad: json['actividad'],
      departamento: json['departamento'],
      fechaInicio: json['fechaInicio'] ?? json['fecha_inicio'],
      fechaCompletacion:
          json['fechaCompletacion'] ?? json['fecha_completacion'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'estado': estado,
    'actividad': actividad,
    'departamento': departamento,
    'fechaInicio': fechaInicio,
    'fechaCompletacion': fechaCompletacion,
  };
}

class EventoHistorico {
  final String id;
  final String
  tipo; // creacion, cambio_estado, aprobacion, rechazo, completacion
  final String descripcion;
  final String? usuario;
  final String? departamento;
  final String fecha;
  final Map<String, dynamic>? detalles;

  EventoHistorico({
    required this.id,
    required this.tipo,
    required this.descripcion,
    this.usuario,
    this.departamento,
    required this.fecha,
    this.detalles,
  });

  factory EventoHistorico.fromJson(Map<String, dynamic> json) {
    return EventoHistorico(
      id: json['id'] ?? '',
      tipo: json['tipo'] ?? 'cambio_estado',
      descripcion: json['descripcion'] ?? '',
      usuario: json['usuario'],
      departamento: json['departamento'],
      fecha: json['fecha'] ?? '',
      detalles: json['detalles'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo,
    'descripcion': descripcion,
    'usuario': usuario,
    'departamento': departamento,
    'fecha': fecha,
    'detalles': detalles,
  };
}

class ExpedienteInfo {
  final String id;
  final List<SeccionEstado> secciones;

  ExpedienteInfo({required this.id, required this.secciones});

  factory ExpedienteInfo.fromJson(Map<String, dynamic> json) {
    return ExpedienteInfo(
      id: json['id'] ?? '',
      secciones: json['secciones'] != null
          ? List<SeccionEstado>.from(
              (json['secciones'] as List).map((s) => SeccionEstado.fromJson(s)),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'secciones': secciones.map((s) => s.toJson()).toList(),
  };
}

class EstadoTramite {
  final String tramiteId;
  final String codigo;
  final String estado;
  final NodoActual nodoActual;
  final ExpedienteInfo expediente;
  final List<EventoHistorico> historial;
  final int progreso;

  EstadoTramite({
    required this.tramiteId,
    required this.codigo,
    required this.estado,
    required this.nodoActual,
    required this.expediente,
    required this.historial,
    required this.progreso,
  });

  factory EstadoTramite.fromJson(Map<String, dynamic> json) {
    final progresoRaw = json['progreso'];
    final progreso = progresoRaw is num
        ? progresoRaw.toInt()
        : int.tryParse(progresoRaw?.toString() ?? '') ?? 0;

    return EstadoTramite(
      tramiteId: json['tramiteId'] ?? json['id'] ?? '',
      codigo: json['codigo'] ?? '',
      estado: json['estado'] ?? 'activo',
      nodoActual: json['nodoActual'] != null
          ? NodoActual.fromJson(json['nodoActual'])
          : NodoActual(id: '', nombre: 'Desconocida', tipo: 'actividad'),
      expediente: json['expediente'] != null
          ? ExpedienteInfo.fromJson(json['expediente'])
          : ExpedienteInfo(id: '', secciones: []),
      historial: json['historial'] != null
          ? List<EventoHistorico>.from(
              (json['historial'] as List).map(
                (h) => EventoHistorico.fromJson(h),
              ),
            )
          : [],
      progreso: progreso,
    );
  }

  Map<String, dynamic> toJson() => {
    'tramiteId': tramiteId,
    'codigo': codigo,
    'estado': estado,
    'nodoActual': nodoActual.toJson(),
    'expediente': expediente.toJson(),
    'historial': historial.map((h) => h.toJson()).toList(),
    'progreso': progreso,
  };
}
