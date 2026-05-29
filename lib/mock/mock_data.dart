/// Credenciales reales del seed del backend (UsuarioSeeder.java).
/// Las usa el botón "Auto-completar" de la pantalla de login.
class MockData {
  /// Cliente Juan Perez — el más común para demos
  static const Map<String, dynamic> clienteTest = {
    'email': 'cliente@cre.bo',
    'password': 'cliente12345',
    'nombre': 'Juan',
    'apellido': 'Perez',
    'tipo': 'cliente',
    'rol': 'Cliente',
  };

  /// Funcionario TEC Carlos Lima
  static const Map<String, dynamic> funcionarioTest = {
    'email': 'funcionario@cre.bo',
    'password': 'func12345',
    'nombre': 'Carlos',
    'apellido': 'Lima',
    'tipo': 'funcionario',
    'rol': 'Funcionario',
  };

  /// Administrador del sistema
  static const Map<String, dynamic> administradorTest = {
    'email': 'admin@cre.bo',
    'password': 'admin12345',
    'nombre': 'Admin',
    'apellido': 'Sistema',
    'tipo': 'administrador',
    'rol': 'Administrador',
  };
}
