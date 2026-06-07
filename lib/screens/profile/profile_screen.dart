// Guía 5F - Pantalla de Perfil de Usuario (ver / editar / guardar real)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../utils/error_messages.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AuthService authService;

  // Controladores persistentes para los campos editables.
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _dniController = TextEditingController();
  final _direccionController = TextEditingController();

  bool editando = false;
  bool guardando = false;
  String? mensajeExito;
  String? mensajeError;

  @override
  void initState() {
    super.initState();
    authService = Get.find<AuthService>();
    _cargarDesdePerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _dniController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  /// Vuelca los datos del usuario actual en los controladores.
  void _cargarDesdePerfil() {
    final u = authService.usuarioActual.value;
    if (u == null) return;
    _nombreController.text = u.nombre;
    _apellidoController.text = u.apellido;
    _telefonoController.text = u.telefono;
    _dniController.text = u.dni;
    _direccionController.text = u.direccion;
  }

  void _activarEdicion() {
    _cargarDesdePerfil();
    setState(() {
      editando = true;
      mensajeError = null;
      mensajeExito = null;
    });
  }

  void _cancelarEdicion() {
    _cargarDesdePerfil(); // descarta cambios no guardados
    setState(() {
      editando = false;
      mensajeError = null;
      mensajeExito = null;
    });
  }

  Future<void> _guardarCambios() async {
    if (_nombreController.text.trim().isEmpty) {
      setState(() => mensajeError = 'El nombre es requerido');
      return;
    }

    setState(() {
      guardando = true;
      mensajeError = null;
      mensajeExito = null;
    });

    try {
      await authService.actualizarPerfil(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        dni: _dniController.text.trim(),
        direccion: _direccionController.text.trim(),
      );

      _cargarDesdePerfil(); // refleja la respuesta del backend
      setState(() {
        editando = false;
        mensajeExito = '✅ Perfil actualizado correctamente';
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => mensajeExito = null);
      });
    } catch (e) {
      setState(() => mensajeError = mensajeAmigable(e));
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  /// Iniciales del usuario para el avatar (nombre + apellido).
  String _iniciales(String nombre, String apellido) {
    final n = nombre.trim();
    final a = apellido.trim();
    final i1 = n.isNotEmpty ? n[0] : '';
    final i2 = a.isNotEmpty ? a[0] : '';
    final r = (i1 + i2).toUpperCase();
    return r.isEmpty ? '?' : r;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: Obx(
        () {
          final usuario = authService.usuarioActual.value;

          if (usuario == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera: avatar (iniciales) + nombre
                Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _iniciales(usuario.nombre, usuario.apellido),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${usuario.nombre} ${usuario.apellido}'.trim(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D1B23),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      usuario.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textoSuave),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    EstadoChip(
                      usuario.activo ? 'Activo' : 'Inactivo',
                      color:
                          usuario.activo ? AppColors.exito : AppColors.peligro,
                      icon: usuario.activo
                          ? Icons.check_circle
                          : Icons.cancel,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Mensajes
                if (mensajeExito != null) ...[
                  _MensajeBanner(
                    mensaje: mensajeExito!,
                    color: AppColors.exito,
                    icon: Icons.check_circle,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (mensajeError != null) ...[
                  _MensajeBanner(
                    mensaje: mensajeError!,
                    color: AppColors.peligro,
                    icon: Icons.error_outline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Información de Perfil
                const SectionHeader('Información Personal'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre (editable)
                      _buildEditableField(
                        label: 'Nombre',
                        controller: _nombreController,
                        editable: editando,
                        icon: Icons.person,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Apellido (editable)
                      _buildEditableField(
                        label: 'Apellido',
                        controller: _apellidoController,
                        editable: editando,
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Email (NO editable)
                      _buildReadOnlyField(
                        label: 'Correo Electrónico',
                        value: usuario.email,
                        icon: Icons.email,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Teléfono (editable)
                      _buildEditableField(
                        label: 'Teléfono',
                        controller: _telefonoController,
                        editable: editando,
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // DNI / CI (editable)
                      _buildEditableField(
                        label: 'DNI / CI',
                        controller: _dniController,
                        editable: editando,
                        icon: Icons.badge,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Dirección (editable)
                      _buildEditableField(
                        label: 'Dirección',
                        controller: _direccionController,
                        editable: editando,
                        icon: Icons.home,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Rol (NO editable)
                      _buildReadOnlyField(
                        label: 'Rol',
                        value: usuario.rol,
                        icon: Icons.verified_user,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Botones
                if (!editando) ...[
                  ElevatedButton.icon(
                    onPressed: _activarEdicion,
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Perfil'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: guardando ? null : _guardarCambios,
                    icon: guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(guardando ? 'Guardando...' : 'Guardar Cambios'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: guardando ? null : _cancelarEdicion,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),

                // Sección de Seguridad
                const SectionHeader('Seguridad'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Función disponible próximamente'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.lock),
                        label: const Text('Cambiar Contraseña'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Botón de Logout
                ElevatedButton.icon(
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'Cerrar Sesión',
                      middleText: '¿Estás seguro de que deseas cerrar sesión?',
                      textConfirm: 'Sí',
                      textCancel: 'No',
                      confirmTextColor: Colors.white,
                      onConfirm: () {
                        authService.logout();
                        Get.offNamed('/login');
                      },
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.peligro,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Footer Info
                const Text(
                  '© 2026 Sistema de Gestión de Trámites\nVersión Beta',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textoSuave, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Campo editable: cuando [editable] es true, el usuario puede escribir.
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool editable,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textoSuave,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          readOnly: !editable,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: !editable ? AppColors.fondo : Colors.white,
          ),
        ),
      ],
    );
  }

  /// Campo de solo lectura (nunca editable, p. ej. email/rol/estado).
  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textoSuave,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.fondo,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.borde),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textoSuave),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ],
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
