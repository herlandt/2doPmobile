import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          // C3 — Campana de notificaciones
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificaciones',
            onPressed: () => Get.toNamed(AppRoutes.notificaciones),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Get.defaultDialog(
                title: 'Cerrar Sesión',
                middleText: '¿Deseas cerrar sesión?',
                textConfirm: 'Sí',
                textCancel: 'No',
                onConfirm: () {
                  authService.logout();
                  Get.offNamed('/login');
                },
              );
            },
          ),
        ],
      ),

      // CU-31: el FAB del agente IA ahora es global (definido en main.dart),
      // por lo que aparece en todas las pantallas autenticadas, no solo aquí.

      body: Obx(
        () {
          final usuario = authService.usuarioActual.value;

          if (usuario == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bienvenida
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Bienvenido!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          usuario.nombre,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Acciones Ciclo 1 ─────────────────────────────────────
                Text(
                  'Mis Trámites',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.misTramites),
                  icon: const Icon(Icons.assignment),
                  label: const Text('Ver Mis Trámites'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.tramites),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Explorar Trámites'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Acciones adicionales ─────────────────────────────────
                Text(
                  'Nuevas Funciones',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                // CU-40 — Iniciar trámite con IA (destacado).
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.iniciarTramiteIa),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Iniciar trámite con IA'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.catalogoTramites),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Iniciar Nuevo Trámite'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.tramitesObservados),
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Trámites con Observaciones'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Acciones de notificaciones ───────────────────────────
                Text(
                  'Notificaciones',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.notificaciones),
                  icon: const Icon(Icons.notifications),
                  label: const Text('Ver Notificaciones'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Información de perfil
                Text(
                  'Información de Perfil',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(context, Icons.email, 'Correo', usuario.email),
                _buildInfoCard(context, Icons.person, 'Rol', usuario.rol),
                _buildInfoCard(
                  context,
                  Icons.verified_user,
                  'Estado',
                  usuario.activo ? 'Activo' : 'Inactivo',
                ),
                const SizedBox(height: 80), // espacio para el FAB
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
