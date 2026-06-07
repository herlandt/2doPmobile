import 'package:flutter/material.dart';

/// Sistema de diseño del cliente.
///
/// Paleta basada en deepPurple (la existente, que al usuario le gusta) con
/// acentos SEMÁNTICOS consistentes — en vez de los colores arcoíris que tenía
/// cada botón. Más constantes de espaciado y radios para un look uniforme.
class AppColors {
  static const Color primary = Color(0xFF5E35B1); // deepPurple 600
  static const Color primaryDark = Color(0xFF4527A0);

  // Acentos semánticos (usar SIEMPRE estos, no colores sueltos):
  static const Color compuerta = Color(0xFF1565C0); // azul · avanzó, pide docs
  static const Color observado = Color(0xFFE65100); // naranja · corregir
  static const Color exito = Color(0xFF2E7D32); // verde · ok
  static const Color ia = Color(0xFF6A1B9A); // violeta · IA
  static const Color peligro = Color(0xFFC62828); // rojo · error

  static const Color fondo = Color(0xFFF5F4FA); // fondo de scaffold
  static const Color superficie = Colors.white;
  static const Color textoSuave = Color(0xFF6B6B76);
  static const Color borde = Color(0xFFE6E3F0);
}

/// Espaciado en una escala de 4.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Radios de esquina.
class AppRadius {
  static const double sm = 10;
  static const double card = 16;
  static const double button = 12;
  static const double pill = 999;
}

/// Tema Material 3 de la app. Mantiene APIs estables (sin CardTheme, que cambia
/// entre versiones — las tarjetas se estilizan en AppCard).
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.fondo,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.fondo,
      foregroundColor: Color(0xFF1D1B23),
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF1D1B23),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.borde),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
  );
}
