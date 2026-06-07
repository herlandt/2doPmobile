// C2 Guía 2F — Formulario de Corrección de Trámite Devuelto (CU-17 cliente)
//
// Subsanar Trámite: el cliente ve los documentos del trámite, sube uno
// corregido/faltante (cámara o galería) y, opcionalmente, escribe una
// aclaración. Reenvía la subsanación cuando hay al menos un documento subido
// en esta sesión o una aclaración escrita.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/tramite_resumen_model.dart';
import '../../models/flujo_completo_model.dart';
import '../../models/documento_archivo_model.dart';
import '../../services/tramites_seguimiento_service.dart';
import '../../services/documento_archivo_service.dart';
import '../../services/adjuntos_service.dart';
import '../../utils/error_messages.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

class RealizarCorreccionScreen extends StatefulWidget {
  final TramiteResumen tramite;

  const RealizarCorreccionScreen({super.key, required this.tramite});

  @override
  State<RealizarCorreccionScreen> createState() =>
      _RealizarCorreccionScreenState();
}

class _RealizarCorreccionScreenState extends State<RealizarCorreccionScreen> {
  final _respuestaController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late TramitesSeguimientoService seguimientoService;
  late DocumentoArchivoService documentoService;
  late AdjuntosService adjuntosService;

  // Estado del nodo observado (donde se devolvió el trámite).
  String? _actividadId;
  String? _actividadNombre;
  String? _observacion;
  // estadoSeccion del nodo actual: distingue CASO A (compuerta) de CASO B
  // (observado). Ver _esCompuerta().
  String? _estadoSeccion;

  // CASO A (compuerta): requisitos del CLIENTE del nodo que faltan por cubrir.
  List<DocumentoRequerido> _requisitosCliente = const [];

  // CASO B (observado): ids de DocumentoArchivo que el funcionario marcó "mal".
  List<String> _documentosObservadosIds = const [];

  // Documentos del trámite.
  List<DocumentoArchivo> _documentos = [];
  bool _cargandoDocs = true;
  // Id del documento cuya subida está en curso (requisito o doc observado),
  // para mostrar el spinner solo en su fila. null = ninguna subida en curso.
  String? _subiendoId;

  // Control de envío y validación.
  bool _isSubmitting = false;
  bool _subioAlgo = false;

  @override
  void initState() {
    super.initState();
    seguimientoService = Get.find<TramitesSeguimientoService>();
    documentoService = Get.find<DocumentoArchivoService>();
    adjuntosService = Get.find<AdjuntosService>();
    _cargarTodo();
  }

