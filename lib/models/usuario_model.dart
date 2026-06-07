/// Modelo de Usuario
class Usuario {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String dni;
  final String direccion;
  final String rol;
  final bool activo;

  Usuario({
    required this.id,
    required this.nombre,
    this.apellido = '',
    required this.email,
    this.telefono = '',
    this.dni = '',
    this.direccion = '',
    required this.rol,
    required this.activo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String? ?? '',
      email: json['email'] as String,
      telefono: json['telefono'] as String? ?? '',
      dni: json['dni'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      rol: json['rol'] as String? ?? 'cliente',
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'dni': dni,
      'direccion': direccion,
      'rol': rol,
      'activo': activo,
    };
  }

  // CopyWith para crear copias con propiedades modificadas
  Usuario copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? email,
    String? telefono,
    String? dni,
    String? direccion,
    String? rol,
    bool? activo,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      dni: dni ?? this.dni,
      direccion: direccion ?? this.direccion,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
    );
  }
}
