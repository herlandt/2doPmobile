// C2 Guía 2F — Formulario de Corrección de Trámite Devuelto (CU-17 cliente)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/tramite_resumen_model.dart';
import '../../services/tramites_seguimiento_service.dart';

class RealizarCorreccionScreen extends StatefulWidget {
  final TramiteResumen tramite;

  const RealizarCorreccionScreen({Key? key, required this.tramite})
      : super(key: key);

  @override
  State<RealizarCorreccionScreen> createState() =>
      _RealizarCorreccionScreenState();
}

class _RealizarCorreccionScreenState extends State<RealizarCorreccionScreen> {
  final _respuestaController = TextEditingController();
  late TramitesSeguimientoService seguimientoService;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    seguimientoService = Get.find<TramitesSeguimientoService>();
  }

  @override
  void dispose() {
    _respuestaController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _respuestaController.text.trim();
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Debe ingresar un comentario o respuesta.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await seguimientoService.enviarCorreccion(widget.tramite.id, texto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Corrección enviada correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
        Get.back();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subsanar Trámite'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Código del trámite
            Text(
              widget.tramite.codigo,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.tramite.politicaNombre,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Aviso devolución
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Motivo de devolución',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Revise el historial del trámite para ver las observaciones detalladas del funcionario. Ingrese su corrección a continuación.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Campo de respuesta
            TextField(
              controller: _respuestaController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Respuesta / Subsanación',
                hintText:
                    'Ingrese sus observaciones o describa la corrección realizada...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            const Spacer(),

            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _enviar,
              icon: _isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSubmitting ? 'Enviando...' : 'Reenviar Trámite',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
