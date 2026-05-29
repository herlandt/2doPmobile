// CU-28 — Servicio de notificaciones push.
//
// Estrategia híbrida:
//  1) SSE (Server-Sent Events) sobre HTTP — push real, latencia < 1s, sin
//     Firebase. Funciona mientras la app esté abierta (foreground o background
//     no terminado por el SO).
//  2) Polling de respaldo, ralentizado a 2 min cuando SSE está conectado y
//     acelerado a 30 s cuando la conexión SSE se cae.
//
// Cuando la app está cerrada o el SO la termina, ninguna de las dos estrategias
// llega: para ese caso se requiere FCM, que queda como mejora futura.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../config/environment.dart';
import 'auth_service.dart';
import 'comunicacion_service.dart';

class PushNotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  late final ComunicacionService _comunicacion;
  late final AuthService _auth;

  Timer? _poll;
  Timer? _reconectarSse;
  http.Client? _sseClient;
  StreamSubscription<String>? _sseSub;
  bool _sseConectado = false;
  final Set<String> _yaNotificadas = <String>{};
  bool _inicializado = false;

  // El polling se ralentiza cuando SSE está activo (1 cada 2 min) porque solo
  // sirve para limpiar el set de IDs y compensar mensajes perdidos puntuales.
  static const Duration _pollRapido = Duration(seconds: 30);
  static const Duration _pollLento = Duration(minutes: 2);

  static const String _channelId = 'tramites_estado';
  static const String _channelName = 'Cambios de estado de trámites';
  static const String _channelDesc =
      'Avisos al cliente cuando un trámite cambia de estado o requiere acción.';

  @override
  void onInit() {
    super.onInit();
    _comunicacion = Get.find<ComunicacionService>();
    _auth = Get.find<AuthService>();
  }

  Future<void> init() async {
    if (_inicializado) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );

    _inicializado = true;
  }

  /// Arranca SSE + polling de respaldo. Llamar tras login.
  void iniciarPolling({Duration intervalo = _pollRapido}) {
    _conectarSse();
    _poll?.cancel();
    _verificar();
    _poll = Timer.periodic(_pollActual(intervalo), (_) => _verificar());
  }

  void detenerPolling() {
    _poll?.cancel();
    _poll = null;
    _reconectarSse?.cancel();
    _reconectarSse = null;
    _cerrarSse();
    _yaNotificadas.clear();
  }

  // ── SSE ──────────────────────────────────────────────────────────────────

  Future<void> _conectarSse() async {
    if (_sseConectado) return;
    final token = _auth.getToken();
    if (token == null || token.isEmpty) return;

    final url = Uri.parse('${Environment.apiUrl}/notificaciones/stream');
    final req = http.Request('GET', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'text/event-stream'
      ..headers['Cache-Control'] = 'no-cache';

    final client = http.Client();
    _sseClient = client;
    try {
      final response = await client.send(req);
      if (response.statusCode != 200) {
        _sobreErrorSse('http ${response.statusCode}');
        return;
      }
      _sseConectado = true;
      _ajustarRitmoPolling();
      String evento = 'message';
      final buffer = StringBuffer();

      _sseSub = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (linea) {
          if (linea.isEmpty) {
            // Línea en blanco → fin de evento, despachar.
            final data = buffer.toString();
            buffer.clear();
            if (data.isNotEmpty) _despacharEventoSse(evento, data);
            evento = 'message';
            return;
          }
          if (linea.startsWith(':')) {
            // Comentario / heartbeat — ignorar.
            return;
          }
          if (linea.startsWith('event:')) {
            evento = linea.substring(6).trim();
          } else if (linea.startsWith('data:')) {
            if (buffer.isNotEmpty) buffer.write('\n');
            buffer.write(linea.substring(5).trim());
          }
        },
        onError: (e) => _sobreErrorSse(e.toString()),
        onDone: () => _sobreErrorSse('stream cerrado'),
        cancelOnError: true,
      );
    } catch (e) {
      _sobreErrorSse(e.toString());
    }
  }

  Future<void> _despacharEventoSse(String evento, String dataJson) async {
    if (evento != 'notificacion') return;
    try {
      final n = json.decode(dataJson) as Map<String, dynamic>;
      final id = (n['id'] ?? n['_id'] ?? '').toString();
      final leida = n['leida'] == true;
      if (id.isEmpty || leida || _yaNotificadas.contains(id)) return;
      await _mostrar(
        id: id,
        titulo: (n['titulo'] ?? 'Aviso').toString(),
        mensaje: (n['mensaje'] ?? '').toString(),
        tipo: (n['tipo'] ?? '').toString(),
      );
      _yaNotificadas.add(id);
    } catch (_) {
      // payload mal formado — ignorar
    }
  }

  void _sobreErrorSse(String motivo) {
    if (_sseConectado) {
      _sseConectado = false;
      _ajustarRitmoPolling();
    }
    _cerrarSse();
    // Reintenta con backoff (5 s, 10 s, 20 s…) limitado a 30 s.
    _reconectarSse?.cancel();
    _reconectarSse = Timer(const Duration(seconds: 5), _conectarSse);
  }

  void _cerrarSse() {
    _sseSub?.cancel();
    _sseSub = null;
    _sseClient?.close();
    _sseClient = null;
    _sseConectado = false;
  }

  Duration _pollActual(Duration solicitado) {
    return _sseConectado ? _pollLento : solicitado;
  }

  void _ajustarRitmoPolling() {
    if (_poll == null) return;
    _poll!.cancel();
    _poll = Timer.periodic(
      _sseConectado ? _pollLento : _pollRapido,
      (_) => _verificar(),
    );
  }

  // ── Polling de respaldo ──────────────────────────────────────────────────

  Future<void> _verificar() async {
    try {
      final lista = await _comunicacion.getMisNotificaciones();
      // Purgamos IDs que ya no existen en el backend para evitar crecimiento ilimitado.
      final idsVivos = lista
          .map((n) => (n['id'] ?? n['_id'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet();
      _yaNotificadas.retainWhere(idsVivos.contains);

      for (final n in lista) {
        final id = (n['id'] ?? n['_id'] ?? '').toString();
        final leida = n['leida'] == true;
        if (id.isEmpty || leida || _yaNotificadas.contains(id)) continue;
        await _mostrar(
          id: id,
          titulo: (n['titulo'] ?? 'Aviso').toString(),
          mensaje: (n['mensaje'] ?? '').toString(),
          tipo: (n['tipo'] ?? '').toString(),
        );
        _yaNotificadas.add(id);
      }
    } catch (_) {
      // sin red o sin sesión — se reintenta en el próximo tick
    }
  }

  Future<void> _mostrar({
    required String id,
    required String titulo,
    required String mensaje,
    required String tipo,
  }) async {
    if (!_inicializado) await init();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: _importanciaPorTipo(tipo),
      priority: Priority.high,
      ticker: titulo,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id.hashCode,
      titulo,
      mensaje,
      details,
      payload: id,
    );
  }

  Importance _importanciaPorTipo(String tipo) {
    switch (tipo) {
      // Parte 1
      case 'sla_vencido':
        return Importance.max;
      case 'cambio_estado':
      case 'asignacion':
        return Importance.high;

      // Parte 2 — eventos generados por la IA (CU-42 / CU-43 / CU-45)
      case 'riesgo_demora_alto':
        return Importance.max;
      case 'anomalia_detectada':
        return Importance.high;
      case 'asignacion_auto':
        return Importance.high;

      default:
        return Importance.defaultImportance;
    }
  }
}
