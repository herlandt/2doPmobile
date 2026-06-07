import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Kit de UI reutilizable — para que TODAS las pantallas del cliente compartan
/// el mismo look (tarjetas, encabezados, chips de estado, estados vacíos).
/// Importar: `import '../../widgets/ui_kit.dart';`

/// Tarjeta base con borde suave y esquinas redondeadas (reemplaza el `Card`
/// suelto para un look uniforme).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? background;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: background ?? AppColors.superficie,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borde),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: card,
      ),
    );
  }
}

/// Encabezado de sección: título en negrita + acción opcional a la derecha.
class SectionHeader extends StatelessWidget {
  final String titulo;
  final String? accionTexto;
  final VoidCallback? onAccion;
  const SectionHeader(this.titulo, {super.key, this.accionTexto, this.onAccion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1B23),
            ),
          ),
          if (accionTexto != null)
            TextButton(
              onPressed: onAccion,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(accionTexto!),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta cuadrada de acción rápida (para grids 2 columnas): ícono en círculo
/// de color + título (+ subtítulo opcional).
class AccionCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String? subtitulo;
  final Color color;
  final VoidCallback onTap;
  const AccionCard({
    super.key,
    required this.icon,
    required this.titulo,
    required this.color,
    required this.onTap,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitulo!,
              style: const TextStyle(fontSize: 12, color: AppColors.textoSuave),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Acceso en fila (ancho completo): círculo de color + título/subtítulo + chevron.
class AccionFila extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String? subtitulo;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Si > 0, muestra un círculo rojo con el número sobre el ícono (indica
  /// "tienes N cosas nuevas/pendientes aquí").
  final int badge;

  const AccionFila({
    super.key,
    required this.icon,
    required this.titulo,
    required this.color,
    required this.onTap,
    this.subtitulo,
    this.trailing,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              if (badge > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 19, minHeight: 19),
                    decoration: BoxDecoration(
                      color: AppColors.peligro,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.superficie, width: 1.5),
                    ),
                    child: Text(
                      badge > 9 ? '9+' : '$badge',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14.5)),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitulo!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textoSuave)),
                ],
              ],
            ),
          ),
          trailing ??
              const Icon(Icons.chevron_right, color: Color(0xFFBDB9CC)),
        ],
      ),
    );
  }
}

/// Chip/píldora de estado con color semántico.
class EstadoChip extends StatelessWidget {
  final String texto;
  final Color color;
  final IconData? icon;
  const EstadoChip(this.texto, {super.key, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Mapea un texto de estado de trámite a su color semántico.
  static Color colorDeEstado(String estado) {
    final e = estado.toLowerCase();
    if (e.contains('observ') || e.contains('devuel') || e.contains('rechaz')) {
      return AppColors.observado;
    }
    if (e.contains('aprob') || e.contains('finaliz') || e.contains('complet')) {
      return AppColors.exito;
    }
    if (e.contains('document') || e.contains('compuerta')) {
      return AppColors.compuerta;
    }
    return AppColors.primary;
  }
}

/// Estado vacío consistente (ícono grande + mensaje).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String? mensaje;
  final Widget? accion;
  const EmptyState({
    super.key,
    required this.icon,
    required this.titulo,
    this.mensaje,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            if (mensaje != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(mensaje!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textoSuave)),
            ],
            if (accion != null) ...[
              const SizedBox(height: AppSpacing.lg),
              accion!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Campana de notificaciones con badge de no-leídas (para el AppBar).
class NotifBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const NotifBell({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notificaciones',
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: const BoxDecoration(
                color: AppColors.peligro,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1),
              ),
            ),
          ),
      ],
    );
  }
}
