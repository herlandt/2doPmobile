
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/auth_model.dart';
import '../../services/auth_service.dart';
import '../../mock/mock_data.dart';
import '../../utils/error_messages.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final authService = Get.find<AuthService>();

  // Controladores de texto
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  /// Llenar datos de prueba
  void _fillMockData() {
    _emailController.text = MockData.clienteTest['email'];
    _passwordController.text = MockData.clienteTest['password'];
  }

  /// Realizar login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ Formulario inválido');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print('🔐 Login Intent:');
      print('   Email: $email');
      print('   Password: [OCULTA]');

      final request = LoginRequest(
        email: email,
        password: password,
      );

      print('📤 Enviando solicitud de login');

      final response = await authService.login(request);

      print('✅ Login exitoso');
      print('   Usuario: ${response.nombre}');

      if (mounted) {
        Get.offNamed('/home');
      }
    } catch (e) {
      print('❌ Error en login: $e');
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // Logo
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: const Icon(Icons.bolt_rounded,
                          size: 40, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Título
                  const Text(
                    'Bienvenido',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D1B23),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Inicia sesión con tu cuenta',
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
                          _ErrorBanner(mensaje: _errorMessage!),
                          const SizedBox(height: AppSpacing.md),
                        ],

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

                        // Login button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
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
                              : const Text('Ingresar'),
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

                  // Registro link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes cuenta? ',
                          style: TextStyle(color: AppColors.textoSuave)),
                      GestureDetector(
                        onTap:
                            _isLoading ? null : () => Get.toNamed('/register'),
                        child: const Text(
                          'Regístrate aquí',
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

/// Banner de error con color semántico de peligro.
class _ErrorBanner extends StatelessWidget {
  final String mensaje;
  const _ErrorBanner({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: AppColors.peligro.withOpacity(0.08),
        border: Border.all(color: AppColors.peligro.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.peligro, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(color: AppColors.peligro),
            ),
          ),
        ],
      ),
    );
  }
}
