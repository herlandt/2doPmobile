// Guía 3F - Pantalla de Nuevo Trámite con Formulario Dinámico

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/politica_model.dart';
import '../../models/formulario_model.dart';
import '../../models/tramite_resumen_model.dart';
import '../../services/auth_service.dart';
import '../../services/tramites_service.dart';
import '../../services/tramites_envio_service.dart';
import '../../utils/error_messages.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import 'realizar_correccion_screen.dart';

class TramiteNuevoScreen extends StatefulWidget {
  const TramiteNuevoScreen({Key? key}) : super(key: key);

  @override
  State<TramiteNuevoScreen> createState() => _TramiteNuevoScreenState();
}

class _TramiteNuevoScreenState extends State<TramiteNuevoScreen> {
  late AuthService authService;
  late TramitesService tramitesService;
  late TramitesEnvioService tramitesEnvioService;

  String politicaId = '';
  Politica? politica;
  FormularioPlantilla? formulario;

  final Map<String, TextEditingController> controladores = {};
  final Map<String, String> datosFormulario = {};
  final _formKey = GlobalKey<FormState>();

  bool cargando = false;
  bool enviando = false;
  String? mensajeError;
  String? mensajeExito;

  @override
  void initState() {
    super.initState();
    authService = Get.find<AuthService>();
    tramitesService = Get.find<TramitesService>();
    tramitesEnvioService = Get.find<TramitesEnvioService>();

    // Obtener politicaId de los parámetros
    final arguments = Get.arguments;
    if (arguments != null && arguments is String) {
      politicaId = arguments;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarDatos();
      });
    } else {
      print('⚠️ No se proporcionó politicaId');
    }
  }

  @override
  void dispose() {
    for (var controller in controladores.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Cargar datos iniciales: política y formulario
  Future<void> _cargarDatos() async {
    if (politicaId.isEmpty) return;

    setState(() => cargando = true);
    mensajeError = null;

    try {
      print('📋 Cargando política: $politicaId');

      // Cargar política
      final politicaCargar = await tramitesService.obtenerPoliticaPorId(politicaId);

      // Cargar formulario plantilla
      final formularioCargar =
          await tramitesEnvioService.obtenerFormularioPlantilla(politicaId);

      setState(() {
        politica = politicaCargar;
        formulario = formularioCargar;
      });

      // Crear controladores de texto para cada campo
      _crearControladores();

      print('✅ Datos cargados exitosamente');
    } catch (e) {
      print('❌ Error cargando datos: $e');
      setState(() => mensajeError = mensajeAmigable(e));
    } finally {
      setState(() => cargando = false);
    }
  }

  /// Crear TextEditingController para cada campo del formulario,
  /// pre-llenando con los datos del perfil del usuario según el CONTRATO
  /// de autollenado (mapeo por nombre de campo → dato del perfil).
  void _crearControladores() {
    if (formulario == null) return;

    for (var campo in formulario!.campos) {
      final inicial = _valorAutollenado(campo.nombre);
      final controller = TextEditingController(text: inicial);
      controladores[campo.nombre] = controller;
      // Mantener datosFormulario en sync para los campos pre-llenados
      // (los handlers onChanged solo lo actualizan al editar).
      if (inicial.isNotEmpty) {
        datosFormulario[campo.nombre] = inicial;
      }
    }
  }

  /// Devuelve el dato del perfil que corresponde a un campo del formulario,
  /// según su nombre. Si el perfil no tiene el dato (o no hay mapeo), '' .
  String _valorAutollenado(String nombreCampo) {
    final usuario = authService.usuarioActual.value;
    if (usuario == null) return '';

    final nombre = nombreCampo.toLowerCase();

    // nombre completo / solicitante → "nombre apellido"
    if (nombre == 'nombre' ||
        nombre == 'nombre_completo' ||
        nombre == 'solicitante') {
      return '${usuario.nombre} ${usuario.apellido}'.trim();
    }

    // documento de identidad
    if (nombre == 'cedula' ||
        nombre == 'dni' ||
        nombre == 'ci' ||
        nombre == 'carnet' ||
        nombre == 'documento') {
      return usuario.dni;
    }

    // teléfono
    if (nombre == 'telefono' || nombre == 'celular' || nombre == 'movil') {
      return usuario.telefono;
    }

    // correo
    if (nombre == 'correo' || nombre == 'email') {
      return usuario.email;
    }

    // dirección
    if (nombre == 'direccion' || nombre == 'domicilio') {
      return usuario.direccion;
    }

    return '';
  }

  /// Validar campo según sus reglas
  String? _validarCampo(CampoFormulario campo, String valor) {
    // Requerido
    if (campo.requerido && valor.isEmpty) {
      return '${campo.etiqueta} es requerido';
    }

    if (valor.isEmpty) return null;

    final validaciones = campo.validaciones;

    // Min length
    if (validaciones?['minLength'] != null) {
      final minLength = validaciones!['minLength'] as int;
      if (valor.length < minLength) {
        return 'Mínimo $minLength caracteres';
      }
    }

    // Max length
    if (validaciones?['maxLength'] != null) {
      final maxLength = validaciones!['maxLength'] as int;
      if (valor.length > maxLength) {
        return 'Máximo $maxLength caracteres';
      }
    }

    // Email
    if (campo.tipo == 'email') {
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(valor)) {
        return 'Email inválido';
      }
    }

    // Pattern
    if (validaciones?['pattern'] != null) {
      final pattern = validaciones!['pattern'] as String;
      final regex = RegExp(pattern);
      if (!regex.hasMatch(valor)) {
        return 'Formato inválido';
      }
    }

    return null;
  }

  /// Devuelve las ETIQUETAS de los campos requeridos/inválidos (vacío = todo OK),
  /// para decirle al usuario exactamente cuáles revisar.
  List<String> _camposInvalidos() {
    if (formulario == null) return const [];
    final invalidos = <String>[];
    for (var campo in formulario!.campos) {
      if (campo.tipo == 'checkbox') continue; // el checkbox no valida por texto
      final controller = controladores[campo.nombre];
      final valor = controller?.text ?? '';
      if (_validarCampo(campo, valor) != null) {
        invalidos.add(campo.etiqueta);
      }
    }
    return invalidos;
  }

  /// Construir el campo según su tipo
  Widget _construirCampo(CampoFormulario campo) {
    final controller = controladores[campo.nombre];
    if (controller == null) return const SizedBox.shrink();

    final label =
        '${campo.etiqueta}${campo.requerido ? ' *' : ''}';

    switch (campo.tipo) {
      case 'text':
      case 'email':
      case 'tel':
      case 'date':
        return TextFormField(
          controller: controller,
          keyboardType: _getKeyboardType(campo.tipo),
          decoration: InputDecoration(
            labelText: label,
            hintText: campo.placeholder,
          ),
          onChanged: (value) => datosFormulario[campo.nombre] = value,
          validator: (value) => _validarCampo(campo, value ?? ''),
        );

      case 'textarea':
        return TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: label,
            hintText: campo.placeholder,
          ),
          onChanged: (value) => datosFormulario[campo.nombre] = value,
          validator: (value) => _validarCampo(campo, value ?? ''),
        );

      case 'select':
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
          ),
          items: campo.opciones
              ?.map((opcion) => DropdownMenuItem(
                    value: opcion.value,
                    child: Text(opcion.label),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              controller.text = value;
              datosFormulario[campo.nombre] = value;
            }
          },
          validator: (value) => _validarCampo(campo, value ?? ''),
        );

      case 'checkbox':
        return AppCard(
          padding: EdgeInsets.zero,
          child: CheckboxListTile(
            title: Text(label),
            activeColor: AppColors.primary,
            value: datosFormulario[campo.nombre] == 'true',
            onChanged: (value) {
              setState(() {
                datosFormulario[campo.nombre] = value?.toString() ?? 'false';
              });
            },
          ),
        );

      default:
        return Text('Tipo de campo no soportado: ${campo.tipo}');
    }
  }

  /// Obtener tipo de teclado según el tipo de campo
  TextInputType _getKeyboardType(String tipo) {
    switch (tipo) {
      case 'email':
        return TextInputType.emailAddress;
      case 'tel':
        return TextInputType.phone;
      case 'date':
        return TextInputType.datetime;
      default:
        return TextInputType.text;
    }
  }

  /// Enviar el formulario
  Future<void> _enviarFormulario() async {
    setState(() {
      mensajeError = null;
      mensajeExito = null;
    });

    // Dispara los errores INLINE bajo cada campo, y arma la lista de cuáles faltan.
    final formOk = _formKey.currentState?.validate() ?? true;
    final faltantes = _camposInvalidos();
    if (!formOk || faltantes.isNotEmpty) {
      setState(() => mensajeError = faltantes.isEmpty
          ? 'Revisa los campos marcados en rojo.'
          : 'Completa o corrige: ${faltantes.join(', ')}');
      return;
    }

    setState(() => enviando = true);

    try {
      // Recopilar datos del formulario
      final datos = <String, dynamic>{};
      controladores.forEach((key, controller) {
        datos[key] = controller.text;
      });

      print('📝 Enviando formulario con datos:');
      datos.forEach((k, v) => print('   - $k: $v'));

      final clienteId = authService.usuarioActual.value?.id ?? 'unknown';

      // Enviar trámite
      final respuesta = await tramitesEnvioService.enviarTramite(
        politicaId: politicaId,
        clienteId: clienteId,
        datos: datos,
        prioridad: 3,
      );

      setState(() {
        mensajeExito = '✅ Trámite creado: ${respuesta.codigo}\n'
            'Ahora sube los documentos requeridos para continuar.';
      });

      print('✅ Trámite enviado: ${respuesta.codigo}');

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        // Tras crear, el trámite queda esperando los documentos del primer nodo
        // (compuerta). Llevamos al cliente directo a subirlos, en vez de volver al home.
        final resumen = TramiteResumen(
          id: respuesta.tramiteId,
          codigo: respuesta.codigo,
          politicaNombre: politica?.nombre ?? '',
          estado: 'En curso',
          nodoActualNombre: '',
          fechaInicio: '',
          progreso: 0,
        );
        Get.off(() => RealizarCorreccionScreen(tramite: resumen));
      }
    } catch (e) {
      print('❌ Error enviando trámite: $e');
      setState(() => mensajeError = mensajeAmigable(e));
    } finally {
      setState(() => enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Trámite'),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información de la política
                  if (politica != null)
                    AppCard(
                      background: AppColors.compuerta.withOpacity(0.06),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.compuerta.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: const Icon(Icons.description_outlined,
                                    color: AppColors.compuerta, size: 22),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  politica!.nombre,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            politica!.descripcion,
                            style: const TextStyle(color: AppColors.textoSuave),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),

                  // Mensajes de error
                  if (mensajeError != null)
                    AppCard(
                      background: AppColors.peligro.withOpacity(0.06),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.peligro),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              mensajeError!,
                              style: const TextStyle(color: AppColors.peligro),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (mensajeError != null)
                    const SizedBox(height: AppSpacing.md),

                  // Mensajes de éxito
                  if (mensajeExito != null)
                    AppCard(
                      background: AppColors.exito.withOpacity(0.06),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.exito),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              mensajeExito!,
                              style: const TextStyle(color: AppColors.exito),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (mensajeExito != null)
                    const SizedBox(height: AppSpacing.md),

                  // Título del formulario
                  if (formulario != null) ...[
                    SectionHeader(formulario!.nombre),
                    if ((formulario!.descripcion ?? '').isNotEmpty) ...[
                      Text(
                        formulario!.descripcion ?? '',
                        style: const TextStyle(color: AppColors.textoSuave),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),

                    // Campos del formulario (dentro de un Form → errores inline por campo)
                    Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: formulario!.campos.map((campo) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _construirCampo(campo),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: enviando ? null : _enviarFormulario,
                            icon: enviando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label:
                                Text(enviando ? 'Enviando...' : 'Enviar Trámite'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: enviando ? null : () => Get.back(),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancelar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Info box
                    AppCard(
                      background: AppColors.observado.withOpacity(0.06),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.info_outline,
                                  color: AppColors.observado, size: 20),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'Información Importante',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text('• Los campos con * son obligatorios'),
                          const Text(
                              '• Verifica que la información sea correcta'),
                          const Text(
                            '• Recibirás un código para seguimiento del trámite',
                          ),
                          const Text(
                            '• El proceso puede durar varios días',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
