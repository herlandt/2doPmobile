// C3 Guía 2F — Bandeja de Notificaciones (CU-28)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/comunicacion_service.dart';
import '../../utils/error_messages.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

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
          SnackBar(content: Text(mensajeAmigable(e))),
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
        return AppColors.exito;
      case 'observacion':
        return AppColors.observado;
      case 'sla_vencido':
        return AppColors.peligro;
      default:
        return AppColors.compuerta;
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
            tooltip: 'Actualizar',
            onPressed: _cargar,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Obx(() {
        if (comunicacionService.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifs = comunicacionService.notificaciones;

        if (notifs.isEmpty) {
          return RefreshIndicator(
            onRefresh: _cargar,
            child: ListView(
              children: const [
                SizedBox(height: 120),
                EmptyState(
                  icon: Icons.notifications_none_rounded,
                  titulo: 'Sin notificaciones',
                  mensaje: 'No tienes notificaciones recientes.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _cargar,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
            itemCount: notifs.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final n = notifs[index];
              final leida = n['leida'] == true;
              final tipo = n['tipo'] as String? ?? '';
              return _NotifCard(
                color: _color(tipo),
                icono: _icono(tipo),
                titulo: n['titulo'] ?? 'Aviso',
                mensaje: n['mensaje'] ?? '',
                fecha: _formatearFecha(n['fechaCreacion']),
                leida: leida,
              );
            },
          ),
        );
      }),
    );
  }
}

/// Tarjeta de una notificación. Las no-leídas se resaltan con un fondo sutil
/// y un borde acentuado del color del tipo, además del punto indicador.
class _NotifCard extends StatelessWidget {
  final Color color;
  final IconData icono;
  final String titulo;
  final String mensaje;
  final String fecha;
  final bool leida;

  const _NotifCard({
    required this.color,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    required this.leida,
  });

  @override
  Widget build(BuildContext context) {
    final card = AppCard(
      background: leida ? AppColors.superficie : color.withOpacity(0.05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight:
                              leida ? FontWeight.w600 : FontWeight.w800,
                          color: const Color(0xFF1D1B23),
                        ),
                      ),
                    ),
                    if (!leida) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                if (mensaje.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    mensaje,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF45424E),
                      height: 1.3,
                    ),
                  ),
                ],
                if (fecha.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 13, color: AppColors.textoSuave),
                      const SizedBox(width: 4),
                      Text(
                        fecha,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textoSuave),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // Resalte de no-leídas: borde acentuado del color del tipo.
    if (leida) return card;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withOpacity(0.45), width: 1.4),
      ),
      child: card,
    );
  }
}
