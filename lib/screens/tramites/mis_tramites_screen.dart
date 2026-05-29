// Guía 4F - Pantalla de Lista "Mis Trámites"

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/tramite_resumen_model.dart';
import '../../services/tramites_seguimiento_service.dart';
import '../../routes/app_routes.dart';

class MisTramitesScreen extends StatefulWidget {
  const MisTramitesScreen({Key? key}) : super(key: key);

  @override
  State<MisTramitesScreen> createState() => _MisTramitesScreenState();
}

class _MisTramitesScreenState extends State<MisTramitesScreen> {
  late TramitesSeguimientoService tramitesSeguimientoService;

  String filtroEstado = '';
  String busqueda = '';

  final List<String> estadosDisponibles = [
    'En proceso', 'Aprobado', 'Rechazado', 'Cancelado', 'Observado', 'Derivado',
  ];

  @override
  void initState() {
    super.initState();
    tramitesSeguimientoService = Get.find<TramitesSeguimientoService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarTramites();
    });
  }

  Future<void> _cargarTramites() async {
    try {
      await tramitesSeguimientoService.obtenerMisTramites();
    } catch (e) {
      print('Error cargando trámites: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  List<TramiteResumen> get tramitesFiltrados {
    List<TramiteResumen> resultado = tramitesSeguimientoService.misTramites;

    // Filtrar por estado
    if (filtroEstado.isNotEmpty) {
      resultado = resultado.where((t) => t.estado == filtroEstado).toList();
    }

    // Filtrar por búsqueda
    if (busqueda.isNotEmpty) {
      final termino = busqueda.toLowerCase();
      resultado = resultado
          .where((t) =>
              t.codigo.toLowerCase().contains(termino) ||
              t.politicaNombre.toLowerCase().contains(termino))
          .toList();
    }

    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Trámites'),
        elevation: 0,
        actions: [
          // C2: acceso rápido a trámites con observaciones
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            tooltip: 'Trámites Observados',
            onPressed: () => Get.toNamed(AppRoutes.tramitesObservados),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTramites,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Búsqueda
                TextField(
                  onChanged: (value) {
                    setState(() => busqueda = value);
                  },
                  decoration: InputDecoration(
                    labelText: 'Buscar por código o nombre',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filtro por estado
                DropdownButton<String>(
                  isExpanded: true,
                  value: filtroEstado.isEmpty ? null : filtroEstado,
                  hint: const Text('Filtrar por estado'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Todos los estados'),
                    ),
                    ...estadosDisponibles.map((estado) {
                      return DropdownMenuItem(
                        value: estado,
                        child: Text(
                          '${tramitesSeguimientoService.getIconoEstado(estado)} ${tramitesSeguimientoService.getTextoEstado(estado).toUpperCase()}',
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => filtroEstado = value ?? '');
                  },
                ),
              ],
            ),
          ),

          // Lista de trámites
          Expanded(
            child: Obx(
              () {
                if (tramitesSeguimientoService.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (tramitesFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay trámites disponibles',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        if (busqueda.isNotEmpty || filtroEstado.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Intenta cambiar los filtros',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tramitesFiltrados.length,
                  itemBuilder: (context, index) {
                    final tramite = tramitesFiltrados[index];
                    return _buildTramiteCard(tramite);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTramiteCard(TramiteResumen tramite) {
    final color = tramitesSeguimientoService.getColorEstadoFlutter(tramite.estado);
    final progreso = tramitesSeguimientoService.progresoEfectivo(tramite.progreso, tramite.estado);
    final esCerrado = tramitesSeguimientoService.esEstadoTerminal(tramite.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          print('📋 Navegando a detalle: ${tramite.id}');
          await Get.toNamed('/tramite-seguimiento', arguments: tramite.id);
          // Al volver del detalle, refresca la lista por si cambió el estado.
          if (mounted) _cargarTramites();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: Código y Estado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tramite.codigo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tramite.politicaNombre,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      border: Border.all(color: color),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${tramitesSeguimientoService.getIconoEstado(tramite.estado)} ${tramitesSeguimientoService.getTextoEstado(tramite.estado)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Etapa actual (solo si no está cerrado)
              if (!esCerrado && tramite.nodoActualNombre.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Etapa: ${tramite.nodoActualNombre}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // Barra de progreso
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progreso',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '$progreso%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progreso / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Fechas
              Text(
                '📅 Creado: ${_formatoFecha(tramite.fechaInicio)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              if (tramite.fechaCierreReal != null)
                Text(
                  '✓ Cerrado: ${_formatoFecha(tramite.fechaCierreReal!)}',
                  style: TextStyle(fontSize: 11, color: Colors.green[600]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatoFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return fecha;
    }
  }
}
