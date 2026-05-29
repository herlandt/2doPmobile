// CU-40 — Iniciar trámite con IA: el ciudadano describe lo que necesita
// (texto o voz) y la app sugiere la política correspondiente con un top-3.
//
// Flujo:
//  1. Escribir descripción (o grabar audio).
//  2. Tap "Analizar" → IaService.sugerirPolitica → top 3 candidatos.
//  3. Confirmar la sugerida o elegir otra → IaService.confirmarSugerencia
//     (registra feedback ACEPTADA / CAMBIADA).
//  4. Inicia el trámite real con TramitesEnvioService.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/sugerencia_politica_model.dart';
import '../../services/auth_service.dart';
import '../../services/ia_service.dart';
import '../../services/tramites_envio_service.dart';
import '../../widgets/grabador_voz_widget.dart';

class IniciarTramiteIaScreen extends StatefulWidget {
  const IniciarTramiteIaScreen({Key? key}) : super(key: key);

  @override
  State<IniciarTramiteIaScreen> createState() => _IniciarTramiteIaScreenState();
}

enum _Paso { describir, analizando, elegir, confirmando, exito }

class _IniciarTramiteIaScreenState extends State<IniciarTramiteIaScreen> {
  late final IaService _iaSvc;
  late final TramitesEnvioService _envioSvc;
  late final AuthService _authSvc;

  final TextEditingController _descCtrl = TextEditingController();

  _Paso _paso = _Paso.describir;
  File? _audio;
  SugerenciaPolitica? _sugerencia;
  String _seleccionadaId = '';
  String _errorMsg = '';
  String _codigoTramite = '';

