// Guía 3F - Modelos para Formularios Dinámicos

class CampoFormulario {
  final String id;
  final String nombre;
  final String tipo; // text, email, tel, date, textarea, select, file, checkbox
  final String etiqueta;
  final String? placeholder;
  final bool requerido;
  final Map<String, dynamic>? validaciones; // minLength, maxLength, pattern
  final List<OpcionFormulario>? opciones; // Para select

  CampoFormulario({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.etiqueta,
    this.placeholder,
    required this.requerido,
    this.validaciones,
    this.opciones,
  });

  factory CampoFormulario.fromJson(Map<String, dynamic> json) {
    return CampoFormulario(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? 'text',
      etiqueta: json['etiqueta'] ?? '',
      placeholder: json['placeholder'],
      requerido: json['requerido'] ?? false,
      validaciones: json['validaciones'],
      opciones: json['opciones'] != null
          ? List<OpcionFormulario>.from(
              (json['opciones'] as List).map((o) => OpcionFormulario.fromJson(o)))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'tipo': tipo,
        'etiqueta': etiqueta,
        'placeholder': placeholder,
        'requerido': requerido,
        'validaciones': validaciones,
        'opciones': opciones?.map((o) => o.toJson()).toList(),
      };
}

class OpcionFormulario {
  final String label;
  final String value;

  OpcionFormulario({required this.label, required this.value});

  factory OpcionFormulario.fromJson(Map<String, dynamic> json) {
    return OpcionFormulario(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
      };
}

class FormularioPlantilla {
  final String id;
  final String nombre;
  final String? descripcion;
  final List<CampoFormulario> campos;
  final int version;

  FormularioPlantilla({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.campos,
    required this.version,
  });

  factory FormularioPlantilla.fromJson(Map<String, dynamic> json) {
    return FormularioPlantilla(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      campos: json['campos'] != null
          ? List<CampoFormulario>.from(
              (json['campos'] as List).map((c) => CampoFormulario.fromJson(c)))
          : [],
      version: json['version'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'campos': campos.map((c) => c.toJson()).toList(),
        'version': version,
      };

  /// Formulario plantilla básico para C1
  static FormularioPlantilla crearPlantillaBasica(String politicaId) {
    return FormularioPlantilla(
      id: 'form-$politicaId',
      nombre: 'Solicitud de Trámite',
      descripcion: 'Por favor completa todos los campos requeridos',
      version: 1,
      campos: [
        CampoFormulario(
          id: 'nombre_completo',
          nombre: 'nombre_completo',
          tipo: 'text',
          etiqueta: 'Nombre Completo',
          placeholder: 'Ej: Juan Pérez',
          requerido: true,
          validaciones: {'minLength': 3, 'maxLength': 100},
        ),
        CampoFormulario(
          id: 'cedula',
          nombre: 'cedula',
          tipo: 'text',
          etiqueta: 'Número de Cédula',
          placeholder: 'Ej: 1234567890',
          requerido: true,
          validaciones: {'pattern': r'^[0-9]{7,10}$'},
        ),
        CampoFormulario(
          id: 'email',
          nombre: 'email',
          tipo: 'email',
          etiqueta: 'Correo Electrónico',
          placeholder: 'Ej: correo@ejemplo.com',
          requerido: true,
        ),
        CampoFormulario(
          id: 'telefono',
          nombre: 'telefono',
          tipo: 'tel',
          etiqueta: 'Teléfono de Contacto',
          placeholder: 'Ej: 3001234567',
          requerido: true,
        ),
        CampoFormulario(
          id: 'descripcion_solicitud',
          nombre: 'descripcion_solicitud',
          tipo: 'textarea',
          etiqueta: 'Descripción de la Solicitud',
          placeholder: 'Describe detalladamente qué necesitas...',
          requerido: true,
          validaciones: {'minLength': 10, 'maxLength': 1000},
        ),
      ],
    );
  }
}

class SolicitudTramite {
  final String politicaId;
  final Map<String, dynamic> datos;
  final List<String>? archivos; // Nombres de archivos en C2

  SolicitudTramite({
    required this.politicaId,
    required this.datos,
    this.archivos,
  });

  factory SolicitudTramite.fromJson(Map<String, dynamic> json) {
    return SolicitudTramite(
      politicaId: json['politicaId'] ?? '',
      datos: json['datos'] ?? {},
      archivos: json['archivos'] != null ? List<String>.from(json['archivos']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'politicaId': politicaId,
        'datos': datos,
        if (archivos != null) 'archivos': archivos,
      };
}

class RespuestaTramite {
  final String tramiteId;
  final String codigo;
  final String estado;
  final String mensaje;
  final String? fechaCreacion;

  RespuestaTramite({
    required this.tramiteId,
    required this.codigo,
    required this.estado,
    required this.mensaje,
    this.fechaCreacion,
  });

  factory RespuestaTramite.fromJson(Map<String, dynamic> json) {
    return RespuestaTramite(
      tramiteId: json['tramiteId'] ?? json['id'] ?? '',
      codigo: json['codigo'] ?? '',
      estado: json['estado'] ?? 'pendiente',
      mensaje: json['mensaje'] ?? 'Trámite creado exitosamente',
      fechaCreacion: json['fechaCreacion'] ?? json['fecha_creacion'],
    );
  }

  Map<String, dynamic> toJson() => {
        'tramiteId': tramiteId,
        'codigo': codigo,
        'estado': estado,
        'mensaje': mensaje,
        'fechaCreacion': fechaCreacion,
      };
}
