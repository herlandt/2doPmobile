// CU-34 — Preview de documento del repositorio.
//
// - Imagen → se muestra inline con `Image.network` (URL S3 firmada).
// - PDF / Word / Excel / otro → botón "Abrir" que delega en `url_launcher`.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/documento_archivo_model.dart';

class PreviewDocumentoWidget extends StatelessWidget {
  final PreviewDocumento preview;
  final String nombreLogico;

  const PreviewDocumentoWidget({
    Key? key,
    required this.preview,
    required this.nombreLogico,
  }) : super(key: key);

  Future<void> _abrirExterno(BuildContext context) async {
    final uri = Uri.tryParse(preview.urlPreview);
    if (uri == null) return;
    final abrio = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!abrio && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo abrir el visor externo.')),
      );
    }
  }

  IconData _iconoTipo() {
    if (preview.esImagen) return Icons.image;
    if (preview.esPdf) return Icons.picture_as_pdf;
    final m = preview.mimeType.toLowerCase();
    if (m.contains('word')) return Icons.description;
    if (m.contains('sheet') || m.contains('excel')) {
      return Icons.table_chart;
    }
    if (m.contains('audio')) return Icons.audiotrack;
    if (m.contains('video')) return Icons.movie;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    if (preview.esImagen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              preview.urlPreview,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Colors.grey.shade100,
                child: const Center(
                  child: Text('No se pudo cargar la vista previa'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _abrirExterno(context),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Abrir en visor externo'),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(_iconoTipo(), size: 36, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreLogico,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  preview.mimeType,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _abrirExterno(context),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Abrir'),
          ),
        ],
      ),
    );
  }
}
