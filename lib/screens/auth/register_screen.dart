import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/auth_model.dart';
import '../../services/auth_service.dart';
import '../../mock/mock_data.dart';
import '../../utils/error_messages.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final authService = Get.find<AuthService>();

  // Controladores de texto
  late TextEditingController _nameController;
  late TextEditingController _apellidoController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _dniController;
  late TextEditingController _direccionController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _apellidoController = TextEditingController();
    _emailController = TextEditingController();
    _telefonoController = TextEditingController();
    _dniController = TextEditingController();
    _direccionController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _dniController.dispose();
    _direccionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validar nombre
  String? _validateName(String? value) {
    if (value?.isEmpty ?? true) {
      return 'El nombre es requerido';
    }
    if ((value?.length ?? 0) < 3) {
      return 'Mínimo 3 caracteres';
    }
    return null;
  }

  /// Validar email
  String? _validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'El email es requerido';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
      return 'Email inválido';
    }
    return null;
  }

  /// Validar contraseña
  String? _validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'La contraseña es requerida';
    }
    if ((value?.length ?? 0) < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }

  /// Validar confirmación de contraseña
  String? _validateConfirmPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Debes confirmar la contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  /// Llenar datos de prueba
  void _fillMockData() {
    _nameController.text = MockData.clienteTest['nombre'];
    _emailController.text = MockData.clienteTest['email'];
    _passwordController.text = MockData.clienteTest['password'];
    _confirmPasswordController.text = MockData.clienteTest['password'];
  }

  /// Realizar registro
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final request = RegisterRequest(
        nombre: _nameController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirm: _confirmPasswordController.text,
        telefono: _telefonoController.text.trim(),
        dni: _dniController.text.trim(),
        direccion: _direccionController.text.trim(),
      );

      await authService.registrar(request);

      setState(() {
        _successMessage = 'Registro exitoso. Redirigiendo a login...';
      });

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Get.offNamed('/login');
      }
    } catch (e) {
      setState(() {
        _errorMessage = mensajeAmigable(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Logo
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded,
                          size: 38, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Título
                  const Text(
                    'Nueva Cuenta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D1B23),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Crea una nueva cuenta para acceder',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textoSuave),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Tarjeta central con el formulario
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mensaje de error
                        if (_errorMessage != null) ...[
                          _MensajeBanner(
                            mensaje: _errorMessage!,
                            color: AppColors.peligro,
                            icon: Icons.error_outline,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Mensaje de éxito
                        if (_successMessage != null) ...[
                          _MensajeBanner(
                            mensaje: _successMessage!,
                            color: AppColors.exito,
                            icon: Icons.check_circle_outline,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Nombre field
                        TextFormField(
                          controller: _nameController,
                          enabled: !_isLoading,
                          decoration: const InputDecoration(
                            labelText: 'Nombre Completo',
                            hintText: 'Tu nombre',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: _validateName,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Apellido field
                        TextFormField(
                          controller: _apellidoController,
                          enabled: !_isLoading,
                          decoration: const InputDecoration(
                            labelText: 'Apellido',
                            hintText: 'Tu apellido',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo Electrónico',
                            hintText: 'tu@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Teléfono field
                        TextFormField(
                          controller: _telefonoController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            hintText: 'Ej: 70012345',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // DNI / CI field
                        TextFormField(
                          controller: _dniController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'DNI / CI',
                            hintText: 'Ej: 1234567',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Dirección field
                        TextFormField(
                          controller: _direccionController,
                          enabled: !_isLoading,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            hintText: 'Tu domicilio',
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Confirm password field
                        TextFormField(
                          controller: _confirmPasswordController,
                          enabled: !_isLoading,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar Contraseña',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: _validateConfirmPassword,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Register button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text('Registrarse'),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Botón de datos de prueba (solo en desarrollo)
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _fillMockData,
                          icon: const Icon(Icons.autorenew),
                          label: const Text('Usar datos de prueba'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          '(Cliente: cliente@cre.bo)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textoSuave),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿Ya tienes cuenta? ',
                          style: TextStyle(color: AppColors.textoSuave)),
                      GestureDetector(
                        onTap: _isLoading ? null : () => Get.toNamed('/login'),
                        child: const Text(
                          'Inicia sesión aquí',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner de mensaje (error/éxito) con color semántico.
class _MensajeBanner extends StatelessWidget {
  final String mensaje;
  final Color color;
  final IconData icon;
  const _MensajeBanner({
    required this.mensaje,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(mensaje, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
