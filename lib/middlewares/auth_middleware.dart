import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';

/// Middleware para proteger rutas que requieren autenticación
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 9;

  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();

    if (!authService.verificarAutenticacion()) {
      return RouteSettings(name: '/login');
    }

    return null;
  }
}
