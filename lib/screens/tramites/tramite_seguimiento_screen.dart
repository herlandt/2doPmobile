// Guía 4F - Pantalla de Seguimiento Detallado de Trámite
//
// Parte 2 — añadidos:
//   • Chip de riesgo IA (CU-43) en el card de estado.
//   • Sección "Documentos del repositorio" en la pestaña Resumen (CU-34).
// NOTA: CU-42 (ruta óptima IA) se removió — pertenece al flujo cliente
// previo (CU-40 al iniciar trámite con IA), no al seguimiento.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/documento_archivo_model.dart';
import '../../models/tramite_estado_model.dart';
import '../../models/flujo_completo_model.dart';
import '../../models/tramite_riesgo_model.dart';
import '../../routes/app_routes.dart';
import '../../services/documento_archivo_service.dart';
import '../../services/ia_service.dart';
import '../../services/tramites_seguimiento_service.dart';
import '../../utils/error_messages.dart';
import '../../widgets/chip_riesgo_widget.dart';
import '../../widgets/preview_documento_widget.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

class TramiteSeguimientoScreen extends StatefulWidget {
  const TramiteSeguimientoScreen({Key? key}) : super(key: key);

  @override
  State<TramiteSeguimientoScreen> createState() => _TramiteSeguimientoScreenState();
}

class _TramiteSeguimientoScreenState extends State<TramiteSeguimientoScreen> {
  late TramitesSeguimientoService tramitesSeguimientoService;
  late DocumentoArchivoService docSvc;
  late IaService iaSvc;

  String tramiteId = '';
  EstadoTramite? estado;
  FlujoCompleto? flujo;
  bool _cargandoFlujo = false;

  // Parte 2 — documentos del trámite + riesgo IA (CU-43).
  // CU-42 (ruta óptima) se removió: la idea de "IA recomienda qué hacer" se
  // canaliza por CU-40 al iniciar el trámite, no por seguimiento del cliente.
  List<DocumentoArchivo> _documentos = [];
  bool _cargandoDocumentos = false;
  TramiteRiesgo? _riesgo;

