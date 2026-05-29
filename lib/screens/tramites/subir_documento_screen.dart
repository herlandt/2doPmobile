import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/network_controller.dart';
import '../../services/adjuntos_service.dart';
import '../../services/upload_queue_service.dart';

/// Argumentos esperados via Get.arguments:
/// { tramiteId, actividadId, actividadNombre, documentoNombre }
class SubirDocumentoScreen extends StatefulWidget {
  const SubirDocumentoScreen({Key? key}) : super(key: key);

  @override
  State<SubirDocumentoScreen> createState() => _SubirDocumentoScreenState();
}

class _SubirDocumentoScreenState extends State<SubirDocumentoScreen> {
  late AdjuntosService adjuntosService;
  late UploadQueueService colaSvc;
  late NetworkController network;
  late Map<String, String> args;

  File? _imagenSeleccionada;
  bool _subiendo = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    adjuntosService = Get.find<AdjuntosService>();
    colaSvc = Get.find<UploadQueueService>();
    network = Get.find<NetworkController>();
    args = Map<String, String>.from(Get.arguments as Map);
  }

  Future<void> _seleccionarImagen(ImageSource fuente) async {
    final XFile? picked = await _picker.pickImage(
      source: fuente,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (picked != null) setState(() => _imagenSeleccionada = File(picked.path));
  }

  Future<void> _subir() async {
    if (_imagenSeleccionada == null) return;

    // CU-33 reforzado — sin conexión, encolamos la subida y notificamos.
    if (!network.hasConnection.value) {
      await colaSvc.enqueue(
        tramiteId: args['tramiteId']!,
        actividadId: args['actividadId']!,
        documentoNombre: args['documentoNombre']!,
        archivo: _imagenSeleccionada!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sin conexión: se subirá cuando vuelva la red.'),
          backgroundColor: Colors.orange,
        ),
      );
      Get.back(result: true);
      return;
    }

    setState(() => _subiendo = true);
    try {
      await adjuntosService.subirAdjunto(
        tramiteId: args['tramiteId']!,
        actividadId: args['actividadId']!,
        documentoNombre: args['documentoNombre']!,
        archivo: _imagenSeleccionada!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento subido correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Get.back(result: true);
      }
    } catch (e) {
      // Si falla por red transitoria, encolar igualmente.
      if (!network.hasConnection.value) {
        await colaSvc.enqueue(
          tramiteId: args['tramiteId']!,
          actividadId: args['actividadId']!,
          documentoNombre: args['documentoNombre']!,
          archivo: _imagenSeleccionada!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se encoló: se reintentará al volver la conexión.'),
              backgroundColor: Colors.orange,
            ),
          );
          Get.back(result: true);
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Documento'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner offline + cola pendiente
            Obx(() {
              final online = network.hasConnection.value;
              final pendientes = colaSvc.totalPendientes;
              if (online && pendientes == 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: online
                      ? Colors.amber.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: online ? Colors.amber.shade300 : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      online ? Icons.upload : Icons.cloud_off,
                      size: 18,
                      color: online ? Colors.amber.shade900 : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        online
                            ? '$pendientes subida(s) en cola: se procesan automáticamente.'
                            : 'Sin conexión. Tu subida se encolará y se enviará cuando vuelva la red.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Info del documento
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    args['actividadNombre'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    args['documentoNombre'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Área de previsualización
            Expanded(
              child: GestureDetector(
                onTap: () => _mostrarOpciones(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _imagenSeleccionada != null
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: _imagenSeleccionada != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _imagenSeleccionada!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Toca para seleccionar imagen',
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botones fuente
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _subiendo ? null : () => _seleccionarImagen(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _subiendo ? null : () => _seleccionarImagen(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Botón subir
            ElevatedButton(
              onPressed: (_imagenSeleccionada == null || _subiendo) ? null : _subir,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green,
              ),
              child: _subiendo
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Confirmar y Subir',
                      style: TextStyle(fontSize: 15, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarOpciones() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