  @override
  void initState() {
    super.initState();
    _iaSvc = Get.find<IaService>();
    _envioSvc = Get.find<TramitesEnvioService>();
    _authSvc = Get.find<AuthService>();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _analizar() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty && _audio == null) {
      setState(() => _errorMsg = 'Describe lo que necesitas o graba un audio.');
      return;
    }
    setState(() {
      _paso = _Paso.analizando;
      _errorMsg = '';
    });
    try {
      final s = await _iaSvc.sugerirPolitica(
        descripcion: desc.isEmpty ? '(audio)' : desc,
        audio: _audio,
      );
      setState(() {
        _sugerencia = s;
        _seleccionadaId = s.politicaSugeridaId;
        _paso = _Paso.elegir;
      });
    } on IaException catch (e) {
      setState(() {
        _paso = _Paso.describir;
        _errorMsg = _mensajeIa(e);
      });
    } catch (e) {
      setState(() {
        _paso = _Paso.describir;
        _errorMsg = 'No se pudo procesar tu descripción: $e';
      });
    }
  }

  String _mensajeIa(IaException e) {
    if (e.statusCode == 503 || e.code == 'IA_NO_DISPONIBLE') {
      return 'El asistente no está disponible. Elige tu trámite manualmente desde el catálogo.';
    }
    if (e.code == 'IA_TIMEOUT') {
      return 'Tarda más de lo esperado. Intenta de nuevo.';
    }
    return 'Error de la IA: ${e.code}';
  }

  Future<void> _confirmar() async {
    final s = _sugerencia;
    if (s == null || _seleccionadaId.isEmpty) return;
    setState(() {
      _paso = _Paso.confirmando;
      _errorMsg = '';
    });
    try {
      await _iaSvc.confirmarSugerencia(
        sugerenciaId: s.sugerenciaId,
        politicaConfirmadaId: _seleccionadaId,
      );

      // Iniciar el trámite con la política confirmada.
      final clienteId = _authSvc.usuarioActual.value?.id ?? '';
      if (clienteId.isEmpty) {
        setState(() {
          _paso = _Paso.elegir;
          _errorMsg = 'No se pudo obtener el usuario activo.';
        });
        return;
      }
      final result = await _envioSvc.iniciarTramiteC2(_seleccionadaId, clienteId);
      final codigo = (result['codigo'] ?? result['tramiteId'] ?? 'N/D').toString();
      setState(() {
        _codigoTramite = codigo;
        _paso = _Paso.exito;
      });
    } catch (e) {
      setState(() {
        _paso = _Paso.elegir;
        _errorMsg = 'No se pudo iniciar el trámite: $e';
      });
    }
  }

  Future<void> _cancelarSugerencia() async {
    final s = _sugerencia;
    if (s != null) {
      try {
        await _iaSvc.cancelarSugerencia(s.sugerenciaId);
      } catch (_) {
        // ignoramos errores en la cancelación
      }
    }
    setState(() {
      _sugerencia = null;
      _seleccionadaId = '';
      _paso = _Paso.describir;
      _errorMsg = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar trámite con IA'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_paso) {
      case _Paso.describir:
      case _Paso.analizando:
        return _vistaDescribir();
      case _Paso.elegir:
      case _Paso.confirmando:
        return _vistaElegir();
      case _Paso.exito:
        return _vistaExito();
    }
  }

  Widget _vistaDescribir() {
    final analizando = _paso == _Paso.analizando;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Colors.deepPurple.shade50,
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.deepPurple),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Describe lo que necesitas en tus propias palabras. La IA te sugerirá la política correcta.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descCtrl,
          maxLines: 5,
          maxLength: 600,
          enabled: !analizando,
          decoration: const InputDecoration(
            labelText: 'Describe tu trámite',
            hintText:
                'Ej: Necesito una nueva conexión eléctrica para mi casa nueva.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GrabadorVozWidget(
                onGrabacion: (file) {
                  setState(() {
                    _audio = file;
                    _errorMsg = '';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Audio listo para enviar.')),
                  );
                },
              ),
            ),
          ],
        ),
        if (_audio != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.graphic_eq, color: Colors.deepPurple, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Audio adjunto (${(_audio!.lengthSync() / 1024).toStringAsFixed(0)} KB)',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: analizando ? null : () => setState(() => _audio = null),
                child: const Text('Quitar'),
              ),
            ],
          ),
        ],
        if (_errorMsg.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorMsg,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: analizando ? null : _analizar,
          icon: analizando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(analizando ? 'Analizando…' : 'Analizar con IA'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _vistaElegir() {
    final s = _sugerencia!;
    final confirmando = _paso == _Paso.confirmando;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Colors.deepPurple.shade50,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.deepPurple),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sugerencia con ${(s.confianza * 100).toStringAsFixed(0)}% de confianza',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Elige la política correcta:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (final c in s.top3) _opcion(c, s.politicaSugeridaId),
        if (_errorMsg.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_errorMsg,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: confirmando ? null : _cancelarSugerencia,
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: (confirmando || _seleccionadaId.isEmpty)
                    ? null
                    : _confirmar,
                icon: confirmando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(confirmando
                    ? 'Iniciando…'
                    : _seleccionadaId == s.politicaSugeridaId
                        ? 'Aceptar sugerencia'
                        : 'Confirmar mi elección'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _opcion(CandidatoPolitica c, String sugeridaId) {
    final seleccionada = c.politicaId == _seleccionadaId;
    return GestureDetector(
      onTap: () => setState(() => _seleccionadaId = c.politicaId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionada ? Colors.deepPurple.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: seleccionada
                ? Colors.deepPurple
                : Colors.grey.shade300,
            width: seleccionada ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: c.politicaId,
              groupValue: _seleccionadaId,
              onChanged: (v) => setState(() => _seleccionadaId = v ?? ''),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.nombre,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (c.politicaId == sugeridaId)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Chip(
                            label: Text('Sugerida',
                                style: TextStyle(fontSize: 10)),
                            backgroundColor: Color(0xFFE3F2FD),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Confianza ${(c.confianza * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vistaExito() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle,
                size: 72, color: Colors.green.shade600),
          ),
          const SizedBox(height: 18),
          const Text(
            'Trámite iniciado con éxito',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Código: $_codigoTramite',
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => Get.until((route) => route.settings.name == '/home'),
            icon: const Icon(Icons.home),
            label: const Text('Volver al inicio'),
          ),
        ],
      ),
    );
  }
}
