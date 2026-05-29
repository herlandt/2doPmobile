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

  @override
  void onInit() {
    super.onInit();
    _adjuntos = Get.find<AdjuntosService>();
    _network = Get.find<NetworkController>();
    _cargarDesdePrefs();

    _watcher = ever<bool>(_network.hasConnection, (online) {
      if (online && _pendientes.isNotEmpty) {
        unawaited(procesarPendientes());
      }
    });
  }

  @override
  void onClose() {
    _watcher?.dispose();
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
        await _intentar(task);
      }
    } finally {
      _procesando = false;
    }
  }

  // ── interno ────────────────────────────────────────────────────────────

  Future<void> _intentar(UploadTask task) async {
    final indice = cola.indexWhere((t) => t.id == task.id);
    if (indice == -1) return;

    cola[indice].estado = UploadEstado.subiendo;
    cola.refresh();
    await _persistir();

    try {
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
        // Backoff antes de seguir con la siguiente.
        final esperaIdx = min(cola[indice].intentos - 1, _backoff.length - 1);
        await Future.delayed(_backoff[esperaIdx]);
      }
      cola.refresh();
      await _persistir();
    }
  }

  /// Evita que la cola crezca sin límite: descarta primero completadas,
  /// luego fallidas, hasta dejar como máximo [_maxItems] entradas.
  void _purgar() {
    if (cola.length < _maxItems) return;
    cola.removeWhere((t) => t.estado == UploadEstado.completado);
    if (cola.length < _maxItems) return;
    cola.removeWhere((t) => t.estado == UploadEstado.fallido);
    while (cola.length >= _maxItems) {
      cola.removeAt(0);
    }
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
