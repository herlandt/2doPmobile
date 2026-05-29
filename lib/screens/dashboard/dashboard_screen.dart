// Guía 5F - Dashboard Principal

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/tramite_resumen_model.dart';
import '../../services/auth_service.dart';
import '../../services/tramites_seguimiento_service.dart';

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
            onPressed: () {
              setState(() => cargando = true);
              _cargarDatos();
            },
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bienvenida
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
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
                          const SizedBox(height: 8),
                          Text(
                            'Aquí puedes explorar nuevos trámites, ver el estado de tus solicitudes y seguir el progreso en tiempo real.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Estadísticas
                  Text(
                    'Resumen de Trámites',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildStatCard(
                        'Total de Trámites',
                        '${estadisticas['total']}',
                        Icons.folder,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'En Proceso',
                        '${estadisticas['en_progreso']}',
                        Icons.hourglass_bottom,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Completados',
                        '${estadisticas['completado']}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Archivados',
                        '${estadisticas['archivado']}',
                        Icons.archive,
                        Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Acciones Rápidas
                  Text(
                    'Acciones Rápidas',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Get.toNamed('/tramites'),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Iniciar Nuevo Trámite'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Get.toNamed('/mis-tramites'),
                    icon: const Icon(Icons.list),
                    label: const Text('Ver Mis Trámites'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Trámites Recientes
                  Text(
                    'Trámites Recientes',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (tramitesRecientes.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(Icons.inbox, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No hay trámites aún',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => Get.toNamed('/tramites'),
                              child: const Text('Iniciar uno ahora'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: tramitesRecientes
                          .map((tramite) => _buildTramiteCard(tramite))
                          .toList(),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String titulo, String valor, IconData icono, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icono, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTramiteCard(TramiteResumen tramite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Get.toNamed('/tramite-seguimiento', arguments: tramite.id),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
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
                    const SizedBox(height: 4),
                    Text(
                      tramite.politicaNombre,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: tramite.progreso / 100,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tramite.progreso}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tramitesSeguimientoService.getTextoEstado(tramite.estado),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
