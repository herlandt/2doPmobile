// Guía 4F - Modelo para Resumen de Trámites

class TramiteResumen {
  final String id;
  final String codigo;
  final String politicaNombre;
  final String estado; // borrador, activo, completado, archivado, rechazado
  final String nodoActualNombre;
  final String fechaInicio;
  final String? fechaCierreReal;
  final int progreso; // 0-100
  // Estado de la sección del nodo actual (ej: "Pendiente de documentos").
  // Lo usa la UX para distinguir CASO A "compuerta" de CASO B "observado".
  final String? estadoSeccion;

  TramiteResumen({
    required this.id,
    required this.codigo,
    required this.politicaNombre,
    required this.estado,
    required this.nodoActualNombre,
    required this.fechaInicio,
    this.fechaCierreReal,
    required this.progreso,
    this.estadoSeccion,
  });

  /// CASO B: el trámite fue devuelto por algo MAL (estado GLOBAL).
  bool get esObservado {
    final e = estado.toLowerCase();
    return e.contains('observ') || e.contains('devuelt');
  }

  /// CASO A "COMPUERTA" (positivo): el trámite AVANZÓ y pide documentos NUEVOS
  /// de la siguiente actividad. estadoSeccion contiene 'pendiente'+'documento'
  /// y NO está observado globalmente.
  bool get esCompuerta {
    final e = (estadoSeccion ?? '').toLowerCase();
    return e.contains('pendiente') && e.contains('documento') && !esObservado;
  }

  factory TramiteResumen.fromJson(Map<String, dynamic> json) {
    final progresoRaw = json['progreso'];
    final progreso = progresoRaw is num
        ? progresoRaw.toInt()
        : int.tryParse(progresoRaw?.toString() ?? '') ?? 0;

    return TramiteResumen(
      id: json['id'] ?? json['tramiteId'] ?? '',
      codigo: json['codigo'] ?? '',
      politicaNombre: json['politicaNombre'] ?? json['politica_nombre'] ?? '',
      // El backend C2 devuelve 'estadoActual' (ej: 'Observado'); C1 devuelve 'estado'
      estado: json['estadoActual'] ?? json['estado'] ?? 'activo',
      nodoActualNombre:
          json['nodoActualNombre'] ?? json['nodo_actual_nombre'] ?? '',
      fechaInicio: json['fechaInicio'] ?? json['fecha_inicio'] ?? '',
      fechaCierreReal: json['fechaCierreReal'] ?? json['fecha_cierre_real'],
      progreso: progreso,
      estadoSeccion: json['estadoSeccion'] ?? json['estado_seccion'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'codigo': codigo,
    'politicaNombre': politicaNombre,
    'estado': estado,
    'nodoActualNombre': nodoActualNombre,
    'fechaInicio': fechaInicio,
    'fechaCierreReal': fechaCierreReal,
    'progreso': progreso,
    'estadoSeccion': estadoSeccion,
  };
}
