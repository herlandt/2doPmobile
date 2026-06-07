// C2 Guía 1F — Catálogo de Tipos de Trámite para iniciar (CU-07)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/tramites_service.dart';
import '../../models/politica_model.dart';
import '../../utils/error_messages.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import 'iniciar_tramite_screen.dart';

class CatalogoTramitesScreen extends StatefulWidget {
  const CatalogoTramitesScreen({Key? key}) : super(key: key);

  @override
  State<CatalogoTramitesScreen> createState() => _CatalogoTramitesScreenState();
}

class _CatalogoTramitesScreenState extends State<CatalogoTramitesScreen> {
  late TramitesService tramitesService;

  @override
  void initState() {
    super.initState();
    tramitesService = Get.find<TramitesService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Tipo de Trámite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargar,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Obx(() {
        if (tramitesService.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final politicasActivas = tramitesService.politicas
            .where((p) => p.estado == 'activa')
            .toList();

        if (politicasActivas.isEmpty) {
          return EmptyState(
            icon: Icons.inbox_outlined,
            titulo: 'No hay políticas de negocio disponibles.',
            accion: ElevatedButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: politicasActivas.length,
          itemBuilder: (context, index) {
            final pol = politicasActivas[index];
            return _buildPoliticaCard(pol);
          },
        );
      }),
    );
  }

  Widget _buildPoliticaCard(Politica pol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () {
          Get.to(
            () => IniciarTramiteScreen(
              politicaId: pol.id,
              politicaNombre: pol.nombre,
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    pol.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    pol.descripcion,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textoSuave),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 14, color: AppColors.textoSuave),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${pol.duracionDiasLimite} días',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textoSuave),
                      ),
                      if (pol.requiereAprobacion) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.verified_user,
                            size: 14, color: AppColors.observado),
                        const SizedBox(width: AppSpacing.xs),
                        const Text(
                          'Requiere aprobación',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.observado),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right, color: Color(0xFFBDB9CC)),
          ],
        ),
      ),
    );
  }
}
