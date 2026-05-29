// C3 Guía 2F — Chat del Agente Conversacional de IA (CU-31)
// Uso (auto-contexto): showModalBottomSheet(context, builder: (_) => const ChatAgenteIA())
// Uso (contexto manual): ChatAgenteIA(pantallaActual: '...', tramiteIdOpcional: '...')

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/comunicacion_service.dart';

class ChatAgenteIA extends StatefulWidget {
  // Si se omiten, el chat deduce el contexto desde el routing actual (Get.currentRoute / Get.arguments).
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
          '¡Hola! Soy tu asistente virtual. Estás en "$_modulo". ¿En qué te puedo ayudar?',
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
      ));
      _esperando = false;
    });
    _scrollAbajo();
  }

  void _ejecutarAccion(String? ruta) {
    if (ruta == null || ruta.isEmpty) return;
    Navigator.pop(context);
    Get.toNamed(ruta);
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
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Cabecera
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.white),
                const SizedBox(width: 10),
                const Text(
                  'Asistente de Soporte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Mensajes
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _mensajes.length,
              itemBuilder: (context, i) {
                final m = _mensajes[i];
                return _buildBurbuja(m);
              },
            ),
          ),

          // Indicador escribiendo
          if (_esperando)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'El asistente está escribiendo...',
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ),

          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                  top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu consulta...',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _enviar(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor:
                      _esperando ? Colors.grey : Colors.indigo,
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
    return Align(
      alignment:
          m.esCliente ? Alignment.centerRight : Alignment.centerLeft,
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
              color: m.esCliente ? Colors.blue.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(m.esCliente ? 16 : 4),
                bottomRight: Radius.circular(m.esCliente ? 4 : 16),
              ),
            ),
            child: Text(m.texto, style: const TextStyle(fontSize: 14)),
          ),
          if (!m.esCliente && m.accionLabel != null && m.accionRuta != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: Text(m.accionLabel!),
                onPressed: () => _ejecutarAccion(m.accionRuta),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  side: const BorderSide(color: Colors.indigo),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
  _Mensaje({
    required this.texto,
    required this.esCliente,
    this.accionLabel,
    this.accionRuta,
  });
}