  @override
  void dispose() {
    _respuestaController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodo() async {
    await _cargarNodoObservado();
    await _cargarDocumentos();
  }

  /// Localiza el nodo actual en el flujo y guarda su actividad, observación,
  /// estadoSeccion y los datos que distinguen CASO A (compuerta: requisitos del
  /// cliente faltantes) de CASO B (observado: documentos marcados "mal").
  Future<void> _cargarNodoObservado() async {
    try {
      final flujo =
          await seguimientoService.obtenerFlujoCompleto(widget.tramite.id);
      FlujoNodo? actual;
      for (final n in flujo.nodos) {
        if (n.esActual) {
          actual = n;
          break;
        }
      }
      final requisitos = actual?.documentosRequeridos
              .where((d) => d.esCliente)
              .toList() ??
          const <DocumentoRequerido>[];
      if (!mounted) return;
      setState(() {
        _actividadId = actual?.actividadId;
        _actividadNombre = actual?.actividadNombre ?? actual?.nombre;
        _observacion = actual?.observacion;
        _estadoSeccion = actual?.estadoSeccion;
        _requisitosCliente = requisitos;
        _documentosObservadosIds = actual?.documentosObservados ?? const [];
      });
    } catch (_) {
      // El flujo no es crítico para subsanar: si falla, dejamos el motivo
      // genérico y permitimos subir solo si se determina la actividad.
    }
  }

  /// CASO A "COMPUERTA": el nodo está a la espera de requisitos obligatorios del
  /// cliente. Su estadoSeccion contiene 'pendiente' + 'documento'
  /// (ej. "Pendiente de documentos"). En caso contrario se trata como CASO B
  /// "OBSERVADO" (estadoSeccion contiene 'observ').
  bool _esCompuerta() {
    final e = (_estadoSeccion ?? '').toLowerCase();
    return e.contains('pendiente') && e.contains('documento');
  }

  /// CASO A: requisitos del cliente que aún NO están cubiertos por algún
  /// documento ya subido (comparando contra los documentoRequeridoId).
  List<DocumentoRequerido> get _requisitosPendientes {
    final cubiertos = _documentos
        .map((d) => d.documentoRequeridoId)
        .whereType<String>()
        .toSet();
    return _requisitosCliente
        .where((r) => !cubiertos.contains(r.id))
        .toList();
  }

  /// CASO B: documentos del trámite que el funcionario marcó como "mal".
  List<DocumentoArchivo> get _documentosACorregir =>
      _documentos.where((d) => _documentosObservadosIds.contains(d.id)).toList();

  Future<void> _cargarDocumentos() async {
    if (mounted) setState(() => _cargandoDocs = true);
    try {
      final docs = await documentoService.listarPorTramite(widget.tramite.id);
      if (!mounted) return;
      setState(() => _documentos = docs);
    } catch (_) {
      if (!mounted) return;
      setState(() => _documentos = []);
    } finally {
      if (mounted) setState(() => _cargandoDocs = false);
    }
  }

  /// Abre el preview del documento en una app externa (navegador/visor).
  Future<void> _verDocumento(DocumentoArchivo doc) async {
    try {
      final preview = await documentoService.preview(doc.id);
      final url = preview.urlPreview;
      if (url.isEmpty) {
        _snack('No se pudo obtener la vista previa del documento.',
            color: AppColors.peligro);
        return;
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        _snack('No se pudo abrir el documento.', color: AppColors.peligro);
      }
    } catch (_) {
      if (mounted) {
        _snack('No se pudo abrir el documento.', color: AppColors.peligro);
      }
    }
  }

  /// Hoja inferior con cámara/galería. [claveSpinner] identifica la fila que
  /// muestra el spinner mientras sube; [documentoRequeridoId] indica qué
  /// requisito cumple (CASO A o B) y [corrigeDocumentoId] el documento observado
  /// que se reemplaza (CASO B).
  void _mostrarOpcionesSubida({
    required String claveSpinner,
    required String documentoNombre,
    String? documentoRequeridoId,
    String? corrigeDocumentoId,
  }) {
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
                _seleccionarYSubir(
                  ImageSource.camera,
                  claveSpinner: claveSpinner,
                  documentoNombre: documentoNombre,
                  documentoRequeridoId: documentoRequeridoId,
                  corrigeDocumentoId: corrigeDocumentoId,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarYSubir(
                  ImageSource.gallery,
                  claveSpinner: claveSpinner,
                  documentoNombre: documentoNombre,
                  documentoRequeridoId: documentoRequeridoId,
                  corrigeDocumentoId: corrigeDocumentoId,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarYSubir(
    ImageSource fuente, {
    required String claveSpinner,
    required String documentoNombre,
    String? documentoRequeridoId,
    String? corrigeDocumentoId,
  }) async {
    final actividadId = _actividadId;
    if (actividadId == null) return;

    final XFile? picked = await _picker.pickImage(
      source: fuente,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (picked == null) return;

    if (mounted) setState(() => _subiendoId = claveSpinner);
    try {
      await adjuntosService.subirAdjunto(
        tramiteId: widget.tramite.id,
        actividadId: actividadId,
        documentoNombre: documentoNombre,
        archivo: File(picked.path),
        documentoRequeridoId: documentoRequeridoId,
        corrigeDocumentoId: corrigeDocumentoId,
      );
      if (!mounted) return;
      setState(() => _subioAlgo = true);
      _snack('Documento subido', color: AppColors.exito);
      // Recargar flujo (para refrescar requisitos/documentosObservados) y la
      // lista de documentos: el requisito cumplido o el doc corregido
      // desaparece de su lista.
      await _cargarNodoObservado();
      await _cargarDocumentos();
    } catch (e) {
      if (!mounted) return;
      final msg = e is SubidaException
          ? e.mensaje
          : 'No se pudo subir el documento.';
      _snack(msg, color: AppColors.peligro);
    } finally {
      if (mounted) setState(() => _subiendoId = null);
    }
  }

  Future<void> _enviar() async {
    final texto = _respuestaController.text.trim();
    if (texto.isEmpty && !_subioAlgo) {
      _snack('Sube un documento corregido o escribe una aclaración.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await seguimientoService.enviarCorreccion(
        widget.tramite.id,
        texto.isEmpty ? 'Documentos corregidos' : texto,
      );
      if (mounted) {
        _snack('Corrección enviada correctamente.', color: AppColors.exito);
        Get.back();
      }
    } catch (e) {
      if (mounted) {
        _snack(mensajeAmigable(e), color: AppColors.peligro);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String mensaje, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _esCompuerta()
              ? 'Completar documentos para continuar'
              : 'Subsanar Trámite',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Código del trámite + política
            Text(
              widget.tramite.codigo,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.tramite.politicaNombre,
              style: const TextStyle(color: AppColors.textoSuave),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. CASO A "compuerta": banner AZUL positivo (avanzó).
            //    CASO B "observado": card ROJO con el motivo de devolución.
            _esCompuerta()
                ? _buildBannerCompuerta()
                : _buildMotivoDevolucion(),
            const SizedBox(height: AppSpacing.lg),

            // 3. Documentos del trámite
            _buildDocumentosCard(),
            const SizedBox(height: AppSpacing.lg),

            // 4 y 5: en OBSERVADO va la aclaración opcional + "Reenviar Trámite".
            // En COMPUERTA solo se suben los documentos: el trámite avanza solo,
            // así que mostramos una nota y un botón "Listo" (sin reenviar).
            if (!_esCompuerta()) ...[
              TextField(
                controller: _respuestaController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Aclaración (opcional)',
                  hintText:
                      'Describe brevemente la corrección realizada (opcional)...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _enviar,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isSubmitting ? 'Enviando...' : 'Reenviar Trámite',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ] else ...[
              const Text(
                'Cuando subas todos los documentos, tu trámite continúa automáticamente.',
                style: TextStyle(color: AppColors.textoSuave, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.check),
                label: const Text('Listo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// CASO A "compuerta": banner AZUL positivo. El trámite avanzó; no es una
  /// corrección por error, solo pide documentos nuevos para continuar.
  Widget _buildBannerCompuerta() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.compuerta.withOpacity(0.08),
        border: Border.all(color: AppColors.compuerta.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.trending_up, color: AppColors.compuerta, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu trámite avanzó ✅',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.compuerta,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Completa estos documentos para continuar.',
                  style: TextStyle(fontSize: 13, color: AppColors.compuerta),
                ),
                if (_actividadNombre != null &&
                    _actividadNombre!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _actividadNombre!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.compuerta,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivoDevolucion() {
    final tieneObservacion =
        _observacion != null && _observacion!.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.observado.withOpacity(0.08),
        border: Border.all(color: AppColors.observado.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.observado, size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Motivo de devolución',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.observado,
                  ),
                ),
              ),
            ],
          ),
          if (_actividadNombre != null && _actividadNombre!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _actividadNombre!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.observado,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            tieneObservacion
                ? _observacion!.trim()
                : 'Revise el historial del trámite para ver las observaciones detalladas del funcionario. Ingrese su corrección a continuación.',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentosCard() {
    final esCompuerta = _esCompuerta();
    final titulo = esCompuerta ? 'Requisitos a completar' : 'Documentos a corregir';
    final colorAcento = esCompuerta ? AppColors.compuerta : AppColors.observado;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(esCompuerta ? Icons.checklist_rtl : Icons.rule_folder,
                  size: 20, color: colorAcento),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          if (_cargandoDocs)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_actividadId == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No se pudo determinar la actividad para subir documentos.',
                style: TextStyle(color: AppColors.textoSuave, fontSize: 13),
              ),
            )
          else if (esCompuerta)
            _buildCasoCompuerta()
          else
            _buildCasoObservado(),
        ],
      ),
    );
  }

  /// CASO A: lista de requisitos del cliente pendientes; cada uno con su botón
  /// "Subir" que pasa su propio documentoRequeridoId.
  Widget _buildCasoCompuerta() {
    final pendientes = _requisitosPendientes;
    if (pendientes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.exito, size: 18),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Todos los requisitos están completos. Ya puedes reenviar el trámite.',
                style: TextStyle(color: AppColors.textoSuave, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: pendientes.map(_buildRequisitoItem).toList(),
    );
  }

  Widget _buildRequisitoItem(DocumentoRequerido req) {
    final clave = 'req_${req.id}';
    final subiendo = _subiendoId == clave;
    final bloqueado = _subiendoId != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(Icons.description_outlined,
              size: 20, color: AppColors.compuerta),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(
              req.obligatorio ? '${req.nombre} (obligatorio)' : req.nombre,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          OutlinedButton.icon(
            onPressed: bloqueado
                ? null
                : () => _mostrarOpcionesSubida(
                      claveSpinner: clave,
                      documentoNombre: req.nombre,
                      documentoRequeridoId: req.id,
                    ),
            icon: subiendo
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file, size: 16),
            label: Text(subiendo ? 'Subiendo...' : 'Subir'),
          ),
        ],
      ),
    );
  }

  /// CASO B: documentos marcados "mal" por el funcionario, cada uno con "Ver" y
  /// "Re-subir corregido". Si no hay observados específicos, fallback a la lista
  /// completa del trámite (trámites antiguos).
  Widget _buildCasoObservado() {
    final observados = _documentosACorregir;
    // Fallback: el funcionario no marcó documentos específicos -> mostrar todos.
    final usarFallback = _documentosObservadosIds.isEmpty;
    final lista = usarFallback ? _documentos : observados;

    if (lista.isEmpty) {
      // CASO B sin documentos específicos para corregir: NO dejar al cliente
      // sin acción. Mensaje claro + botón genérico de subida (cámara/galería).
      if (usarFallback) {
        return _buildSubidaGenerica();
      }
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          'No hay documentos pendientes de corrección. Ya puedes reenviar el trámite.',
          style: TextStyle(color: AppColors.textoSuave, fontSize: 13),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (usarFallback)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Vuelve a subir el documento corregido que corresponda:',
              style: TextStyle(color: AppColors.textoSuave, fontSize: 12),
            ),
          ),
        ...lista.map(_buildDocCorregirItem),
      ],
    );
  }

  /// CASO B sin documentos concretos para corregir: mensaje claro de qué hacer
  /// + botón genérico para subir el documento que corresponda (cámara/galería).
  Widget _buildSubidaGenerica() {
    const clave = 'generico';
    final subiendo = _subiendoId == clave;
    final bloqueado = _subiendoId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revisa el motivo arriba y sube el documento que corresponda.',
          style: TextStyle(color: AppColors.textoSuave, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: bloqueado
                ? null
                : () => _mostrarOpcionesSubida(
                      claveSpinner: clave,
                      documentoNombre: 'Documento de subsanación',
                    ),
            icon: subiendo
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file, size: 16),
            label: Text(subiendo ? 'Subiendo...' : 'Subir documento'),
          ),
        ),
      ],
    );
  }

  Widget _buildDocCorregirItem(DocumentoArchivo doc) {
    final clave = 'doc_${doc.id}';
    final subiendo = _subiendoId == clave;
    final bloqueado = _subiendoId != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insert_drive_file_outlined,
              size: 20, color: AppColors.observado),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.nombreLogico,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${doc.tipoDocumento} v${doc.numeroVersionActual}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textoSuave),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: bloqueado ? null : () => _verDocumento(doc),
                      icon: const Icon(Icons.remove_red_eye, size: 16),
                      label: const Text('Ver'),
                      style: TextButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: bloqueado
                          ? null
                          : () => _mostrarOpcionesSubida(
                                claveSpinner: clave,
                                documentoNombre: doc.nombreLogico,
                                documentoRequeridoId: doc.documentoRequeridoId,
                                corrigeDocumentoId: doc.id,
                              ),
                      icon: subiendo
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file, size: 16),
                      label:
                          Text(subiendo ? 'Subiendo...' : 'Re-subir corregido'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
