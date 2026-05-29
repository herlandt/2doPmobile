// CU-43 — Badge visual del nivel de riesgo de un trámite.

import 'package:flutter/material.dart';
import '../models/tramite_riesgo_model.dart';

class ChipRiesgoWidget extends StatelessWidget {
  final NivelRiesgo nivel;
  final double? probSuperarSla;
  final bool mostrarProb;

  const ChipRiesgoWidget({
    Key? key,
    required this.nivel,
    this.probSuperarSla,
    this.mostrarProb = true,
  }) : super(key: key);

  Color _color() {
    switch (nivel) {
      case NivelRiesgo.alto:
        return Colors.red.shade600;
      case NivelRiesgo.medio:
        return Colors.amber.shade700;
      case NivelRiesgo.bajo:
        return Colors.green.shade600;
      case NivelRiesgo.desconocido:
        return Colors.grey.shade600;
    }
  }

  String _label() {
    switch (nivel) {
      case NivelRiesgo.alto:
        return 'Alto';
      case NivelRiesgo.medio:
        return 'Medio';
      case NivelRiesgo.bajo:
        return 'Bajo';
      case NivelRiesgo.desconocido:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final pct = probSuperarSla != null
        ? '${(probSuperarSla! * 100).toStringAsFixed(0)}%'
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            _label(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (mostrarProb && pct != null) ...[
            const SizedBox(width: 6),
            Text(
              pct,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
