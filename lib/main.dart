import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_routes.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/tramites_service.dart';
import 'services/tramites_envio_service.dart';
import 'services/tramites_seguimiento_service.dart';
import 'services/comunicacion_service.dart';
import 'services/adjuntos_service.dart';
import 'services/push_notification_service.dart';
// Parte 2
import 'services/ia_service.dart';
import 'services/documento_archivo_service.dart';
import 'services/upload_queue_service.dart';
import 'controllers/network_controller.dart';
import 'widgets/chat_agente_ia.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('📱 Iniciando aplicación...');
  
  // Inicializar StorageService
  print('💾 Inicializando StorageService...');
  final storageService = StorageService();
  await storageService.init();
  print('✅ StorageService inicializado');
  
  // Registrar servicios
  print('🔧 Registrando servicios con GetX...');
  Get.put<StorageService>(storageService);
  Get.put<AuthService>(
    AuthService(storageService: storageService),
    permanent: true,
  );
  Get.put<TramitesService>(
    TramitesService(),
    permanent: true,
  );
  Get.put<TramitesEnvioService>(
    TramitesEnvioService(),
    permanent: true,
  );
  Get.put<TramitesSeguimientoService>(
    TramitesSeguimientoService(),
    permanent: true,
  );
  Get.put<ComunicacionService>(
    ComunicacionService(),
    permanent: true,
  );
  Get.put<AdjuntosService>(
    AdjuntosService(),
    permanent: true,
  );
  Get.put<NetworkController>(
    NetworkController(),
    permanent: true,
  );

  // ── Parte 2 ──────────────────────────────────────────────────────────
  // IaService — CU-39/CU-40/CU-42/CU-43 (sugerir, dictar, riesgo, ruta IA).
  Get.put<IaService>(IaService(), permanent: true);
  // DocumentoArchivoService — CU-32/33/34/35 (repositorio documental).
  Get.put<DocumentoArchivoService>(DocumentoArchivoService(), permanent: true);
  // UploadQueueService — CU-33 reforzado: cola offline de adjuntos.
  // Depende de AdjuntosService + NetworkController (ya inyectados arriba).
  Get.put<UploadQueueService>(UploadQueueService(), permanent: true);

  final pushService = PushNotificationService();
  Get.put<PushNotificationService>(
    pushService,
    permanent: true,
  );
  await pushService.init();

  // Arranca el polling cuando el usuario se autentica y lo detiene al salir.
  final authService = Get.find<AuthService>();
  ever<bool>(authService.isAuthenticated, (autenticado) {
    if (autenticado) {
      pushService.iniciarPolling();
    } else {
      pushService.detenerPolling();
    }
  });
  if (authService.isAuthenticated.value) {
    pushService.iniciarPolling();
  }
  print('✅ Servicios registrados');

  print('🎬 Ejecutando app...\n');
  runApp(const MyApp());
}

/// Ruta actual del navegador como observable. La mantiene actualizada el
/// `routingCallback` de [GetMaterialApp] (ver más abajo). Necesario porque
/// `Get.currentRoute` es una propiedad estática, no reactiva — un `Obx` que
/// la lea no se redibuja al navegar.
final RxString rutaActualRx = RxString('');

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Sistema de Gestión de Trámites',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.pages,
      debugShowCheckedModeBanner: false,
      // Propaga cada cambio de ruta al RxString para que el FAB sepa cuándo
      // ocultarse en login/register.
      routingCallback: (routing) {
        final actual = routing?.current;
        if (actual != null && actual != rutaActualRx.value) {
          rutaActualRx.value = actual;
        }
      },
      // CU-31: el agente IA es un panel flotante accesible desde cualquier pantalla
      // del sistema. Aquí lo inyectamos por encima del árbol de rutas.
      builder: (context, child) => _AgenteFlotanteGlobal(child: child),
    );
  }
}

/// Stack que coloca un FAB del Agente IA sobre cualquier pantalla autenticada.
/// No se muestra en login/register para evitar invitar a usuarios no autenticados.
class _AgenteFlotanteGlobal extends StatelessWidget {
  final Widget? child;
  const _AgenteFlotanteGlobal({required this.child});

  static const _rutasSinAgente = {AppRoutes.login, AppRoutes.register, '/', '/splash'};

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child ?? const SizedBox.shrink(),
        Obx(() {
          final auth = Get.find<AuthService>();
          if (!auth.isAuthenticated.value) return const SizedBox.shrink();
          // Lee la Rx — el Obx ahora SÍ se rebuilds al navegar.
          final ruta = rutaActualRx.value;
          if (_rutasSinAgente.contains(ruta)) return const SizedBox.shrink();
          return Positioned(
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Semantics(
                label: 'Asistente Virtual',
                button: true,
                child: FloatingActionButton(
                  heroTag: 'agente-fab-global',
                  backgroundColor: Colors.indigo,
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    // Sin parámetros → ChatAgenteIA deduce módulo y trámite del routing.
                    builder: (_) => const ChatAgenteIA(),
                  ),
                  child: const Icon(Icons.support_agent, color: Colors.white),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
