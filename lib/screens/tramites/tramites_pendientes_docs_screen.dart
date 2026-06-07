// UX — Lista de Trámites que AVANZARON y piden documentos NUEVOS (CASO A
// "compuerta"). Tono AZUL positivo: el trámite avanzó, no es una corrección.
// Distinto de TramitesObservadosScreen (CASO B, naranja, "corregir").

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/tramite_resumen_model.dart';
import '../../services/tramites_seguimiento_service.dart';
import '../../utils/error_messages.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import 'realizar_correccion_screen.dart';

class TramitesPendientesDocsScreen extends StatefulWidget {
  const TramitesPendientesDocsScreen({Key? key}) : super(key: key);

  @override
  State<TramitesPendientesDocsScreen> createState() =>
      _TramitesPendientesDocsScreenState();
}

class _TramitesPendientesDocsScreenState
    extends State<TramitesPendientesDocsScreen> {
  late TramitesSeguimientoService seguimientoService;
  List<TramiteResumen> _pendientes = [];
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    seguimientoService = Get.find<TramitesSeguimientoService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final todos = await seguimientoService.obtenerMisTramites();
      setState(() {
        // CASO A: estadoSeccion "Pendiente de documentos" y NO observado.
        _pendientes = todos.where((t) => t.esCompuerta).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeAmigable(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar documentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargar,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _pendientes.isEmpty
                      ? const EmptyState(
                          icon: Icons.check_circle_outline,
                          titulo: 'No tienes documentos pendientes 🎉',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0,
                              AppSpacing.md, AppSpacing.lg),
                          itemCount: _pendientes.length,
                          itemBuilder: (context, index) {
                            final t = _pendientes[index];
                            return _buildCard(t);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: AppCard(
        background: AppColors.compuerta.withOpacity(0.08),
        child: Row(
          children: [
            const Icon(Icons.trending_up, color: AppColors.compuerta),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text(
                'Tu trámite avanzó — completa los documentos para continuar.',
                style: TextStyle(
                  color: AppColors.compuerta,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(TramiteResumen t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_outlined,
                    color: AppColors.compuerta),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    t.codigo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                const EstadoChip(
                  'Completar documentos',
                  color: AppColors.compuerta,
                  icon: Icons.description_outlined,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(t.politicaNombre,
                style: const TextStyle(
                    color: AppColors.textoSuave, fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Etapa: ${t.nodoActualNombre}',
              style: const TextStyle(fontSize: 12, color: AppColors.textoSuave),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Completar documentos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.compuerta,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Get.to(
                    () => RealizarCorreccionScreen(tramite: t),
                  )?.then((_) => _cargar());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
