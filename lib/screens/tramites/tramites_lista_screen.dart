import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/politica_model.dart';
import '../../services/tramites_service.dart';
import '../../utils/error_messages.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

/// Trámites que el cliente PUEDE iniciar. Solo muestra políticas ACTIVAS:
/// borrador/archivada son estados internos del admin, no "disponibles".
class TramitesListaScreen extends StatefulWidget {
  const TramitesListaScreen({super.key});

  @override
  State<TramitesListaScreen> createState() => _TramitesListaScreenState();
}

class _TramitesListaScreenState extends State<TramitesListaScreen> {
  late TramitesService tramitesService;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    tramitesService = Get.find<TramitesService>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarPoliticas());
  }

  Future<void> _cargarPoliticas() async {
    try {
      await tramitesService.obtenerPoliticas();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeAmigable(e))),
        );
      }
    }
  }

  /// Solo ACTIVAS + búsqueda por nombre/descripción.
  List<Politica> get _politicasFiltradas {
    var resultado =
        tramitesService.politicas.where((p) => p.estado == 'activa').toList();
    if (_busqueda.isNotEmpty) {
      final t = _busqueda.toLowerCase();
      resultado = resultado
          .where((p) =>
              p.nombre.toLowerCase().contains(t) ||
              p.descripcion.toLowerCase().contains(t))
          .toList();
    }
    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trámites Disponibles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarPoliticas,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          // Búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: TextField(
              onChanged: (v) => setState(() => _busqueda = v),
              decoration: const InputDecoration(
                labelText: 'Buscar trámite',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Lista
          Expanded(
            child: Obx(() {
              if (tramitesService.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final lista = _politicasFiltradas;
              if (lista.isEmpty) {
                return EmptyState(
                  icon: Icons.inbox_outlined,
                  titulo: 'No hay trámites disponibles',
                  mensaje: _busqueda.isNotEmpty
                      ? 'Prueba con otra búsqueda'
                      : 'Vuelve a intentar más tarde',
                  accion: ElevatedButton.icon(
                    onPressed: _cargarPoliticas,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                itemCount: lista.length,
                itemBuilder: (context, i) => _buildTramiteCard(lista[i]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTramiteCard(Politica politica) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => Get.toNamed('/tramite-detalle', arguments: politica.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.compuerta.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.description,
                      color: AppColors.compuerta, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        politica.nombre,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        politica.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textoSuave, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 15, color: AppColors.textoSuave),
                const SizedBox(width: 6),
                Text(
                  '${politica.duracionDiasLimite} días límite',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textoSuave),
                ),
                if (politica.requiereAprobacion) ...[
                  const SizedBox(width: AppSpacing.md),
                  const Icon(Icons.verified,
                      size: 15, color: AppColors.compuerta),
                  const SizedBox(width: 6),
                  const Text(
                    'Requiere aprobación',
                    style: TextStyle(fontSize: 12, color: AppColors.compuerta),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Get.toNamed('/tramite-nuevo', arguments: politica.id),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Iniciar Trámite'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.toNamed('/tramite-detalle',
                        arguments: politica.id),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Ver Detalles'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
