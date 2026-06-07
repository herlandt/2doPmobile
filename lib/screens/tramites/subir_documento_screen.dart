import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/network_controller.dart';
import '../../models/flujo_completo_model.dart';
import '../../services/adjuntos_service.dart';
import '../../services/upload_queue_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

/// Argumentos esperados via Get.arguments:
/// { tramiteId, actividadId, actividadNombre, documentoNombre }
/// Compuerta de documentos (opcionales):
///   - documentoRequeridoId: si viene, el documento se asocia directo a ese
///     requisito (no se muestra dropdown).
///   - requisitosCliente: `List<DocumentoRequerido>` del nodo (proveedor CLIENTE)
///     para que, si no llegó un documentoRequeridoId, el cliente elija cuál cumple.
class SubirDocumentoScreen extends StatefulWidget {
  const SubirDocumentoScreen({Key? key}) : super(key: key);

  @override
  State<SubirDocumentoScreen> createState() => _SubirDocumentoScreenState();
}

class _SubirDocumentoScreenState extends State<SubirDocumentoScreen> {
  late AdjuntosService adjuntosService;
  late UploadQueueService colaSvc;
  late NetworkController network;
  late Map<String, dynamic> _rawArgs;
  late Map<String, String> args;

  File? _imagenSeleccionada;
  bool _subiendo = false;
  final ImagePicker _picker = ImagePicker();

  // Compuerta de documentos: requisito que cumple esta subida.
  List<DocumentoRequerido> _requisitosCliente = const [];
  String? _documentoRequeridoId;

  @override
  void initState() {
    super.initState();
    adjuntosService = Get.find<AdjuntosService>();
    colaSvc = Get.find<UploadQueueService>();
    network = Get.find<NetworkController>();
    _rawArgs = Map<String, dynamic>.from(Get.arguments as Map);
    // Sólo los campos String se exponen como `args` (compatibilidad con el
    // build previo, que indexa args['...']).
    args = <String, String>{
      for (final e in _rawArgs.entries)
        if (e.value is String) e.key: e.value as String,
    };

    final reqs = _rawArgs['requisitosCliente'];
    if (reqs is List) {
      _requisitosCliente = reqs.whereType<DocumentoRequerido>().toList();
    }
    // Si llega un requisito directo, úsalo y no se muestra el dropdown.
    final directo = _rawArgs['documentoRequeridoId'];
    if (directo is String && directo.isNotEmpty) {
      _documentoRequeridoId = directo;
    }
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
          backgroundColor: AppColors.observado,
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
        documentoRequeridoId: _documentoRequeridoId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento subido correctamente'),
            backgroundColor: AppColors.exito,
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
              backgroundColor: AppColors.observado,
            ),
          );
          Get.back(result: true);
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mensajeError(e)),
            backgroundColor: AppColors.peligro,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  /// Mensaje claro para el usuario a partir del error de subida.
  String _mensajeError(Object e) {
    if (e is SubidaException) return e.mensaje;
    return 'No se pudo subir el documento. Revisa tu conexión e intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Documento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner offline + cola pendiente
            Obx(() {
              final online = network.hasConnection.value;
              final pendientes = colaSvc.totalPendientes;
              if (online && pendientes == 0) return const SizedBox.shrink();
              final color =
                  online ? AppColors.observado : AppColors.peligro;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  background: color.withOpacity(0.06),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        online ? Icons.upload : Icons.cloud_off,
                        size: 18,
                        color: color,
                      ),
                      const SizedBox(width: AppSpacing.sm),
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
                ),
              );
            }),
            // Info del documento
            AppCard(
              background: AppColors.compuerta.withOpacity(0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    args['actividadNombre'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.compuerta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
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

            // Compuerta de documentos: si NO llegó un requisito directo y hay
            // requisitos del cliente, el usuario elige cuál cumple.
            _buildSelectorRequisito(),
            const SizedBox(height: AppSpacing.lg),

            // Área de previsualización
            Expanded(
              child: GestureDetector(
                onTap: () => _mostrarOpciones(),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.fondo,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: _imagenSeleccionada != null
                          ? AppColors.exito
                          : AppColors.borde,
                      width: 2,
                    ),
                  ),
                  child: _imagenSeleccionada != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          child: Image.file(
                            _imagenSeleccionada!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'Toca para seleccionar imagen',
                              style: TextStyle(
                                  color: AppColors.textoSuave, fontSize: 14),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Botones fuente
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _subiendo ? null : () => _seleccionarImagen(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _subiendo ? null : () => _seleccionarImagen(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Botón subir
            ElevatedButton(
              onPressed: (_imagenSeleccionada == null || _subiendo) ? null : _subir,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.exito,
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

  /// Dropdown para elegir QUÉ requisito del cliente cumple esta subida.
  /// Sólo aparece cuando NO llegó un `documentoRequeridoId` directo en los args
  /// y hay requisitos del cliente disponibles.
  Widget _buildSelectorRequisito() {
    final directo = _rawArgs['documentoRequeridoId'];
    final llegoDirecto = directo is String && directo.isNotEmpty;
    if (llegoDirecto || _requisitosCliente.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: DropdownButtonFormField<String>(
        value: _documentoRequeridoId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: '¿Qué requisito cumple este documento?',
          prefixIcon: Icon(Icons.rule),
        ),
        items: _requisitosCliente
            .map(
              (r) => DropdownMenuItem<String>(
                value: r.id,
                child: Text(
                  r.obligatorio ? '${r.nombre} (obligatorio)' : r.nombre,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: _subiendo
            ? null
            : (v) => setState(() => _documentoRequeridoId = v),
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
