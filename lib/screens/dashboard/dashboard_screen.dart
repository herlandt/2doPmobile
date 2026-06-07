// Guía 5F - Dashboard Principal

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/tramite_resumen_model.dart';
import '../../services/auth_service.dart';
import '../../services/tramites_seguimiento_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late AuthService authService;
  late TramitesSeguimientoService tramitesSeguimientoService;

  List<TramiteResumen> tramitesRecientes = [];
  Map<String, int> estadisticas = {
    'total': 0,
    'en_progreso': 0,
    'completado': 0,
    'archivado': 0,
  };

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    authService = Get.find<AuthService>();
    tramitesSeguimientoService = Get.find<TramitesSeguimientoService>();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      print('📊 Cargando datos del dashboard...');
      await tramitesSeguimientoService.obtenerMisTramites();

      final tramites = tramitesSeguimientoService.misTramites;

      // Tomar los últimos 5 trámites
      tramitesRecientes = tramites.length > 5 ? tramites.sublist(0, 5) : tramites;

      // Calcular estadísticas
      estadisticas['total'] = tramites.length;
      estadisticas['en_progreso'] = tramites.where((t) => t.estado == 'activo' || t.estado == 'en_progreso').length;
      estadisticas['completado'] =
          tramites.where((t) => t.estado == 'completado').length;
      estadisticas['archivado'] =
          tramites.where((t) => t.estado == 'archivado').length;

      print('✅ Dashboard cargado: ${tramites.length} trámites');

      setState(() => cargando = false);
    } catch (e) {
      print('❌ Error cargando dashboard: $e');
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = authService.usuarioActual.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              setState(() => cargando = true);
              _cargarDatos();
            },
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bienvenida
                  AppCard(
                    background: AppColors.primary.withOpacity(0.06),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Bienvenido a tu Panel de Trámites!',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Aquí puedes explorar nuevos trámites, ver el estado de tus solicitudes y seguir el progreso en tiempo real.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Estadísticas
                  const SectionHeader('Resumen de Trámites'),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.4,
                    children: [
                      _buildStatCard(
                        'Total de Trámites',
                        '${estadisticas['total']}',
                        Icons.folder,
                        AppColors.compuerta,
                      ),
                      _buildStatCard(
                        'En Proceso',
                        '${estadisticas['en_progreso']}',
                        Icons.hourglass_bottom,
                        AppColors.observado,
                      ),
                      _buildStatCard(
                        'Completados',
                        '${estadisticas['completado']}',
                        Icons.check_circle,
                        AppColors.exito,
                      ),
                      _buildStatCard(
                        'Archivados',
                        '${estadisticas['archivado']}',
                        Icons.archive,
                        AppColors.textoSuave,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Acciones Rápidas
                  const SectionHeader('Acciones Rápidas'),
                  ElevatedButton.icon(
                    onPressed: () => Get.toNamed('/tramites'),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Iniciar Nuevo Trámite'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => Get.toNamed('/mis-tramites'),
                    icon: const Icon(Icons.list),
                    label: const Text('Ver Mis Trámites'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Trámites Recientes
                  const SectionHeader('Trámites Recientes'),
                  if (tramitesRecientes.isEmpty)
                    EmptyState(
                      icon: Icons.inbox_rounded,
                      titulo: 'No hay trámites aún',
                      accion: ElevatedButton(
                        onPressed: () => Get.toNamed('/tramites'),
                        child: const Text('Iniciar uno ahora'),
                      ),
                    )
                  else
                    Column(
                      children: tramitesRecientes
                          .map((tramite) => _buildTramiteCard(tramite))
                          .toList(),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String titulo, String valor, IconData icono, Color color) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icono, color: color, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            titulo,
            style: const TextStyle(color: AppColors.textoSuave, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTramiteCard(TramiteResumen tramite) {
    final colorEstado = EstadoChip.colorDeEstado(tramite.estado);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: () =>
            Get.toNamed('/tramite-seguimiento', arguments: tramite.id),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tramite.codigo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    tramite.politicaNombre,
                    style: const TextStyle(
                        color: AppColors.textoSuave, fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: LinearProgressIndicator(
                      value: tramite.progreso / 100,
                      minHeight: 5,
                      backgroundColor: AppColors.borde,
                      valueColor: AlwaysStoppedAnimation<Color>(colorEstado),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${tramite.progreso}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textoSuave,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            EstadoChip(
              tramitesSeguimientoService.getTextoEstado(tramite.estado),
              color: colorEstado,
            ),
          ],
        ),
      ),
    );
  }
}
