// Tests de parsing fromJson/toJson de los modelos del dominio mobile.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/auth_model.dart';
import 'package:mobile/models/usuario_model.dart';
import 'package:mobile/models/politica_model.dart';

void main() {
  group('LoginResponse', () {
    test('fromJson / toJson roundtrip', () {
      final r = LoginResponse.fromJson({
        'token': 'T',
        'tipoToken': 'Bearer',
        'email': 'a@x',
        'nombre': 'A',
        'tipo': 'cliente',
      });
      expect(r.token, 'T');
      expect(r.toJson()['email'], 'a@x');
    });
  });

  group('Usuario', () {
    test('fromJson respeta defaults', () {
      final u = Usuario.fromJson({
        'id': 'u1',
        'nombre': 'A',
        'email': 'a@x',
      });
      expect(u.rol, 'cliente');
      expect(u.activo, isTrue);
    });
  });

  group('Politica', () {
    test('fromJson / copyWith', () {
      final p = Politica.fromJson({
        'id': 'p1',
        'nombre': 'P',
        'descripcion': 'd',
      });
      expect(p.estado, 'activa');
      expect(p.activo, isTrue);
      final p2 = p.copyWith(nombre: 'Q');
      expect(p2.nombre, 'Q');
      expect(p2.id, 'p1');
    });
  });

  group('ActividadDocumentos', () {
    test('fromJson lee lista de documentos', () {
      final ad = ActividadDocumentos.fromJson({
        'actividadId': 'a1',
        'actividadNombre': 'Verificar',
        'documentosRequeridos': ['CI', 'Foto'],
      });
      expect(ad.documentosRequeridos.length, 2);
    });
  });
}
