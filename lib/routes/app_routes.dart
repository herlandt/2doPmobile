import 'package:get/get.dart';
import '../middlewares/auth_middleware.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
// C1 — Trámites base
import '../screens/tramites/tramites_lista_screen.dart';
import '../screens/tramites/tramite_detalle_screen.dart';
import '../screens/tramites/tramite_nuevo_screen.dart';
import '../screens/tramites/mis_tramites_screen.dart';
import '../screens/tramites/tramite_seguimiento_screen.dart';
// C2 — Registro y Subsanación
import '../screens/tramites/catalogo_tramites_screen.dart';
import '../screens/tramites/tramites_observados_screen.dart';
import '../screens/tramites/subir_documento_screen.dart';
// C3 — Línea de tiempo y Notificaciones
import '../screens/tramites/detalle_linea_tiempo_screen.dart';
import '../screens/comunicacion/notificaciones_screen.dart';
// Parte 2
import '../screens/tramites/iniciar_tramite_ia_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String splash = '/splash';

  // C1
  static const String tramites = '/tramites';
  static const String tramiteDetalle = '/tramite-detalle';
  static const String tramiteNuevo = '/tramite-nuevo';
  static const String misTramites = '/mis-tramites';
  static const String tramiteSeguimiento = '/tramite-seguimiento';

  // C2
  static const String catalogoTramites = '/catalogo-tramites';
  static const String tramitesObservados = '/tramites-observados';
  static const String subirDocumento = '/subir-documento';

  // C3
  static const String detalleLineaTiempo = '/detalle-linea-tiempo';
  static const String notificaciones = '/notificaciones';

  // Parte 2
  static const String iniciarTramiteIa = '/iniciar-tramite-ia';

  static List<GetPage> pages = [
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: register,
      page: () => const RegisterScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),

    // ── C1 ────────────────────────────────────────────────────────────────
    GetPage(
      name: tramites,
      page: () => const TramitesListaScreen(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: tramiteDetalle,
      page: () => const TramiteDetalleScreen(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: tramiteNuevo,
      page: () => const TramiteNuevoScreen(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: misTramites,
      page: () => const MisTramitesScreen(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: tramiteSeguimiento,
      page: () => const TramiteSeguimientoScreen(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),

    // ── C2 ────────────────────────────────────────────────────────────────
    GetPage(
      name: catalogoTramites,
      page: () => const CatalogoTramitesScreen(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: tramitesObservados,
      page: () => const TramitesObservadosScreen(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: subirDocumento,
      page: () => const SubirDocumentoScreen(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),

    // ── C3 ────────────────────────────────────────────────────────────────
    GetPage(
      name: detalleLineaTiempo,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return DetalleLineaTiempoScreen(
          tramiteId: args['tramiteId'],
          codigo: args['codigo'],
        );
      },
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: notificaciones,
      page: () => const NotificacionesScreen(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),

    // ── Parte 2 ────────────────────────────────────────────────────────────
    GetPage(
      name: iniciarTramiteIa,
      page: () => const IniciarTramiteIaScreen(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),

    // Raíz → login
    GetPage(
      name: '/',
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),
  ];
}
