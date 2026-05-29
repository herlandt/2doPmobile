// C2 Guía 1F — Confirmación e Inicio de Trámite simplificado (CU-07)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/tramites_envio_service.dart';
import '../../services/auth_service.dart';

class IniciarTramiteScreen extends StatefulWidget {
  final String politicaId;
  final String politicaNombre;

  const IniciarTramiteScreen({
    Key? key,
    required this.politicaId,
    required this.politicaNombre,
  }) : super(key: key);

  @override
  State<IniciarTramiteScreen> createState() => _IniciarTramiteScreenState();
}

class _IniciarTramiteScreenState extends State<IniciarTramiteScreen> {
  late TramitesEnvioService envioService;
  late AuthService authService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    envioService = Get.find<TramitesEnvioService>();
    authService = Get.find<AuthService>();
  }

  Future<void> _iniciar() async {
    final clienteId = authService.usuarioActual.value?.id ?? '';
    if (clienteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: no se pudo obtener el ID del usuario.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result =
          await envioService.iniciarTramiteC2(widget.politicaId, clienteId);

      final codigo = result['codigo'] ?? result['tramiteId'] ?? 'N/D';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Trámite iniciado con éxito: $codigo'),
            backgroundColor: Colors.green,
          ),
        );
        // Volver al Dashboard
        Get.until((route) => route.settings.name == '/home');
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Trámite'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icono
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_turned_in,
                  size: 64,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Texto informativo
            const Text(
              'Está a punto de iniciar:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              widget.politicaNombre,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Aviso
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Una vez iniciado, este trámite será derivado automáticamente al área de Atención al Cliente para su revisión.',
                style: TextStyle(fontSize: 14),
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: _isLoading ? null : _iniciar,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Confirmar e Iniciar Trámite',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : () => Get.back(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
