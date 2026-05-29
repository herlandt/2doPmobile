import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/politica_model.dart';
import '../../services/tramites_service.dart';
import '../../services/adjuntos_service.dart';

class TramiteDetalleScreen extends StatefulWidget {
  const TramiteDetalleScreen({Key? key}) : super(key: key);

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
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'activa':
        return Colors.green;
      case 'borrador':
        return Colors.orange;
      case 'archivada':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Trámite'),
        elevation: 0,
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('No se pudo cargar el trámite'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con fondo
                Container(
                  color: Colors.blue,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  politica.nombre,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getEstadoColor(politica.estado),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    politica.estado.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Contenido
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Descripción
                      _buildSection(
                        title: 'Descripción',
                        child: Text(
                          politica.descripcion,
                          style: const TextStyle(fontSize: 14, height: 1.6),
                        ),
                      ),

                      // Información General
                      _buildSection(
                        title: 'Información General',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              '⏱ Duración Límite',
                              '${politica.duracionDiasLimite} días',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              '✓ Aprobación',
                              politica.requiereAprobacion ? 'Requerida' : 'No requerida',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              '📅 Creado',
                              politica.fechaCreacion,
                            ),
                          ],
                        ),
                      ),

                      // Documentos requeridos por actividad
                      _buildSection(
                        title: 'Documentos que necesitas',
                        child: _documentosRequeridos.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: const Text(
                                  'No hay documentos específicos configurados para este trámite.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _documentosRequeridos.map((actDoc) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade100),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.work_outline,
                                                size: 16, color: Colors.blue.shade700),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                actDoc.actividadNombre,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Colors.blue.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...actDoc.documentosRequeridos.map((doc) => Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.description_outlined,
                                                      size: 14, color: Colors.grey[600]),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    doc,
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            )),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),

                      // Flujo del Proceso
                      _buildSection(
                        title: 'Flujo del Proceso',
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'El trámite pasará por diferentes etapas según la política configurada. '
                            'Podrás seguir el estado en tiempo real desde tu panel de control.',
                            style: TextStyle(fontSize: 13, color: Colors.blue),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

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
                      const SizedBox(height: 12),
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 24),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
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
          const SizedBox(height: 4),
          Text(
            descripcion,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
