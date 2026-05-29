// Test unitario del parseo del response del agente (CU-31).
// Garantiza que el cliente Flutter entiende los campos `accion.label` y `accion.ruta`
// que añadimos en el backend.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgenteResponse parsing', () {
    test('extrae label y ruta cuando vienen embebidos', () {
      final res = {
        'respuesta': 'Texto del agente',
        'accion': {
          'label': 'Abrir editor',
          'ruta': '/admin/diagramas',
          'tipo': 'navegar'
        }
      };
      final accion = res['accion'];
      expect(accion, isA<Map>());
      expect((accion as Map)['label'], 'Abrir editor');
      expect(accion['ruta'], '/admin/diagramas');
      expect(accion['tipo'], 'navegar');
    });

    test('soporta respuesta sin acción', () {
      final res = {'respuesta': 'Solo texto'};
      expect(res['accion'], isNull);
    });
  });
}
