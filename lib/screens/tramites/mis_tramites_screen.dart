// Guía 4F - Pantalla de Lista "Mis Trámites"

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/tramite_resumen_model.dart';
import '../../services/tramites_seguimiento_service.dart';
import '../../routes/app_routes.dart';
import '../../utils/error_messages.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

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
    'En curso', 'Observado', 'Aprobado', 'Rechazado', 'Cancelado',
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
          SnackBar(content: Text(mensajeAmigable(e))),
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
        actions: [
          // C2: acceso rápido a trámites con observaciones
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded,
                color: AppColors.observado),
            tooltip: 'Trámites Observados',
            onPressed: () => Get.toNamed(AppRoutes.tramitesObservados),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarTramites,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Búsqueda
                TextField(
                  onChanged: (value) {
                    setState(() => busqueda = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Buscar por código o nombre',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Filtro por estado
                _filtroEstadoField(),
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
                  return EmptyState(
                    icon: Icons.inbox_outlined,
                    titulo: 'No hay trámites disponibles',
                    mensaje: (busqueda.isNotEmpty || filtroEstado.isNotEmpty)
                        ? 'Intenta cambiar los filtros'
                        : null,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
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

  /// Campo de filtro por estado dentro de una superficie con borde del kit.
  Widget _filtroEstadoField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.borde),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
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
      ),
    );
  }

  /// Badge UX por trámite: NARANJA "Observado" (CASO B) o AZUL "Completar
  /// documentos" (CASO A "compuerta"). Sin badge en otros casos.
  Widget _buildBadge(TramiteResumen tramite) {
    final bool observado = tramite.esObservado;
    final Color color =
        observado ? AppColors.observado : AppColors.compuerta;
    final String texto =
        observado ? 'Observado' : 'Completar documentos';
    final IconData icon =
        observado ? Icons.warning_amber_rounded : Icons.description_outlined;
    return Align(
      alignment: Alignment.centerLeft,
      child: EstadoChip(texto, color: color, icon: icon),
    );
  }

  Widget _buildTramiteCard(TramiteResumen tramite) {
    final color = tramitesSeguimientoService.getColorEstadoFlutter(tramite.estado);
    final progreso = tramitesSeguimientoService.progresoEfectivo(tramite.progreso, tramite.estado);
    final esCerrado = tramitesSeguimientoService.esEstadoTerminal(tramite.estado);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () async {
          print('📋 Navegando a detalle: ${tramite.id}');
          await Get.toNamed('/tramite-seguimiento', arguments: tramite.id);
          // Al volver del detalle, refresca la lista por si cambió el estado.
          if (mounted) _cargarTramites();
        },
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        tramite.politicaNombre,
                        style: const TextStyle(
                            color: AppColors.textoSuave, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                EstadoChip(
                  tramitesSeguimientoService.getTextoEstado(tramite.estado),
                  color: color,
                ),
              ],
            ),

            // Badge UX: distingue CASO A (compuerta, azul) de CASO B
            // (observado, naranja). Ver helpers en TramiteResumen.
            if (tramite.esObservado || tramite.esCompuerta) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildBadge(tramite),
            ],
            const SizedBox(height: AppSpacing.sm),

            // Etapa actual (solo si no está cerrado)
            if (!esCerrado && tramite.nodoActualNombre.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.textoSuave),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Etapa: ${tramite.nodoActualNombre}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textoSuave),
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
                    const Text(
                      'Progreso',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textoSuave),
                    ),
                    Text(
                      '$progreso%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: progreso / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.borde,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Fechas
            Text(
              '📅 Creado: ${_formatoFecha(tramite.fechaInicio)}',
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textoSuave),
            ),
            if (tramite.fechaCierreReal != null)
              Text(
                '✓ Cerrado: ${_formatoFecha(tramite.fechaCierreReal!)}',
                style: const TextStyle(fontSize: 11, color: AppColors.exito),
              ),
          ],
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
