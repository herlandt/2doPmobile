import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class NetworkController extends GetxService {
  final Connectivity _connectivity = Connectivity();
  late final StreamSubscription<ConnectivityResult> _subscription;

  final RxBool hasConnection = true.obs;

  // El primer chequeo se hace antes de que MaterialApp esté montado, así que
  // todavía no hay un Overlay donde mostrar un Get.snackbar (provoca NPE).
  // Marcamos la primera actualización como "silenciosa" — solo actualiza el RxBool.
  bool _bootstrapped = false;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  Future<void> _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
  }

  void _updateStatus(ConnectivityResult result) {
    final isConnected = result != ConnectivityResult.none;
    final changed = hasConnection.value != isConnected;
    hasConnection.value = isConnected;

    // Primer disparo: solo guarda el estado, no muestra snackbar (no hay Overlay aún).
    if (!_bootstrapped) {
      _bootstrapped = true;
      return;
    }

    if (!changed) {
      return;
    }

    // Espera al siguiente frame para garantizar que el Overlay ya esté disponible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isConnected) {
        Get.snackbar(
          'Conexión restaurada',
          'La app volvió a estar en línea.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Sin conexión',
          'Revisa tu internet para seguir usando la app.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}