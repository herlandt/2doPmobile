import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../services/comunicacion_service.dart';
import '../../services/tramites_seguimiento_service.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authService = Get.find<AuthService>();
  int _noLeidas = 0;
  int _compuertaCount = 0;
  int _observadoCount = 0;

  @override
  void initState() {
    super.initState();
    _cargarNoLeidas();
    _cargarPendientes();
  }

  /// Cuenta trámites en compuerta (completar documentos) y observados, para
  /// mostrar el badge en la sección "Pendientes".
  Future<void> _cargarPendientes() async {
    try {
      final lista =
          await Get.find<TramitesSeguimientoService>().obtenerMisTramites();
      var comp = 0;
      var obs = 0;
      for (final t in lista) {
        if (t.esObservado) {
          obs++;
        } else if (t.esCompuerta) {
          comp++;
        }
      }
      if (mounted) {
        setState(() {
          _compuertaCount = comp;
          _observadoCount = obs;
        });
      }
    } catch (_) {
      // silencioso: si falla, simplemente no se muestran badges
    }
  }

  /// Cuenta las notificaciones no leídas para el badge de la campana.
  Future<void> _cargarNoLeidas() async {
    try {
      final lista = await Get.find<ComunicacionService>().getMisNotificaciones();
      var n = 0;
      for (final item in lista) {
        final leida = (item is Map) ? item['leida'] == true : false;
        if (!leida) n++;
      }
      if (mounted) setState(() => _noLeidas = n);
    } catch (_) {
      // silencioso: si falla, el badge simplemente no aparece
    }
  }

  void _confirmarLogout() {
    Get.defaultDialog(
      title: 'Cerrar sesión',
      middleText: '¿Deseas cerrar sesión?',
      textConfirm: 'Sí',
      textCancel: 'No',
      confirmTextColor: Colors.white,
      onConfirm: () {
        authService.logout();
        Get.offNamed(AppRoutes.login);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mi perfil',
            onPressed: () => Get.toNamed(AppRoutes.perfil),
          ),
          NotifBell(
            count: _noLeidas,
            onTap: () => Get.toNamed(AppRoutes.notificaciones)
                ?.then((_) => _cargarNoLeidas()),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: _confirmarLogout,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Obx(() {
        final usuario = authService.usuarioActual.value;
        if (usuario == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo
              Text(
                'Hola, ${usuario.nombre} 👋',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              const Text(
                'Bienvenido de nuevo',
                style: TextStyle(fontSize: 14, color: AppColors.textoSuave),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Acciones rápidas (grid 2 columnas)
              const SectionHeader('Acciones rápidas'),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  mainAxisExtent: 118,
                ),
                children: [
                  AccionCard(
                    icon: Icons.assignment_outlined,
                    titulo: 'Mis trámites',
                    color: AppColors.primary,
                    onTap: () => Get.toNamed(AppRoutes.misTramites),
                  ),
                  AccionCard(
                    icon: Icons.travel_explore,
                    titulo: 'Explorar e iniciar',
                    color: AppColors.exito,
                    onTap: () => Get.toNamed(AppRoutes.tramites),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Pendientes
              const SectionHeader('Pendientes'),
              AccionFila(
                icon: Icons.description_outlined,
                titulo: 'Completar documentos',
                subtitulo: 'Trámites que avanzaron y piden documentos',
                color: AppColors.compuerta,
                badge: _compuertaCount,
                onTap: () => Get.toNamed(AppRoutes.tramitesPendientesDocs)
                    ?.then((_) => _cargarPendientes()),
              ),
              const SizedBox(height: AppSpacing.sm),
              AccionFila(
                icon: Icons.warning_amber_rounded,
                titulo: 'Trámites observados',
                subtitulo: 'Devueltos para corregir',
                color: AppColors.observado,
                badge: _observadoCount,
                onTap: () => Get.toNamed(AppRoutes.tramitesObservados)
                    ?.then((_) => _cargarPendientes()),
              ),
            ],
          ),
        );
      }),
    );
  }
}