  @override
  void initState() {
    super.initState();
    tramitesSeguimientoService = Get.find<TramitesSeguimientoService>();
    docSvc = Get.find<DocumentoArchivoService>();
    iaSvc = Get.find<IaService>();

    tramiteId = Get.arguments ?? '';
    if (tramiteId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarEstado();
        _cargarDocumentosYRiesgo();
        // El flujo ahora SIEMPRE se muestra (no detrás de una pestaña),
        // por lo que se carga al abrir la pantalla.
        _cargarFlujo();
      });
    }
  }

  Future<void> _cargarDocumentosYRiesgo() async {
    if (tramiteId.isEmpty) return;
    setState(() => _cargandoDocumentos = true);
    try {
      final docs = await docSvc.listarPorTramite(tramiteId);
      if (mounted) setState(() => _documentos = docs);
    } catch (_) {
      // Si el repositorio aún no existe, dejamos lista vacía sin error visible.
    } finally {
      if (mounted) setState(() => _cargandoDocumentos = false);
    }
    try {
      final lista = await iaSvc.enRiesgo();
      TramiteRiesgo? mio;
      for (final r in lista) {
        if (r.tramiteId == tramiteId) {
          mio = r;
          break;
        }
      }
      if (mounted) setState(() => _riesgo = mio);
    } catch (_) {
      // IA no disponible — no bloqueamos la pantalla.
    }
  }

  Future<void> _abrirPreview(DocumentoArchivo doc) async {
    showDialog(
      context: context,
      builder: (_) => const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      final preview = await docSvc.preview(doc.id);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                doc.nombreLogico,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              PreviewDocumentoWidget(
                preview: preview,
                nombreLogico: doc.nombreLogico,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeAmigable(e))),
      );
    }
  }

  Future<void> _cargarEstado() async {
    try {
      estado = await tramitesSeguimientoService.obtenerEstadoTramite(tramiteId);
      setState(() {});
    } catch (e) {
      print('Error cargando estado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeAmigable(e))),
        );
      }
    }
  }

  Future<void> _cargarFlujo() async {
    if (flujo != null || _cargandoFlujo) return;
    setState(() => _cargandoFlujo = true);
    try {
      flujo = await tramitesSeguimientoService.obtenerFlujoCompleto(tramiteId);
    } catch (e) {
      print('Error cargando flujo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeAmigable(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoFlujo = false);
    }
  }

  /// Recarga el flujo y los documentos (tras subir un requisito faltante).
  Future<void> _refrescarFlujoYDocumentos() async {
    // Forzamos recarga del flujo (que es cacheado por _cargarFlujo).
    flujo = null;
    await _cargarFlujo();
    await _cargarDocumentosYRiesgo();
  }

  /// ¿La sección del nodo está en "Pendiente de documentos"? Comparación
  /// tolerante: contiene 'pendiente' y 'docu'.
  bool _esPendienteDocumentos(FlujoNodo nodo) {
    final s = (nodo.estadoSeccion ?? '').toLowerCase();
    return s.contains('pendiente') && s.contains('docu');
  }

  /// Requisitos del CLIENTE obligatorios del nodo que AÚN no están cubiertos.
  /// Un requisito está cubierto si existe un DocumentoArchivo cargado con
  /// `documentoRequeridoId == requisito.id`.
  List<DocumentoRequerido> _requisitosPendientes(FlujoNodo nodo) {
    final cubiertos = _documentos
        .map((d) => d.documentoRequeridoId)
        .where((id) => id != null && id.isNotEmpty)
        .toSet();
    return nodo.documentosRequeridos
        .where((r) => r.esCliente && r.obligatorio && !cubiertos.contains(r.id))
        .toList();
  }

  /// Navega a SubirDocumentoScreen para cumplir un requisito faltante y, al
  /// volver con éxito, refresca el flujo + documentos.
  Future<void> _subirRequisito(FlujoNodo nodo, DocumentoRequerido req) async {
    final result = await Get.toNamed(
      AppRoutes.subirDocumento,
      arguments: {
        'tramiteId': tramiteId,
        'actividadId': nodo.actividadId ?? '',
        'actividadNombre': nodo.actividadNombre ?? nodo.nombre,
        'documentoNombre': req.nombre,
        'documentoRequeridoId': req.id,
      },
    );
    if (result == true) {
      await _refrescarFlujoYDocumentos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de Trámite'),
      ),
      body: Obx(
        () {
          if (tramitesSeguimientoService.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (estado == null) {
            return EmptyState(
              icon: Icons.error_outline,
              titulo: 'Error al cargar el trámite',
              accion: ElevatedButton.icon(
                onPressed: _cargarEstado,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: código / estado / progreso
                _buildCardEstadoGeneral(context),

                // Banner de riesgo IA (CU-43)
                _buildBannerRiesgo(),
                const SizedBox(height: AppSpacing.lg),

                // FLUJO: el trámite se organiza como una sola lista de pasos
                const SectionHeader('Flujo del trámite'),
                _buildPestanaFlujo(),
                const SizedBox(height: AppSpacing.lg),

                // Documentos del repositorio (CU-34)
                _buildSeccionDocumentos(),
              ],
            ),
          );
        },
      ),
    );
  }

  int get _progresoEfectivo =>
      tramitesSeguimientoService.progresoEfectivo(estado!.progreso, estado!.estado);

  bool get _esCerrado =>
      tramitesSeguimientoService.esEstadoTerminal(estado!.estado);

  /// Abre el documento de resolución entregable del trámite (URL firmada).
  Future<void> _descargarResolucion() async {
    try {
      final res = await tramitesSeguimientoService.obtenerResolucion(tramiteId);
      final url = res?['url'] as String?;
      if (url == null || url.isEmpty) {
        Get.snackbar('Resolución', 'Este trámite aún no tiene documento de resolución.');
        return;
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Resolución', 'No se pudo abrir el documento.');
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo obtener la resolución del trámite.');
    }
  }

  Widget _buildCardEstadoGeneral(BuildContext context) {
    final color = tramitesSeguimientoService.getColorEstadoFlutter(estado!.estado);
    final progreso = _progresoEfectivo;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Código y Estado
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estado!.codigo,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${estado!.tramiteId}',
                      style: const TextStyle(
                          color: AppColors.textoSuave, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              EstadoChip(
                '${tramitesSeguimientoService.getIconoEstado(estado!.estado)} ${tramitesSeguimientoService.getTextoEstado(estado!.estado)}',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Progreso
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Progreso General'),
                  Text(
                    '$progreso%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: progreso / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.borde,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Etapa Actual / Estado final
          if (_esCerrado)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                border: Border.all(color: color.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        tramitesSeguimientoService.esAprobado(estado!.estado)
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: color,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Trámite ${tramitesSeguimientoService.getTextoEstado(estado!.estado)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  // Descargar el documento de resolución (solo trámites aprobados)
                  if (tramitesSeguimientoService.esAprobado(estado!.estado)) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _descargarResolucion,
                        icon: const Icon(Icons.download),
                        label: const Text('Descargar resolución'),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.compuerta.withOpacity(0.08),
                border: Border.all(color: AppColors.compuerta.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⏳ Etapa Actual',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    estado!.nodoActual.nombre.isNotEmpty
                        ? estado!.nodoActual.nombre
                        : 'En revisión',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (estado!.nodoActual.departamento != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Departamento: ${estado!.nodoActual.departamento}',
                      style: const TextStyle(
                          color: AppColors.textoSuave, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// CU-43 — Banner de riesgo de demora (IA). Vacío si no hay datos de riesgo.
  Widget _buildBannerRiesgo() {
    if (_riesgo == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.ia, size: 20),
                const SizedBox(width: 6),
                const Text(
                  'Riesgo de demora (IA)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                ChipRiesgoWidget(
                  nivel: _riesgo!.nivel,
                  probSuperarSla: _riesgo!.probSuperarSla,
                ),
              ],
            ),
            if (_riesgo!.razones.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _riesgo!.razones
                    .map((r) => Chip(
                          label:
                              Text(r, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppColors.fondo,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// CU-34 — Documentos del repositorio del trámite.
  Widget _buildSeccionDocumentos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SectionHeader('Documentos del repositorio'),
            const Spacer(),
            if (_cargandoDocumentos)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_documentos.isEmpty && !_cargandoDocumentos)
                const Text(
                  'Aún no hay documentos en el repositorio para este trámite.',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textoSuave),
                ),
              for (final d in _documentos)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    _iconoTipoDoc(d.tipoDocumento),
                    color: AppColors.primary,
                  ),
                  title: Text(
                    d.nombreLogico,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'v${d.numeroVersionActual} · ${d.tipoDocumento}'
                    '${d.obligatorio ? " · obligatorio" : ""}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: TextButton.icon(
                    onPressed: () => _abrirPreview(d),
                    icon: const Icon(Icons.remove_red_eye, size: 16),
                    label: const Text('Ver'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconoTipoDoc(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'IMAGEN':
        return Icons.image;
      case 'WORD':
        return Icons.description;
      case 'EXCEL':
        return Icons.table_chart;
      case 'AUDIO':
        return Icons.audiotrack;
      case 'VIDEO':
        return Icons.movie;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildPestanaFlujo() {
    if (_cargandoFlujo) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (flujo == null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              const Text('No se pudo cargar el flujo'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _cargarFlujo,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (flujo!.nodos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text('Esta política no tiene flujo configurado')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compuerta de documentos: card prominente si el nodo actual está
        // "Pendiente de documentos" y faltan obligatorios del cliente.
        _buildCompuertaDocumentos(),
        ...flujo!.nodos.asMap().entries.map(
              (e) =>
                  _buildNodoFlujo(e.value, e.key == flujo!.nodos.length - 1),
            ),
      ],
    );
  }

  /// CU — Compuerta de documentos: cuando el trámite entra a una actividad y
  /// faltan los documentos OBLIGATORIOS del CLIENTE, el backend deja la sección
  /// en "Pendiente de documentos" y no avanza. Mostramos un card prominente con
  /// los requisitos pendientes y un botón "Subir" por cada uno.
  Widget _buildCompuertaDocumentos() {
    final nodos = flujo?.nodos ?? const <FlujoNodo>[];
    FlujoNodo? actual;
    for (final n in nodos) {
      if (n.esActual && _esPendienteDocumentos(n)) {
        actual = n;
        break;
      }
    }
    if (actual == null) return const SizedBox.shrink();

    final pendientes = _requisitosPendientes(actual);
    if (pendientes.isEmpty) return const SizedBox.shrink();

    final nodo = actual;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md - 2),
      decoration: BoxDecoration(
        color: AppColors.compuerta.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.compuerta, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file,
                  color: AppColors.compuerta, size: 20),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Faltan documentos para continuar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.compuerta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Sube los siguientes documentos obligatorios para que tu trámite avance.',
            style: TextStyle(fontSize: 12, color: AppColors.textoSuave),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...pendientes.map(
            (req) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.superficie,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.borde),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.nombre,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (req.descripcion != null &&
                            req.descripcion!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              req.descripcion!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textoSuave,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: () => _subirRequisito(nodo, req),
                    icon: const Icon(Icons.cloud_upload, size: 16),
                    label: const Text('Subir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.compuerta,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodoFlujo(FlujoNodo nodo, bool esUltimo) {
    // Fork/Join son nodos TÉCNICOS (división/unión de ramas paralelas): el
    // usuario no debería verlos como un "paso". Los mostramos como un conector
    // discreto en vez de una tarjeta "FORK"/"JOIN".
    if (nodo.tipo == 'fork' || nodo.tipo == 'join') {
      return _buildConectorParalelo(nodo, esUltimo);
    }
    final color = _colorPorEstadoNodo(nodo);
    final icono = _iconoPorEstadoNodo(nodo);
    final esActividad = nodo.tipo == 'actividad';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicador y línea vertical conectora
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: nodo.esActual
                    ? Border.all(color: AppColors.primary, width: 3)
                    : null,
              ),
              child: Icon(icono, color: Colors.white, size: 20),
            ),
            if (!esUltimo)
              Container(
                width: 2,
                height: esActividad ? 80 : 40,
                color: AppColors.borde,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        // Tarjeta del nodo
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.superficie,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: nodo.esActual ? AppColors.primary : AppColors.borde,
                  width: nodo.esActual ? 2 : 1,
                ),
              ),
              child: esActividad
                  ? _buildNodoActividad(nodo, color)
                  : _buildNodoSimple(nodo, color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNodoSimple(FlujoNodo nodo, Color color) {
    // Nodo de decisión (if): mostramos LA PREGUNTA y a dónde lleva cada rama,
    // no el tipo genérico "DECISION".
    if (nodo.tipo == 'decision') {
      return _buildNodoDecision(nodo);
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nodo.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _etiquetaTipoNodo(nodo.tipo),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textoSuave),
                    ),
                  ],
                ),
              ),
              if (nodo.esActual)
                const EstadoChip('ACTUAL', color: AppColors.primary),
            ],
          ),
          if (nodo.observacion != null && nodo.observacion!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '⚠️ ${nodo.observacion}',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.observado),
              ),
            ),
        ],
      ),
    );
  }

  /// Etiqueta legible para tipos de nodo simples (inicio/fin).
  String _etiquetaTipoNodo(String tipo) {
    switch (tipo) {
      case 'inicio':
        return 'Inicio del trámite';
      case 'fin':
        return 'Fin del trámite';
      default:
        return tipo.toUpperCase();
    }
  }

  /// ¿La pregunta de un decisión quedó vacía o con el placeholder "¿Decisión?"?
  bool _preguntaVaciaDecision(String? p) {
    final norm = (p ?? '').replaceAll(RegExp(r'[¿?]'), '').trim().toLowerCase();
    return norm.isEmpty || norm == 'decision' || norm == 'decisión';
  }

  /// Nodo de decisión (if): muestra LA PREGUNTA y a dónde lleva cada rama.
  Widget _buildNodoDecision(FlujoNodo nodo) {
    final tienePregunta = !_preguntaVaciaDecision(nodo.pregunta);
    final pregunta = tienePregunta ? nodo.pregunta! : '¿Decisión?';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline,
                  size: 16,
                  color:
                      tienePregunta ? AppColors.primary : AppColors.observado),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pregunta,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: tienePregunta ? null : AppColors.observado,
                  ),
                ),
              ),
              if (nodo.esActual)
                const EstadoChip('ACTUAL', color: AppColors.primary),
            ],
          ),
          if (nodo.opciones.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...nodo.opciones.map((op) {
              final etiqueta = (op['etiqueta'] ?? op['valor'] ?? '').toString();
              final destino = (op['destinoNombre'] ?? '').toString();
              return Padding(
                padding: const EdgeInsets.only(top: 3, left: 2),
                child: Text(
                  destino.isNotEmpty ? '→ $etiqueta: $destino' : '→ $etiqueta',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textoSuave),
                ),
              );
            }),
          ],
          if (nodo.observacion != null && nodo.observacion!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '⚠️ ${nodo.observacion}',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.observado),
              ),
            ),
        ],
      ),
    );
  }

  /// Conector discreto para fork/join (nodos técnicos): el usuario no los ve
  /// como un "paso", solo un punto pequeño + un texto en gris.
  Widget _buildConectorParalelo(FlujoNodo nodo, bool esUltimo) {
    final esFork = nodo.tipo == 'fork';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.textoSuave,
                  shape: BoxShape.circle,
                ),
                child: Icon(esFork ? Icons.call_split : Icons.call_merge,
                    size: 11, color: Colors.white),
              ),
              if (!esUltimo)
                Container(width: 2, height: 26, color: AppColors.borde),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1, bottom: AppSpacing.sm + AppSpacing.xs),
            child: Text(
              esFork
                  ? 'El trámite continúa en varias tareas a la vez'
                  : 'Las tareas paralelas se reúnen para continuar',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textoSuave,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNodoActividad(FlujoNodo nodo, Color color) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        initiallyExpanded: nodo.esActual,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nodo.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (nodo.departamentoCodigo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.business,
                              size: 12, color: AppColors.textoSuave),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${nodo.departamentoCodigo}'
                                  '${nodo.departamentoNombre != null ? ' · ${nodo.departamentoNombre}' : ''}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textoSuave),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _buildBadgeEstado(nodo, color),
          ],
        ),
        children: [
          if (nodo.actividadDescripcion != null && nodo.actividadDescripcion!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                nodo.actividadDescripcion!,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
          if (nodo.slaHoras != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 14, color: AppColors.textoSuave),
                  const SizedBox(width: 6),
                  Text(
                    'SLA: ${nodo.slaHoras} horas',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          if (nodo.funcionarioNombre != null && nodo.funcionarioNombre!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: AppColors.textoSuave),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Asignado a: ${nodo.funcionarioNombre}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          if (nodo.fechaAsignacion != null && nodo.fechaAsignacion!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.login,
                      size: 14, color: AppColors.textoSuave),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Asignado: ${_formatoFecha(nodo.fechaAsignacion!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          if (nodo.fechaCompletado != null && nodo.fechaCompletado!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 14, color: AppColors.exito),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Completado: ${_formatoFecha(nodo.fechaCompletado!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (nodo.documentosRequeridos.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.fondo,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: AppColors.textoSuave),
                  SizedBox(width: 6),
                  Text(
                    'Esta actividad no requiere documentos',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textoSuave),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                const Icon(Icons.folder_outlined,
                    size: 14, color: AppColors.compuerta),
                const SizedBox(width: 6),
                Text(
                  'Documentos requeridos (${nodo.documentosRequeridos.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.compuerta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...nodo.documentosRequeridos.map(
              (doc) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.compuerta.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.compuerta.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 14, color: AppColors.compuerta),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            doc.nombre,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (doc.descripcion != null && doc.descripcion!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 2),
                        child: Text(
                          doc.descripcion!,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textoSuave),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          // Observación / motivo (absorbe el antiguo Historial por nodo).
          if (nodo.observacion != null && nodo.observacion!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.observado.withOpacity(0.08),
                border: Border.all(color: AppColors.observado.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'Observación: ${nodo.observacion}',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.observado),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeEstado(FlujoNodo nodo, Color color) {
    final texto = _textoEstadoNodo(nodo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _colorPorEstadoNodo(FlujoNodo nodo) {
    if (nodo.esActual) return AppColors.primary;
    switch (nodo.estadoSeccion) {
      case 'Derivada':
      case 'completada':
      case 'completado':
        return AppColors.exito;
      case 'En ejecucion':
      case 'en_curso':
        return AppColors.compuerta;
      case 'Pendiente de recepcion':
        return AppColors.compuerta;
      case 'Observado':
      case 'observado':
        return AppColors.observado;
      case 'Bloqueada':
      case 'bloqueada':
      default:
        return AppColors.textoSuave;
    }
  }

  IconData _iconoPorEstadoNodo(FlujoNodo nodo) {
    switch (nodo.tipo) {
      case 'inicio':
        return Icons.play_arrow;
      case 'fin':
        return Icons.flag;
      case 'decision':
        return Icons.alt_route;
      case 'fork':
        return Icons.call_split;
      case 'join':
        return Icons.call_merge;
      default:
        switch (nodo.estadoSeccion) {
          case 'Derivada':
          case 'completada':
          case 'completado':
            return Icons.check;
          case 'En ejecucion':
          case 'en_curso':
            return Icons.edit;
          case 'Pendiente de recepcion':
            return Icons.inbox;
          case 'Observado':
          case 'observado':
            return Icons.warning;
          default:
            return Icons.lock_outline;
        }
    }
  }

  String _textoEstadoNodo(FlujoNodo nodo) {
    if (nodo.esActual) return 'ACTUAL';
    switch (nodo.estadoSeccion) {
      case 'Derivada':
      case 'completada':
      case 'completado':
        return 'DERIVADA';
      case 'En ejecucion':
      case 'en_curso':
        return 'EN EJECUCIÓN';
      case 'Pendiente de recepcion':
        return 'EN BANDEJA';
      case 'Observado':
      case 'observado':
        return 'OBSERVADO';
      case 'Bloqueada':
      case 'bloqueada':
      default:
        return 'PENDIENTE';
    }
  }

  String _formatoFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha;
    }
  }
}
