/// Modelo del flujo completo de un trámite: todos los nodos del camino con
/// su estado en ESTE trámite específico + documentos requeridos por actividad.

class DocumentoRequerido {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? proveedor; // 'CLIENTE' | 'FUNCIONARIO'
  final bool obligatorio;

  DocumentoRequerido({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.proveedor,
    this.obligatorio = false,
  });

  /// ¿Es un requisito que debe aportar el CLIENTE? (tolerante a mayúsculas)
  bool get esCliente => (proveedor ?? '').toUpperCase() == 'CLIENTE';

  factory DocumentoRequerido.fromJson(Map<String, dynamic> json) {
    return DocumentoRequerido(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      proveedor: json['proveedor']?.toString(),
      obligatorio: json['obligatorio'] == true,
    );
  }
}

class FlujoNodo {
  final String nodoId;
  final String nombre;
  final String tipo; // inicio | actividad | decision | fork | join | fin
  final int orden;
  final String? departamentoCodigo;
  final String? departamentoNombre;
  final String? swimlane;

  // Datos del nodo de decisión (solo si tipo=decision)
  final String? pregunta;
  final List<Map<String, dynamic>> opciones; // [{valor, etiqueta, destinoNombre}]

  // Datos de la actividad (solo si tipo=actividad)
  final String? actividadId;
  final String? actividadNombre;
  final String? actividadDescripcion;
  final int? slaHoras;
  final List<String> salidasPosibles;
  final List<DocumentoRequerido> documentosRequeridos;

  // Estado en este trámite específico
  final String? estadoSeccion; // completada | en_curso | bloqueada | observado
  final String? observacion; // último motivo/observación del historial en este nodo
  // CASO OBSERVADO: ids de DocumentoArchivo que el funcionario marcó como "mal"
  // y que el cliente debe corregir (vacío cuando no hay observación específica).
  final List<String> documentosObservados;
  final bool esActual;
  final String? funcionarioId;
  final String? funcionarioNombre;
  final String? fechaAsignacion;
  final String? fechaCompletado;

  FlujoNodo({
    required this.nodoId,
    required this.nombre,
    required this.tipo,
    required this.orden,
    this.departamentoCodigo,
    this.departamentoNombre,
    this.swimlane,
    this.pregunta,
    this.opciones = const [],
    this.actividadId,
    this.actividadNombre,
    this.actividadDescripcion,
    this.slaHoras,
    this.salidasPosibles = const [],
    this.documentosRequeridos = const [],
    this.estadoSeccion,
    this.observacion,
    this.documentosObservados = const [],
    this.esActual = false,
    this.funcionarioId,
    this.funcionarioNombre,
    this.fechaAsignacion,
    this.fechaCompletado,
  });

  factory FlujoNodo.fromJson(Map<String, dynamic> json) {
    return FlujoNodo(
      nodoId: json['nodoId'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? 'actividad',
      orden: (json['orden'] as num?)?.toInt() ?? 0,
      departamentoCodigo: json['departamentoCodigo'],
      departamentoNombre: json['departamentoNombre'],
      swimlane: json['swimlane'],
      pregunta: json['pregunta'],
      opciones: json['opciones'] != null
          ? List<Map<String, dynamic>>.from(
              (json['opciones'] as List)
                  .map((o) => Map<String, dynamic>.from(o as Map)),
            )
          : const [],
      actividadId: json['actividadId'],
      actividadNombre: json['actividadNombre'],
      actividadDescripcion: json['actividadDescripcion'],
      slaHoras: (json['slaHoras'] as num?)?.toInt(),
      salidasPosibles: json['salidasPosibles'] != null
          ? List<String>.from(json['salidasPosibles'])
          : const [],
      documentosRequeridos: json['documentosRequeridos'] != null
          ? List<DocumentoRequerido>.from(
              (json['documentosRequeridos'] as List)
                  .map((d) => DocumentoRequerido.fromJson(d)),
            )
          : const [],
      estadoSeccion: json['estadoSeccion'],
      observacion: json['observacion']?.toString(),
      documentosObservados:
          (json['documentosObservados'] as List?)?.cast<String>() ?? const [],
      esActual: json['esActual'] == true,
      funcionarioId: json['funcionarioId'],
      funcionarioNombre: json['funcionarioNombre'],
      fechaAsignacion: json['fechaAsignacion']?.toString(),
      fechaCompletado: json['fechaCompletado']?.toString(),
    );
  }
}

class FlujoCompleto {
  final String tramiteId;
  final String codigo;
  final String? politicaNombre;
  final String? nodoActualId;
  final List<FlujoNodo> nodos;

  FlujoCompleto({
    required this.tramiteId,
    required this.codigo,
    this.politicaNombre,
    this.nodoActualId,
    required this.nodos,
  });

  factory FlujoCompleto.fromJson(Map<String, dynamic> json) {
    return FlujoCompleto(
      tramiteId: json['tramiteId'] ?? '',
      codigo: json['codigo'] ?? '',
      politicaNombre: json['politicaNombre'],
      nodoActualId: json['nodoActualId'],
      nodos: json['nodos'] != null
          ? List<FlujoNodo>.from(
              (json['nodos'] as List).map((n) => FlujoNodo.fromJson(n)),
            )
          : const [],
    );
  }
}
