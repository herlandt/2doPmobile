// Smoke test del bottom-sheet del chat del agente (CU-31).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile/widgets/chat_agente_ia.dart';
import 'package:mobile/services/comunicacion_service.dart';

class _FakeComunicacionService extends GetxService
    implements ComunicacionService {
  @override
  Future<Map<String, dynamic>> consultarAgenteIA(
      String consulta, String moduloActivo,
      {String? tramiteIdOpcional}) async {
    return {
      'respuesta': 'Respuesta simulada del agente.',
      'accion': {
        'label': 'Ir a algún lado',
        'ruta': '/home',
        'tipo': 'navegar',
      }
    };
  }

  @override
  Future<List<dynamic>> getMisNotificaciones() async => <dynamic>[];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.reset();
    Get.put<ComunicacionService>(_FakeComunicacionService());
  });

  testWidgets('Chat del agente muestra el saludo contextual',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatAgenteIA(pantallaActual: 'Dashboard'),
      ),
    ));

    expect(find.textContaining('Dashboard'), findsOneWidget);
    expect(find.text('Asistente de Soporte'), findsOneWidget);
  });
}
