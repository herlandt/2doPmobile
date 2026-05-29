// C3 Guía 1F — Línea de Tiempo Interactiva y Cancelación (CU-21, CU-19)
// NOTA: la integración con CU-42 (ruta óptima IA) se removió — el caso de uso
// "IA sugiere qué trámite" pertenece a CU-40 en IniciarTramiteIaScreen, no al
// seguimiento del cliente.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../services/tramites_seguimiento_service.dart';

class DetalleLineaTiempoScreen extends StatefulWidget {
  final String tramiteId;
  final String codigo;

  const DetalleLineaTiempoScreen({
    Key? key,
    required this.tramiteId,
    required this.codigo,
  }) : super(key: key);

  @override
  State<DetalleLineaTiempoScreen> createState() =>
      _DetalleLineaTiempoScreenState();
}

class _DetalleLineaTiempoScreenState extends State<DetalleLineaTiempoScreen> {
  late TramitesSeguimientoService seguimientoService;
  Map<String, dynamic>? _datos;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    seguimientoService = Get.find<TramitesSeguimientoService>();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data =
          await seguimientoService.getLineaTiempoTramite(widget.tramiteId);
      setState(() => _datos = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // CU-19: Diálogo de cancelación
  void _mostrarDialogoCancelar() {
    final motivoController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text(
          'Cancelar Trámite',
          style: TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Estás seguro de que deseas desistir de este trámite? El proceso se detendrá inmediatamente en el departamento actual.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: InputDecoration(
                labelText: 'Motivo de cancelación (opcional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cerrar'),
            onPressed: () => Get.back(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmar Cancelación',
                style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Get.back();
              try {
                await seguimientoService.cancelarTramite(
                    widget.tramiteId, motivoController.text);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trámite cancelado.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                _cargar();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    ).whenComplete(motivoController.dispose);
  }

  String _formatearFecha(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Color _colorEstado(String estado) {
    final e = estado.toLowerCase();
    if (e.contains('cancel') || e.contains('rechaz')) return Colors.red;
    if (e.contains('aprobado') || e.contains('completado')) return Colors.green;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seguimiento: ${widget.codigo}'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
            tooltip: 'Cancelar Trámite',
            onPressed: _mostrarDialogoCancelar,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Error al cargar la línea de tiempo.'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _cargar,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _buildContenido(),
    );
  }

  Widget _buildContenido() {
    final estadoGlobal =
        _datos?['estadoActual'] as String? ?? 'Desconocido';
    final hitos = _datos?['hitos'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // Encabezado de estado global
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Estado Global:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Chip(
                label: Text(
                  estadoGlobal,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: _colorEstado(estadoGlobal),
              ),
            ],
          ),
        ),

        // CU-42 (banner ruta IA) removido — ver comentario al inicio del archivo.

        // Timeline de hitos (CU-21)
        Expanded(
          child: hitos.isEmpty
              ? const Center(
                  child: Text(
                    'No hay hitos registrados aún.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: hitos.length,
                  itemBuilder: (context, index) {
                    final hito = hitos[index];
                    final bool esActual = hito['esActual'] == true;
                    final bool esUltimo = index == hitos.length - 1;

                    return TimelineTile(
                      isFirst: index == 0,
                      isLast: esUltimo,
                      indicatorStyle: IndicatorStyle(
                        width: 28,
                        color: esActual ? Colors.orange : Colors.green,
                        iconStyle: IconStyle(
                          iconData: esActual
                              ? Icons.hourglass_top
                              : Icons.check_circle,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      beforeLineStyle: LineStyle(
                        color: esActual
                            ? Colors.orange.shade300
                            : Colors.green.shade300,
                        thickness: 2,
                      ),
                      endChild: Container(
                        constraints: const BoxConstraints(minHeight: 100),
                        padding: const EdgeInsets.fromLTRB(12, 8, 8, 16),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hito['estado'] ?? 'Sin estado',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                if (hito['departamento'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.business, size: 13,
                                          color: Colors.blueGrey),
                                      const SizedBox(width: 4),
                                      Text('${hito['departamento']}',
                                          style: const TextStyle(
                                              fontSize: 13)),
                                    ],
                                  ),
                                ],
                                if (hito['actor'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 13,
                                          color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text('${hito['actor']}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700])),
                                    ],
                                  ),
                                ],
                                if (hito['fecha'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 13,
                                          color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatearFecha(hito['fecha']),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.green),
                                      ),
                                    ],
                                  ),
                                ],
                                if (esActual) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'En proceso actualmente',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.deepOrange,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
