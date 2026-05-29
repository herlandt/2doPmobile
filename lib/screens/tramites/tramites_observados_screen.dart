// C2 Guía 2F — Lista de Trámites Devueltos/Observados (CU-17 cliente)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/tramite_resumen_model.dart';
import '../../services/tramites_seguimiento_service.dart';
import 'realizar_correccion_screen.dart';

class TramitesObservadosScreen extends StatefulWidget {
  const TramitesObservadosScreen({Key? key}) : super(key: key);

  @override
  State<TramitesObservadosScreen> createState() =>
      _TramitesObservadosScreenState();
}

class _TramitesObservadosScreenState extends State<TramitesObservadosScreen> {
  late TramitesSeguimientoService seguimientoService;
  List<TramiteResumen> _observados = [];
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
        // La guía G2F-C2 especifica filtrar por estadoActual == 'Observado'
        _observados = todos
            .where((t) =>
                t.estado == 'Observado' ||
                t.estado == 'observado' ||
                t.estado == 'Devuelto' ||
                t.estado == 'devuelto')
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar trámites: $e')),
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
        title: const Text('Trámites Devueltos / Observados'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _observados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.green.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'No tienes trámites con observaciones.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _observados.length,
                  itemBuilder: (context, index) {
                    final t = _observados[index];
                    return _buildCard(t);
                  },
                ),
    );
  }

  Widget _buildCard(TramiteResumen t) {
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.codigo,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(t.politicaNombre,
                style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              'Etapa: ${t.nodoActualNombre}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_note),
                label: const Text('Corregir y Reenviar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
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

