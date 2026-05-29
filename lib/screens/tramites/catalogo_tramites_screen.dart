// C2 Guía 1F — Catálogo de Tipos de Trámite para iniciar (CU-07)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/tramites_service.dart';
import '../../models/politica_model.dart';
import 'iniciar_tramite_screen.dart';

class CatalogoTramitesScreen extends StatefulWidget {
  const CatalogoTramitesScreen({Key? key}) : super(key: key);

  @override
  State<CatalogoTramitesScreen> createState() => _CatalogoTramitesScreenState();
}

class _CatalogoTramitesScreenState extends State<CatalogoTramitesScreen> {
  late TramitesService tramitesService;

  @override
  void initState() {
    super.initState();
    tramitesService = Get.find<TramitesService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    try {
      await tramitesService.obtenerPoliticas();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar políticas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Tipo de Trámite'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
        ],
      ),
      body: Obx(() {
        if (tramitesService.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final politicasActivas = tramitesService.politicas
            .where((p) => p.estado == 'activa')
            .toList();

        if (politicasActivas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No hay políticas de negocio disponibles.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _cargar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: politicasActivas.length,
          itemBuilder: (context, index) {
            final pol = politicasActivas[index];
            return _buildPoliticaCard(pol);
          },
        );
      }),
    );
  }

  Widget _buildPoliticaCard(Politica pol) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.description, color: Colors.blue.shade700),
        ),
        title: Text(
          pol.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(pol.descripcion),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${pol.duracionDiasLimite} días',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (pol.requiereAprobacion) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.verified_user, size: 14, color: Colors.orange[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Requiere aprobación',
                    style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Get.to(
            () => IniciarTramiteScreen(
              politicaId: pol.id,
              politicaNombre: pol.nombre,
            ),
          );
        },
      ),
    );
  }
}
