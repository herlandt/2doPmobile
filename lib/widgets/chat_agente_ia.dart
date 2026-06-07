// C3 Guía 2F — Chat del Agente Conversacional de IA (CU-31)
// Uso (auto-contexto): showModalBottomSheet(context, builder: (_) => const ChatAgenteIA())
// Uso (contexto manual): ChatAgenteIA(pantallaActual: '...', tramiteIdOpcional: '...')

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/comunicacion_service.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

class ChatAgenteIA extends StatefulWidget {
  // Si se omiten, el chat deduce el contexto desde el routing actual.
  final String? pantallaActual;
  final String? tramiteIdOpcional;

  const ChatAgenteIA({
    super.key,
    this.pantallaActual,
    this.tramiteIdOpcional,
  });

  @override
  State<ChatAgenteIA> createState() => _ChatAgenteIAState();
}

class _ChatAgenteIAState extends State<ChatAgenteIA> {
  late ComunicacionService comunicacionService;
  final List<_Mensaje> _mensajes = [];
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _esperando = false;

  late final String _modulo;
  late final String? _tramiteId;

  @override
  void initState() {
    super.initState();
    comunicacionService = Get.find<ComunicacionService>();
    _modulo = widget.pantallaActual ?? _modeloDesdeRuta(Get.currentRoute);
    _tramiteId = widget.tramiteIdOpcional ?? _extraerTramiteIdDeArgs();
    _mensajes.add(_Mensaje(
      texto:
          '¡Hola! Soy tu asistente virtual. Puedo guiarte por tus trámites, '
          'documentos y notificaciones. ¿En qué te ayudo?',
      esCliente: false,
    ));
  }

  String _modeloDesdeRuta(String ruta) {
    if (ruta.isEmpty || ruta == '/') return 'Inicio';
    return ruta;
  }

  String? _extraerTramiteIdDeArgs() {
    final args = Get.arguments;
    if (args is String && args.length >= 8) return args;
    if (args is Map) {
      final v = args['tramiteId'] ?? args['id'];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty || _esperando) return;

    setState(() {
      _mensajes.add(_Mensaje(texto: texto, esCliente: true));
      _ctrl.clear();
      _esperando = true;
    });
    _scrollAbajo();

    final res = await comunicacionService.consultarAgenteIA(
      texto,
      _modulo,
      tramiteIdOpcional: _tramiteId,
    );

    final accion = res['accion'];
    setState(() {
      _mensajes.add(_Mensaje(
        texto: res['respuesta'] ?? 'Sin respuesta.',
        esCliente: false,
        accionLabel: accion is Map ? accion['label'] as String? : null,
        accionRuta: accion is Map ? accion['ruta'] as String? : null,
        accionTipo: accion is Map ? accion['tipo'] as String? : null,
        accionDato: accion is Map ? accion['dato'] as String? : null,
      ));
      _esperando = false;
    });
    _scrollAbajo();
  }

  /// El agente devuelve rutas del WEB (/cliente/...). Las traducimos a las del
  /// móvil; si no hay equivalente, devolvemos null (y se oculta el botón).
  String? _rutaMovil(String? rutaWeb) {
    if (rutaWeb == null || rutaWeb.isEmpty) return null;
    final r = rutaWeb.toLowerCase();
    if (r.contains('notif')) return AppRoutes.notificaciones;
    if (r.contains('perfil') || r.contains('cuenta')) return AppRoutes.perfil;
    if (r.contains('catalogo') || r.contains('nuevo') || r.contains('iniciar')) {
      return AppRoutes.catalogoTramites;
    }
    if (r.contains('tramite') || r.contains('expediente')) {
      return AppRoutes.misTramites;
    }
    return null;
  }

  void _ejecutarAccion(_Mensaje m) {
    // Recomendación: iniciar directamente el trámite sugerido (con su id).
    if (m.accionTipo == 'iniciar' &&
        m.accionDato != null &&
        m.accionDato!.isNotEmpty) {
      Get.back();
      Get.toNamed('/tramite-nuevo', arguments: m.accionDato);
      return;
    }
    final mapeada = _rutaMovil(m.accionRuta);
    if (mapeada == null) return;
    Get.back();
    Get.toNamed(mapeada);
  }

  void _scrollAbajo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Cabecera
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.ia,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asistente virtual',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Te ayuda con tus trámites',
                      style: TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),

          // Mensajes
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _mensajes.length,
              itemBuilder: (context, i) => _buildBurbuja(_mensajes[i]),
            ),
          ),

          if (_esperando)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'El asistente está escribiendo…',
                  style: TextStyle(
                      color: AppColors.textoSuave,
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ),

          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.fondo,
              border: Border(top: BorderSide(color: AppColors.borde)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu consulta…',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.superficie,
                    ),
                    onSubmitted: (_) => _enviar(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor:
                      _esperando ? AppColors.textoSuave : AppColors.ia,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _esperando ? null : _enviar,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBurbuja(_Mensaje m) {
    final esIniciar =
        m.accionTipo == 'iniciar' && (m.accionDato?.isNotEmpty ?? false);
    final mostrarAccion = !m.esCliente &&
        m.accionLabel != null &&
        (esIniciar || _rutaMovil(m.accionRuta) != null);
    return Align(
      alignment: m.esCliente ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            m.esCliente ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration(
              color: m.esCliente
                  ? AppColors.primary.withOpacity(0.1)
                  : const Color(0xFFF0EEF7),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(m.esCliente ? 16 : 4),
                bottomRight: Radius.circular(m.esCliente ? 4 : 16),
              ),
            ),
            child: Text(m.texto, style: const TextStyle(fontSize: 14)),
          ),
          if (mostrarAccion)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: Text(m.accionLabel!),
                onPressed: () => _ejecutarAccion(m),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ia,
                  side: const BorderSide(color: AppColors.ia),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Mensaje {
  final String texto;
  final bool esCliente;
  final String? accionLabel;
  final String? accionRuta;
  final String? accionTipo;
  final String? accionDato;
  _Mensaje({
    required this.texto,
    required this.esCliente,
    this.accionLabel,
    this.accionRuta,
    this.accionTipo,
    this.accionDato,
  });
}
