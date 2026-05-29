/// Modelo de Departamento
class Departamento {
  final String id;
  final String nombre;
  final String correoContacto;
  final bool activo;

  Departamento({
    required this.id,
    required this.nombre,
    required this.correoContacto,
    required this.activo,
  });

  factory Departamento.fromJson(Map<String, dynamic> json) {
    return Departamento(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      correoContacto: json['correoContacto'] as String,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correoContacto': correoContacto,
      'activo': activo,
    };
  }
}
