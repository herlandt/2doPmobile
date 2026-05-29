// Guía 4F - Pantalla de Seguimiento Detallado de Trámite
//
// Parte 2 — añadidos:
//   • Chip de riesgo IA (CU-43) en el card de estado.
//   • Sección "Documentos del repositorio" en la pestaña Resumen (CU-34).
// NOTA: CU-42 (ruta óptima IA) se removió — pertenece al flujo cliente
// previo (CU-40 al iniciar trámite con IA), no al seguimiento.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/documento_archivo_model.dart';
import '../../models/tramite_estado_model.dart';
import '../../models/flujo_completo_model.dart';
import '../../models/tramite_riesgo_model.dart';
import '../../services/documento_archivo_service.dart';
import '../../services/ia_service.dart';
import '../../services/tramites_seguimiento_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/chip_riesgo_widget.dart';
import '../../widgets/preview_documento_widget.dart';

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
  String pestanaActiva = 'resumen';
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
        SnackBar(content: Text('No se pudo abrir el documento: $e')),
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
          SnackBar(content: Text('Error: ${e.toString()}')),
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
          SnackBar(content: Text('Error al cargar flujo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoFlujo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de Trámite'),
        elevation: 0,
        actions: [
          // C3: Acceso a la línea de tiempo visual
          if (estado != null)
            IconButton(
              icon: const Icon(Icons.timeline),
              tooltip: 'Línea de Tiempo',
              onPressed: () => Get.toNamed(
                AppRoutes.detalleLineaTiempo,
                arguments: {
                  'tramiteId': tramiteId,
                  'codigo': estado!.codigo,
                },
              ),
            ),
        ],
      ),
      body: Obx(
        () {
          if (tramitesSeguimientoService.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (estado == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Error al cargar el trámite'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _cargarEstado,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card de Estado General
                _buildCardEstadoGeneral(context),
                const SizedBox(height: 16),

                // Pestañas
                _buildPestanas(),
                const SizedBox(height: 16),

                // Contenido según pestaña
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildContenidoPestana(),
                ),
                const SizedBox(height: 24),
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

  Widget _buildCardEstadoGeneral(BuildContext context) {
    final color = tramitesSeguimientoService.getColorEstadoFlutter(estado!.estado);
    final progreso = _progresoEfectivo;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    border: Border.all(color: color),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${tramitesSeguimientoService.getIconoEstado(estado!.estado)} ${tramitesSeguimientoService.getTextoEstado(estado!.estado)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progreso / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Etapa Actual / Estado final
            if (_esCerrado)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  border: Border.all(color: color.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      estado!.estado == 'Rechazado' || estado!.estado == 'rechazado'
                          ? Icons.cancel_outlined
                          : Icons.check_circle_outline,
                      color: color,
                    ),
                    const SizedBox(width: 10),
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
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⏳ Etapa Actual',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPestanas() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            _buildBotonPestana('resumen', '📋 Resumen'),
            const SizedBox(width: 8),
            _buildBotonPestana('flujo', '🛤️ Flujo'),
            const SizedBox(width: 8),
            _buildBotonPestana('secciones', '📑 Secciones'),
            const SizedBox(width: 8),
            _buildBotonPestana('historial', '📜 Historial'),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonPestana(String nombre, String label) {
    final activa = pestanaActiva == nombre;
    return ElevatedButton(
      onPressed: () {
        setState(() => pestanaActiva = nombre);
        if (nombre == 'flujo') _cargarFlujo();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: activa ? Colors.blue : Colors.grey.shade200,
        foregroundColor: activa ? Colors.white : Colors.black87,
      ),
      child: Text(label),
    );
  }

  Widget _buildContenidoPestana() {
    switch (pestanaActiva) {
      case 'resumen':
        return _buildPestanaResumen();
      case 'flujo':
        return _buildPestanaFlujo();
      case 'secciones':
        return _buildPestanaSecciones();
      case 'historial':
        return _buildPestanaHistorial();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPestanaResumen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CU-43 — Riesgo IA
        if (_riesgo != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Colors.deepPurple, size: 20),
                      const SizedBox(width: 6),
                      const Text(
                        'Riesgo de demora (IA)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(),
                      ChipRiesgoWidget(
                        nivel: _riesgo!.nivel,
                        probSuperarSla: _riesgo!.probSuperarSla,
                      ),
                    ],
                  ),
                  if (_riesgo!.razones.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _riesgo!.razones
                          .map((r) => Chip(
                                label: Text(r,
                                    style: const TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: Colors.grey.shade100,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

        // CU-42 (Sugerencia de ruta IA) se removió de esta pantalla:
        // el flujo correcto es CU-40 — el cliente describe su problema y la
        // IA recomienda el trámite — eso vive en IniciarTramiteIaScreen.

        // CU-34 — Documentos del repositorio
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_open, size: 20),
                    const SizedBox(width: 6),
                    const Text(
                      'Documentos del repositorio',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    if (_cargandoDocumentos)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_documentos.isEmpty && !_cargandoDocumentos)
                  Text(
                    'Aún no hay documentos en el repositorio para este trámite.',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade700),
                  ),
                for (final d in _documentos)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      _iconoTipoDoc(d.tipoDocumento),
                      color: Colors.deepPurple,
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
        ),

        const SizedBox(height: 8),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Próximos Pasos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu trámite está en revisión',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Se te notificará cuando se requiera información adicional o cuando se complete el proceso.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
      children: flujo!.nodos
          .asMap()
          .entries
          .map((e) => _buildNodoFlujo(e.value, e.key == flujo!.nodos.length - 1))
          .toList(),
    );
  }

  Widget _buildNodoFlujo(FlujoNodo nodo, bool esUltimo) {
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
                    ? Border.all(color: Colors.amber, width: 3)
                    : null,
              ),
              child: Icon(icono, color: Colors.white, size: 20),
            ),
            if (!esUltimo)
              Container(
                width: 2,
                height: esActividad ? 80 : 40,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Tarjeta del nodo
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Card(
              elevation: nodo.esActual ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: nodo.esActual
                    ? const BorderSide(color: Colors.amber, width: 2)
                    : BorderSide.none,
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
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
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
                  nodo.tipo.toUpperCase(),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (nodo.esActual)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ACTUAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
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
                          Icon(Icons.business, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${nodo.departamentoCodigo}'
                                  '${nodo.departamentoNombre != null ? ' · ${nodo.departamentoNombre}' : ''}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                  const Icon(Icons.timer_outlined, size: 14, color: Colors.blueGrey),
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
                  const Icon(Icons.person_outline, size: 14, color: Colors.blueGrey),
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
          const SizedBox(height: 8),
          if (nodo.documentosRequeridos.isEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Esta actividad no requiere documentos',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                const Icon(Icons.folder_outlined, size: 14, color: Colors.indigo),
                const SizedBox(width: 6),
                Text(
                  'Documentos requeridos (${nodo.documentosRequeridos.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...nodo.documentosRequeridos.map(
              (doc) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 14, color: Colors.indigo),
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
                          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                        ),
                      ),
                  ],
                ),
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
    if (nodo.esActual) return Colors.amber.shade700;
    switch (nodo.estadoSeccion) {
      case 'completada':
      case 'completado':
        return Colors.green;
      case 'en_curso':
        return Colors.blue;
      case 'observado':
        return Colors.orange;
      case 'bloqueada':
      default:
        return Colors.grey;
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
          case 'completada':
            return Icons.check;
          case 'en_curso':
            return Icons.edit;
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
      case 'completada':
      case 'completado':
        return 'COMPLETADA';
      case 'en_curso':
        return 'EN CURSO';
      case 'observado':
        return 'OBSERVADO';
      case 'bloqueada':
      default:
        return 'PENDIENTE';
    }
  }

  Widget _buildPestanaSecciones() {
    if (estado!.expediente.secciones.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No hay secciones disponibles'),
        ),
      );
    }

    return Column(
      children: estado!.expediente.secciones
          .map(
            (seccion) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                seccion.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (seccion.departamento != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Depto: ${seccion.departamento}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getColorSeccion(seccion.estado),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getTextoSeccion(seccion.estado),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (seccion.fechaInicio != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        '📅 Inicio: ${_formatoFecha(seccion.fechaInicio!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPestanaHistorial() {
    if (estado!.historial.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No hay eventos en el historial'),
        ),
      );
    }

    return Column(
      children: estado!.historial
          .asMap()
          .entries
          .map(
            (entry) {
              final evento = entry.value;
              final esUltimo = entry.key == estado!.historial.length - 1;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              tramitesSeguimientoService.getIconoEvento(evento.tipo),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        if (!esUltimo)
                          Container(
                            width: 2,
                            height: 30,
                            color: Colors.grey.shade300,
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            evento.descripcion,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatoFecha(evento.fecha),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          if (evento.usuario != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Usuario: ${evento.usuario}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          )
          .toList(),
    );
  }

  Color _getColorSeccion(String estado) {
    switch (estado) {
      case 'completada':
        return Colors.green;
      case 'en_curso':
        return Colors.blue;
      case 'bloqueada':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getTextoSeccion(String estado) {
    const textos = {
      'completada': 'Completada',
      'en_curso': 'En Curso',
      'bloqueada': 'Bloqueada',
    };
    return textos[estado] ?? estado;
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
