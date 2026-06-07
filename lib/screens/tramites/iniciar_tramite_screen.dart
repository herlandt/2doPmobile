// C2 Guía 1F — Confirmación e Inicio de Trámite simplificado (CU-07)
//
// NUEVO: antes de crear el trámite, el cliente adjunta los documentos
// obligatorios del PRIMER nodo. El botón "Iniciar" queda deshabilitado hasta
// tener todos los adjuntos. Al confirmar: se crea el trámite y se suben los
// documentos -> el trámite arranca SIN quedar en compuerta.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/politica_model.dart';
import '../../services/tramites_envio_service.dart';
import '../../services/adjuntos_service.dart';
import '../../services/auth_service.dart';
import '../../utils/error_messages.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

class IniciarTramiteScreen extends StatefulWidget {
  final String politicaId;
  final String politicaNombre;

  const IniciarTramiteScreen({
    Key? key,
    required this.politicaId,
    required this.politicaNombre,
  }) : super(key: key);

  @override
  State<IniciarTramiteScreen> createState() => _IniciarTramiteScreenState();
}

class _IniciarTramiteScreenState extends State<IniciarTramiteScreen> {
  late TramitesEnvioService envioService;
  late AuthService authService;
  late AdjuntosService adjuntosService;

  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  // Carga inicial de los requisitos del primer nodo.
  bool _cargandoRequisitos = true;
  String? _errorCarga;

  // Datos del primer nodo (compuerta inicial).
  String _actividadId = '';
  List<DocumentoRequerido> _requisitos = const [];

  // Archivos adjuntados en memoria por requisito.id (aún NO subidos).
  final Map<String, File> _adjuntos = {};

  @override
  void initState() {
    super.initState();
    envioService = Get.find<TramitesEnvioService>();
    authService = Get.find<AuthService>();
    adjuntosService = Get.find<AdjuntosService>();
    _cargarRequisitos();
  }

  Future<void> _cargarRequisitos() async {
    setState(() {
      _cargandoRequisitos = true;
      _errorCarga = null;
    });
    try {
      final actividad =
          await adjuntosService.obtenerDocumentosIniciales(widget.politicaId);
      if (!mounted) return;
      setState(() {
        _actividadId = actividad?.actividadId ?? '';
        // Solo los que debe aportar el cliente y son obligatorios.
        _requisitos = (actividad?.documentosRequeridos ?? const [])
            .where((d) => d.esCliente && d.obligatorio)
            .toList();
        _cargandoRequisitos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCarga = e.toString();
        _cargandoRequisitos = false;
      });
    }
  }

  /// ¿Están adjuntados TODOS los requisitos obligatorios del cliente?
  bool get _todosAdjuntados =>
      _requisitos.every((r) => _adjuntos.containsKey(r.id));

  Future<void> _seleccionarImagen(
      DocumentoRequerido req, ImageSource fuente) async {
    final XFile? picked = await _picker.pickImage(
      source: fuente,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (picked != null && mounted) {
      setState(() => _adjuntos[req.id] = File(picked.path));
    }
  }

  void _mostrarOpciones(DocumentoRequerido req) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(req, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(req, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _iniciar() async {
    final clienteId = authService.usuarioActual.value?.id ?? '';
    if (clienteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos identificar tu usuario. Cierra sesión y vuelve a entrar.')),
      );
      return;
    }

    // Si hay requisitos, deben estar todos adjuntados (defensa extra: el botón
    // ya está deshabilitado en ese caso).
    if (_requisitos.isNotEmpty && !_todosAdjuntados) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adjunta todos los documentos para iniciar.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // a) Crear el trámite.
      final result =
          await envioService.iniciarTramiteC2(widget.politicaId, clienteId);

      final tramiteId = (result['tramiteId'] ?? result['id'])?.toString() ?? '';
      final codigo = result['codigo'] ?? result['tramiteId'] ?? 'N/D';

      // b) Subir los documentos del primer nodo (si los hay).
      final List<String> fallidos = [];
      if (tramiteId.isNotEmpty) {
        for (final req in _requisitos) {
          final file = _adjuntos[req.id];
          if (file == null) continue;
          try {
            await adjuntosService.subirAdjunto(
              tramiteId: tramiteId,
              actividadId: _actividadId,
              documentoNombre: req.nombre,
              archivo: file,
              documentoRequeridoId: req.id,
            );
          } catch (_) {
            fallidos.add(req.nombre);
          }
        }
      }

      if (!mounted) return;

      // c) Éxito + avisar de subidas fallidas (el trámite YA se creó).
      if (fallidos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Trámite iniciado con éxito: $codigo'),
            backgroundColor: AppColors.exito,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Trámite iniciado ($codigo), pero falló subir: '
              '${fallidos.join(', ')}. Puedes subirlos luego.',
            ),
            backgroundColor: AppColors.observado,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      // Volver al Dashboard
      Get.until((route) => route.settings.name == '/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeAmigable(e)),
            backgroundColor: AppColors.peligro,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool puedeIniciar = !_isLoading &&
        !_cargandoRequisitos &&
        (_requisitos.isEmpty || _todosAdjuntados);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Trámite'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // Icono
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.compuerta.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in,
                          size: 64,
                          color: AppColors.compuerta,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Texto informativo
                    const Text(
                      'Está a punto de iniciar:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15, color: AppColors.textoSuave),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.politicaNombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Sección de documentos para iniciar.
                    _buildSeccionDocumentos(),

                    const SizedBox(height: AppSpacing.sm),

                    // Aviso
                    AppCard(
                      background: AppColors.observado.withOpacity(0.06),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline,
                              color: AppColors.observado, size: 20),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Una vez iniciado, este trámite será derivado automáticamente al área de Atención al Cliente para su revisión.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Texto de ayuda si faltan adjuntos.
              if (!_cargandoRequisitos &&
                  _requisitos.isNotEmpty &&
                  !_todosAdjuntados)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Adjunta todos los documentos para iniciar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.peligro, fontSize: 13),
                  ),
                ),

              ElevatedButton(
                onPressed: puedeIniciar ? _iniciar : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirmar e Iniciar Trámite',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: _isLoading ? null : () => Get.back(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sección "Documentos para iniciar": estado de carga, error, o la lista de
  /// requisitos del cliente con su botón de adjuntar.
  Widget _buildSeccionDocumentos() {
    if (_cargandoRequisitos) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_errorCarga != null) {
      return AppCard(
        background: AppColors.peligro.withOpacity(0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No se pudieron cargar los documentos requeridos.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: _cargarRequisitos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Sin requisitos del cliente: comportamiento de hoy (iniciar directo).
    if (_requisitos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Documentos para iniciar'),
        const Text(
          'Adjunta estos documentos obligatorios para poder iniciar el trámite.',
          style: TextStyle(fontSize: 13, color: AppColors.textoSuave),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._requisitos.map(_buildRequisitoTile),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildRequisitoTile(DocumentoRequerido req) {
    final adjuntado = _adjuntos.containsKey(req.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  adjuntado
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: adjuntado ? AppColors.exito : AppColors.textoSuave,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    req.nombre,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                ),
                EstadoChip(
                  adjuntado ? 'Adjuntado' : 'Pendiente',
                  color: adjuntado ? AppColors.exito : AppColors.observado,
                ),
              ],
            ),
            if (adjuntado) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.file(
                  _adjuntos[req.id]!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : () => _mostrarOpciones(req),
              icon: Icon(adjuntado ? Icons.cached : Icons.attach_file),
              label: Text(adjuntado ? 'Reemplazar' : 'Adjuntar'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
