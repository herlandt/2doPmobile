// Cola offline para subidas de adjuntos (CU-33 reforzado).
//
// Persiste las tareas en `shared_preferences` (clave `upload.queue`) como
// un JSON array. Cuando el dispositivo recupera conexión (vía
// `NetworkController.hasConnection`), procesa la cola en FIFO con reintento
// exponencial (5s, 15s, 60s) y máx. 3 intentos por ítem.
//
// La cola tiene un tope de 50 ítems; al alcanzarlo, descarta los más
// antiguos en estado `completado` o `fallido` antes de aceptar nuevos.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/network_controller.dart';
import '../models/upload_task_model.dart';
import 'adjuntos_service.dart';

class UploadQueueService extends GetxService {
  static const String _prefsKey = 'upload.queue';
  static const int _maxItems = 50;
  static const int _maxIntentos = 3;
  static const List<Duration> _backoff = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 60),
  ];

  late final AdjuntosService _adjuntos;
  late final NetworkController _network;

  /// Lista observable de tareas (UI puede mostrar contador / detalle).
  final RxList<UploadTask> cola = <UploadTask>[].obs;

  Worker? _watcher;
  bool _procesando = false;
  // M2: reintento auto-reprogramado para tareas que quedan pendientes estando online.
  Timer? _reintentoTimer;
  bool _reintentoProgramado = false;

  @override
  void onInit() {
    super.onInit();
    _adjuntos = Get.find<AdjuntosService>();
    _network = Get.find<NetworkController>();
    _cargarDesdePrefs().then((_) {
      if (_network.hasConnection.value && _pendientes.isNotEmpty) {
        unawaited(procesarPendientes());
      }
    });

    _watcher = ever<bool>(_network.hasConnection, (online) {
      if (online && _pendientes.isNotEmpty) {
        unawaited(procesarPendientes());
      }
    });
  }

  @override
  void onClose() {
    _watcher?.dispose();
    _reintentoTimer?.cancel();
    super.onClose();
  }

  /// Cantidad de tareas pendientes (no completadas).
  int get totalPendientes => _pendientes.length;

  List<UploadTask> get _pendientes => cola
      .where((t) =>
          t.estado == UploadEstado.pendiente || t.estado == UploadEstado.subiendo)
      .toList();

  /// Encola una nueva tarea. Devuelve la tarea creada.
  Future<UploadTask> enqueue({
    required String tramiteId,
    required String actividadId,
    required String documentoNombre,
    required File archivo,
  }) async {
    _purgar();

    final task = UploadTask(
      id: _generarId(),
      tramiteId: tramiteId,
      actividadId: actividadId,
      documentoNombre: documentoNombre,
      archivoPath: archivo.path,
    );
    cola.add(task);
    await _persistir();
    return task;
  }

  /// Elimina una tarea (por ejemplo tras éxito o si el usuario la descarta).
  Future<void> remover(String id) async {
    cola.removeWhere((t) => t.id == id);
    await _persistir();
  }

  /// Limpia las tareas completadas (housekeeping invocable desde UI).
  Future<void> limpiarCompletadas() async {
    cola.removeWhere((t) => t.estado == UploadEstado.completado);
    await _persistir();
  }

  /// Procesa todas las tareas pendientes en FIFO. Idempotente — si ya hay
  /// otro lote en curso, no arranca uno nuevo.
  Future<void> procesarPendientes() async {
    if (_procesando) return;
    if (!_network.hasConnection.value) return;
    _procesando = true;
    try {
      // Trabajar sobre una copia para evitar mutaciones concurrentes.
      final pendientes = List<UploadTask>.from(_pendientes);
      for (final task in pendientes) {
        if (!_network.hasConnection.value) break;
        // Backoff no bloqueante: si la tarea aún está en espera, saltarla para
        // no frenar el resto de la cola.
        if (task.proximoIntento != null &&
            DateTime.now().isBefore(task.proximoIntento!)) {
          continue;
        }
        await _intentar(task);
      }
    } finally {
      _procesando = false;
      // M2: tras el lote, si quedaron tareas pendientes reintentables, reprogramar.
      // En `finally` para que corra aunque `_intentar` lance.
      _programarReintentoSiHaceFalta();
    }
  }

  /// M2: el Worker `ever` solo dispara cuando la conectividad pasa a `true`. Si
  /// una tarea falla de forma transitoria estando online, nada la reintentaría
  /// hasta perder y recuperar la conexión. Aquí agendamos otra pasada mientras
  /// queden tareas pendientes con reintentos disponibles.
  void _programarReintentoSiHaceFalta() {
    if (_reintentoProgramado) return;
    if (!_network.hasConnection.value) return;
    final quedan = cola.any((t) =>
        (t.estado == UploadEstado.pendiente ||
            t.estado == UploadEstado.subiendo) &&
        t.intentos < _maxIntentos);
    if (!quedan) return;

    // Programar la próxima pasada para el `proximoIntento` más cercano entre
    // las tareas pendientes reintentables, en vez de un retardo fijo. Así una
    // tarea con backoff corto no espera el máximo, y una sin backoff se toma
    // casi de inmediato (piso de 1s para no entrar en bucle apretado).
    final ahora = DateTime.now();
    DateTime? proximo;
    for (final t in cola) {
      if ((t.estado != UploadEstado.pendiente &&
              t.estado != UploadEstado.subiendo) ||
          t.intentos >= _maxIntentos) {
        continue;
      }
      final cuando = t.proximoIntento ?? ahora;
      if (proximo == null || cuando.isBefore(proximo)) {
        proximo = cuando;
      }
    }
    if (proximo == null) return;

    var espera = proximo.difference(ahora);
    if (espera < const Duration(seconds: 1)) {
      espera = const Duration(seconds: 1);
    }

    _reintentoProgramado = true;
    _reintentoTimer?.cancel();
    _reintentoTimer = Timer(espera, () {
      _reintentoProgramado = false;
      if (_network.hasConnection.value) {
        unawaited(procesarPendientes());
      }
    });
  }

  // ── interno ────────────────────────────────────────────────────────────

  Future<void> _intentar(UploadTask task) async {
    final indice = cola.indexWhere((t) => t.id == task.id);
    if (indice == -1) return;

    try {
      // Marcar `subiendo` y persistir DENTRO del try: si la persistencia (o la
      // subida) falla, el `catch` revierte el estado y la tarea no queda
      // colgada en `subiendo`.
      cola[indice].estado = UploadEstado.subiendo;
      cola.refresh();
      await _persistir();

      final archivo = File(task.archivoPath);
      if (!archivo.existsSync()) {
        cola[indice].estado = UploadEstado.fallido;
        cola[indice].ultimoError = 'Archivo no encontrado en disco.';
        cola.refresh();
        await _persistir();
        return;
      }

      await _adjuntos.subirAdjunto(
        tramiteId: task.tramiteId,
        actividadId: task.actividadId,
        documentoNombre: task.documentoNombre,
        archivo: archivo,
      );

      cola[indice].estado = UploadEstado.completado;
      cola.refresh();
      await _persistir();
    } catch (e) {
      cola[indice].intentos += 1;
      cola[indice].ultimoError = e.toString();

      if (cola[indice].intentos >= _maxIntentos) {
        cola[indice].estado = UploadEstado.fallido;
      } else {
        cola[indice].estado = UploadEstado.pendiente;
        // Backoff NO bloqueante: marcar cuándo puede reintentarse sin dormir el
        // bucle, para no bloquear el resto de la cola de subidas.
        final esperaIdx = min(cola[indice].intentos - 1, _backoff.length - 1);
        cola[indice].proximoIntento = DateTime.now().add(_backoff[esperaIdx]);
      }
      cola.refresh();
      await _persistir();
    }
  }

  /// Evita que la cola crezca sin límite: descarta primero completadas,
  /// luego fallidas, hasta dejar como máximo [_maxItems] entradas.
  ///
  /// Nunca elimina tareas en estado `subiendo` (una subida en curso no debe
  /// perderse). Si tras purgar completadas/fallidas la cola sigue llena, libera
  /// un único hueco descartando la tarea `pendiente` más antigua. Se invoca con
  /// `cola.length == _maxItems`, así que basta liberar 1 hueco.
  void _purgar() {
    if (cola.length < _maxItems) return;
    cola.removeWhere((t) => t.estado == UploadEstado.completado);
    if (cola.length < _maxItems) return;
    cola.removeWhere((t) => t.estado == UploadEstado.fallido);
    if (cola.length < _maxItems) return;
    // Solo quedan pendientes/subiendo. Descartar la pendiente más antigua de
    // forma controlada; si no hay ninguna pendiente (todo `subiendo`), no se
    // elimina nada y se acepta el desborde momentáneo.
    final idx = cola.indexWhere((t) => t.estado == UploadEstado.pendiente);
    if (idx == -1) return;
    final descartada = cola.removeAt(idx);
    print(
      '⚠️ UploadQueue: cola llena, descartada tarea pendiente más antigua '
      '${descartada.id} (${descartada.documentoNombre}).',
    );
  }

  Future<void> _persistir() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = cola.map((t) => t.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(lista));
  }

  Future<void> _cargarDesdePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      final tareas = data
          .map((e) => UploadTask.fromJson(e as Map<String, dynamic>))
          .toList();
      // Tareas que quedaron en `subiendo` (la app se cerró a mitad de una
      // subida) son huérfanas: ningún flujo las reanuda. Normalizarlas a
      // `pendiente` y limpiar el backoff para que el siguiente lote las tome.
      for (final t in tareas) {
        if (t.estado == UploadEstado.subiendo) {
          t.estado = UploadEstado.pendiente;
          t.proximoIntento = null;
        }
      }
      cola.assignAll(tareas);
    } catch (_) {
      // JSON corrupto — descartar.
      await prefs.remove(_prefsKey);
    }
  }

  String _generarId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final r = Random().nextInt(1 << 32).toRadixString(36);
    return 'up_${ts}_$r';
  }
}
