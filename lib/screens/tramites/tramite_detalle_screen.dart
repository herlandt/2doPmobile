import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/politica_model.dart';
import '../../services/tramites_service.dart';
import '../../services/adjuntos_service.dart';
import '../../utils/error_messages.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

class TramiteDetalleScreen extends StatefulWidget {
  const TramiteDetalleScreen({super.key});

  @override
  State<TramiteDetalleScreen> createState() => _TramiteDetalleScreenState();
}

class _TramiteDetalleScreenState extends State<TramiteDetalleScreen> {
  late TramitesService tramitesService;
  late AdjuntosService adjuntosService;
  late String politicaId;
  List<ActividadDocumentos> _documentosRequeridos = [];

  @override
  void initState() {
    super.initState();
    tramitesService = Get.find<TramitesService>();
    adjuntosService = Get.find<AdjuntosService>();
    politicaId = Get.arguments ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDetalle();
    });
  }

  Future<void> _cargarDetalle() async {
    try {
      await tramitesService.obtenerPoliticaPorId(politicaId);
      final docs = await adjuntosService.obtenerDocumentosRequeridos(politicaId);
      if (mounted) setState(() => _documentosRequeridos = docs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeAmigable(e))),
        );
      }
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'activa':
        return AppColors.exito;
      case 'borrador':
        return AppColors.observado;
      case 'archivada':
        return AppColors.textoSuave;
      default:
        return AppColors.compuerta;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Trámite'),
      ),
      body: Obx(
        () {
          if (tramitesService.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final politica = tramitesService.politicaActual.value;

          if (politica == null) {
            return EmptyState(
              icon: Icons.error_outline,
              titulo: 'No se pudo cargar el trámite',
              accion: ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Volver'),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado: nombre del trámite + chip de estado
                Text(
                  politica.nombre,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                EstadoChip(
                  politica.estado.toUpperCase(),
                  color: _getEstadoColor(politica.estado),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Descripción
                _buildSection(
                  title: 'Descripción',
                  child: AppCard(
                    child: Text(
                      politica.descripcion,
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ),
                ),

                // Información General
                _buildSection(
                  title: 'Información General',
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          '⏱ Duración Límite',
                          '${politica.duracionDiasLimite} días',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildInfoRow(
                          '✓ Aprobación',
                          politica.requiereAprobacion
                              ? 'Requerida'
                              : 'No requerida',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildInfoRow(
                          '📅 Creado',
                          politica.fechaCreacion,
                        ),
                      ],
                    ),
                  ),
                ),

                // Documentos requeridos por actividad
                _buildSection(
                  title: 'Documentos que necesitas',
                  child: _documentosRequeridos.isEmpty
                      ? AppCard(
                          background: AppColors.fondo,
                          child: const Text(
                            'No hay documentos específicos configurados para este trámite.',
                            style: TextStyle(
                                color: AppColors.textoSuave, fontSize: 13),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _documentosRequeridos.map((actDoc) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.work_outline,
                                            size: 16,
                                            color: AppColors.compuerta),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            actDoc.actividadNombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: AppColors.compuerta,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    ...actDoc.documentosRequeridos
                                        .map((doc) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 6),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(
                                                      Icons.description_outlined,
                                                      size: 14,
                                                      color:
                                                          AppColors.textoSuave),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          doc.nombre,
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        if (doc.descripcion
                                                            .isNotEmpty)
                                                          Text(
                                                            doc.descripcion,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 11,
                                                              color: AppColors
                                                                  .textoSuave,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),

                // Flujo del Proceso
                _buildSection(
                  title: 'Flujo del Proceso',
                  child: AppCard(
                    background: AppColors.compuerta.withOpacity(0.06),
                    child: const Text(
                      'El trámite pasará por diferentes etapas según la política configurada. '
                      'Podrás seguir el estado en tiempo real desde tu panel de control.',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.compuerta),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Botones de acción
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: politica.estado == 'activa'
                        ? () => Get.toNamed(
                              '/tramite-nuevo',
                              arguments: politica.id,
                            )
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Iniciar Este Trámite',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Volver'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        child,
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildRequisito(String titulo, String descripcion) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            descripcion,
            style: const TextStyle(
              color: AppColors.textoSuave,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
