// Widget reutilizable para grabar voz vía `record` (CU-39 / CU-40).
//
// Flujo:
//  1. El usuario pulsa "Grabar" → solicitamos permiso de micrófono.
//  2. Iniciamos `AudioRecorder` apuntando a un fichero temporal.
//  3. Mostramos cronómetro y botón "Detener".
//  4. Al detener, emitimos el `File` por el callback `onGrabacion`.
//
// El consumidor decide qué hacer con el archivo (subirlo, descartarlo, etc.).

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

enum _EstadoGrabacion { inactivo, pidiendoPermiso, grabando, finalizando }

class GrabadorVozWidget extends StatefulWidget {
  final void Function(File audio) onGrabacion;
  final Duration limite;

  const GrabadorVozWidget({
    Key? key,
    required this.onGrabacion,
    this.limite = const Duration(minutes: 2),
  }) : super(key: key);

  @override
  State<GrabadorVozWidget> createState() => _GrabadorVozWidgetState();
}

class _GrabadorVozWidgetState extends State<GrabadorVozWidget> {
  final AudioRecorder _recorder = AudioRecorder();
  _EstadoGrabacion _estado = _EstadoGrabacion.inactivo;
  Timer? _ticker;
  int _segundos = 0;
  String _error = '';
  String? _pathDestino;

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<bool> _solicitarPermiso() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _iniciar() async {
    setState(() {
      _error = '';
      _estado = _EstadoGrabacion.pidiendoPermiso;
    });

    final permitido = await _solicitarPermiso();
    if (!permitido) {
      setState(() {
        _estado = _EstadoGrabacion.inactivo;
        _error = 'Permiso de micrófono denegado. Habilítalo en ajustes.';
      });
      return;
    }

    try {
      final dir = await path_provider.getTemporaryDirectory();
      final path =
          '${dir.path}/grab_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _pathDestino = path;

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      setState(() {
        _estado = _EstadoGrabacion.grabando;
        _segundos = 0;
      });

      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _segundos += 1);
        if (_segundos >= widget.limite.inSeconds) _detener();
      });
    } catch (e) {
      setState(() {
        _estado = _EstadoGrabacion.inactivo;
        _error = 'No se pudo iniciar la grabación: $e';
      });
    }
  }

  Future<void> _detener() async {
    if (_estado != _EstadoGrabacion.grabando) return;
    setState(() => _estado = _EstadoGrabacion.finalizando);
    _ticker?.cancel();

    try {
      final path = await _recorder.stop();
      final pathFinal = path ?? _pathDestino;
      if (pathFinal == null) {
        setState(() {
          _estado = _EstadoGrabacion.inactivo;
          _error = 'No se generó el archivo.';
        });
        return;
      }
      final file = File(pathFinal);
      if (!file.existsSync() || file.lengthSync() < 1024) {
        setState(() {
          _estado = _EstadoGrabacion.inactivo;
          _error = 'Grabación demasiado corta.';
        });
        return;
      }
      widget.onGrabacion(file);
      setState(() {
        _estado = _EstadoGrabacion.inactivo;
        _segundos = 0;
      });
    } catch (e) {
      setState(() {
        _estado = _EstadoGrabacion.inactivo;
        _error = 'Error al detener: $e';
      });
    }
  }

  String _formato(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    final esGrabando = _estado == _EstadoGrabacion.grabando;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              esGrabando ? Icons.fiber_manual_record : Icons.mic,
              color: esGrabando ? Colors.red : Colors.deepPurple,
            ),
            const SizedBox(width: 8),
            if (esGrabando)
              Text(
                _formato(_segundos),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            const Spacer(),
            if (!esGrabando &&
                _estado != _EstadoGrabacion.pidiendoPermiso &&
                _estado != _EstadoGrabacion.finalizando)
              OutlinedButton.icon(
                onPressed: _iniciar,
                icon: const Icon(Icons.mic),
                label: const Text('Grabar'),
              ),
            if (_estado == _EstadoGrabacion.pidiendoPermiso ||
                _estado == _EstadoGrabacion.finalizando)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (esGrabando)
              ElevatedButton.icon(
                onPressed: _detener,
                icon: const Icon(Icons.stop),
                label: const Text('Detener'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        if (_error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _error,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
