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
import '../../models/tramite_resumen_model.dart';
import '../../services/auth_service.dart';
import '../../services/ia_service.dart';
import '../../services/tramites_envio_service.dart';
import '../../utils/error_messages.dart';
import '../../widgets/grabador_voz_widget.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import 'realizar_correccion_screen.dart';

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
  String _tramiteId = '';

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
        _errorMsg = mensajeAmigable(e);
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
    return 'No pudimos analizar tu descripción. Intenta de nuevo o elige tu trámite desde el catálogo.';
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
        _tramiteId = (result['tramiteId'] ?? result['id'] ?? '').toString();
        _codigoTramite = codigo;
        _paso = _Paso.exito;
      });
    } catch (e) {
      setState(() {
        _paso = _Paso.elegir;
        _errorMsg = mensajeAmigable(e);
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
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
        AppCard(
          background: AppColors.ia.withOpacity(0.06),
          child: Row(
            children: const [
              Icon(Icons.auto_awesome, color: AppColors.ia),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Describe lo que necesitas en tus propias palabras. La IA te sugerirá la política correcta.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _descCtrl,
          maxLines: 5,
          maxLength: 600,
          enabled: !analizando,
          decoration: const InputDecoration(
            labelText: 'Describe tu trámite',
            hintText:
                'Ej: Necesito una nueva conexión eléctrica para mi casa nueva.',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.graphic_eq, color: AppColors.ia, size: 18),
              const SizedBox(width: AppSpacing.xs),
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
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            background: AppColors.peligro.withOpacity(0.06),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.peligro, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _errorMsg,
                    style: const TextStyle(
                        color: AppColors.peligro, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
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
            backgroundColor: AppColors.ia,
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
        AppCard(
          background: AppColors.ia.withOpacity(0.06),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.ia),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Sugerencia con ${(s.confianza * 100).toStringAsFixed(0)}% de confianza',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const SectionHeader('Elige la política correcta'),
        for (final c in s.top3) _opcion(c, s.politicaSugeridaId),
        if (_errorMsg.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_errorMsg,
              style: const TextStyle(color: AppColors.peligro, fontSize: 12)),
        ],
        const SizedBox(height: AppSpacing.md),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ia,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _opcion(CandidatoPolitica c, String sugeridaId) {
    final seleccionada = c.politicaId == _seleccionadaId;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => setState(() => _seleccionadaId = c.politicaId),
        background: seleccionada
            ? AppColors.ia.withOpacity(0.06)
            : AppColors.superficie,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Radio<String>(
              value: c.politicaId,
              groupValue: _seleccionadaId,
              activeColor: AppColors.ia,
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
                          padding: EdgeInsets.only(left: AppSpacing.xs),
                          child: EstadoChip('Sugerida', color: AppColors.ia),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Confianza ${(c.confianza * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textoSuave),
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
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.exito.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                size: 72, color: AppColors.exito),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Trámite iniciado con éxito',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Código: $_codigoTramite',
              style: const TextStyle(color: AppColors.textoSuave)),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: _tramiteId.isEmpty
                ? null
                : () => Get.off(() => RealizarCorreccionScreen(
                      tramite: TramiteResumen(
                        id: _tramiteId,
                        codigo: _codigoTramite,
                        politicaNombre: '',
                        estado: 'En curso',
                        nodoActualNombre: '',
                        fechaInicio: '',
                        progreso: 0,
                      ),
                    )),
            icon: const Icon(Icons.upload_file),
            label: const Text('Subir documentos para continuar'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Get.until((route) => route.settings.name == '/home'),
            icon: const Icon(Icons.home),
            label: const Text('Volver al inicio'),
          ),
        ],
      ),
    );
  }
}
