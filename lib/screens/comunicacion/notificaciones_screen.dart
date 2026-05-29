// C3 Guía 2F — Bandeja de Notificaciones (CU-28)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/comunicacion_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({Key? key}) : super(key: key);

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  late ComunicacionService comunicacionService;

  @override
  void initState() {
    super.initState();
    comunicacionService = Get.find<ComunicacionService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    try {
      await comunicacionService.getMisNotificaciones();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener notificaciones: $e')),
        );
      }
    }
  }

  // Tipos reales del backend: cambio_estado | asignacion | sla_vencido | observacion
  IconData _icono(String tipo) {
    switch (tipo) {
      case 'cambio_estado':
        return Icons.trending_flat;
      case 'asignacion':
        return Icons.verified;
      case 'observacion':
        return Icons.history;
      case 'sla_vencido':
        return Icons.warning_amber;
      default:
        return Icons.notifications_active;
    }
  }

  Color _color(String tipo) {
    switch (tipo) {
      case 'asignacion':
        return Colors.green;
      case 'observacion':
        return Colors.orange;
      case 'sla_vencido':
        return Colors.red;
      default:
        return Colors.blue;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Notificaciones'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
        ],
      ),
      body: Obx(() {
        if (comunicacionService.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifs = comunicacionService.notificaciones;

        if (notifs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No tienes notificaciones recientes.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _cargar,
          child: ListView.separated(
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = notifs[index];
              final leida = n['leida'] == true;
              final tipo = n['tipo'] as String? ?? '';

              return Container(
                color: leida
                    ? Colors.transparent
                    : Colors.blue.withOpacity(0.04),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: _color(tipo),
                    child:
                        Icon(_icono(tipo), color: Colors.white, size: 20),
                  ),
                  title: Text(
                    n['titulo'] ?? 'Aviso',
                    style: TextStyle(
                      fontWeight:
                          leida ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(n['mensaje'] ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        _formatearFecha(n['fechaCreacion']),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: leida
                      ? null
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
