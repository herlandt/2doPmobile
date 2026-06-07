/// Modelo para solicitud de login
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Modelo para respuesta de login
class LoginResponse {
  final String token;
  final String tipoToken;
  final String email;
  final String nombre;
  final String tipo; // "cliente" | "funcionario" | "administrador"

  LoginResponse({
    required this.token,
    required this.tipoToken,
    required this.email,
    required this.nombre,
    required this.tipo,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      tipoToken: json['tipoToken'] as String? ?? 'Bearer',
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'tipoToken': tipoToken,
      'email': email,
      'nombre': nombre,
      'tipo': tipo,
    };
  }
}

/// Modelo para solicitud de registro
class RegisterRequest {
  final String nombre;
  final String apellido;
  final String email;
  final String password;
  final String passwordConfirm;
  final String telefono;
  final String dni;
  final String direccion;

  RegisterRequest({
    required this.nombre,
    this.apellido = '',
    required this.email,
    required this.password,
    required this.passwordConfirm,
    this.telefono = '',
    this.dni = '',
    this.direccion = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'password': password,
      'telefono': telefono,
      'dni': dni,
      'direccion': direccion,
    };
  }
}

/// Modelo para respuesta de registro
class RegisterResponse {
  final String message;
  final String usuarioId;

  RegisterResponse({
    required this.message,
    required this.usuarioId,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'] as String,
      usuarioId: json['usuarioId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'usuarioId': usuarioId,
    };
  }
}
