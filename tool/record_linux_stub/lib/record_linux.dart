import 'package:record_platform_interface/record_platform_interface.dart';

/// Stub de la implementación Linux del plugin `record`.
///
/// Esta app solo se compila para Android/iOS; el paquete real `record_linux`
/// 0.7.2 (el único compatible con `record 5.x`, máximo para Dart 3.11.x) no
/// implementa la interfaz actual (`startStream`) y rompe `kernel_snapshot`.
///
/// Este stub solo debe COMPILAR: forwarda cualquier llamada a `noSuchMethod`,
/// lo cual satisface los miembros abstractos de la interfaz. Nunca se ejecuta
/// en móvil (no hay registro Linux en el build de Android/iOS).
class RecordLinux extends RecordPlatform {
  /// Registro del plugin federado (solo se invoca en builds de Linux).
  static void registerWith() {
    RecordPlatform.instance = RecordLinux();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
        'record_linux no está soportado en esta aplicación.',
      );
}
