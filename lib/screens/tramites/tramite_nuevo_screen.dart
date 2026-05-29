// Guía 3F - Pantalla de Nuevo Trámite con Formulario Dinámico

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/politica_model.dart';
import '../../models/formulario_model.dart';
import '../../services/auth_service.dart';
import '../../services/tramites_service.dart';
import '../../services/tramites_envio_service.dart';

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
      setState(() => mensajeError = 'Error al cargar los datos: $e');
    } finally {
      setState(() => cargando = false);
    }
  }

  /// Crear TextEditingController para cada campo del formulario
  void _crearControladores() {
    if (formulario == null) return;

    for (var campo in formulario!.campos) {
      controladores[campo.nombre] = TextEditingController();
    }
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

  /// Validar todo el formulario
  bool _validarFormulario() {
    if (formulario == null) return false;

    bool valido = true;
    for (var campo in formulario!.campos) {
      final controller = controladores[campo.nombre];
      if (controller != null) {
        final error = _validarCampo(campo, controller.text);
        if (error != null) {
          valido = false;
          break;
        }
      }
    }

    return valido;
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
            border: const OutlineInputBorder(),
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
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) => datosFormulario[campo.nombre] = value,
          validator: (value) => _validarCampo(campo, value ?? ''),
        );

      case 'select':
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
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
        return CheckboxListTile(
          title: Text(label),
          value: datosFormulario[campo.nombre] == 'true',
          onChanged: (value) {
            setState(() {
              datosFormulario[campo.nombre] = value?.toString() ?? 'false';
            });
          },
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

    if (!_validarFormulario()) {
      setState(() =>
          mensajeError = 'Por favor completa todos los campos requeridos correctamente');
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
        mensajeExito = '✅ Trámite enviado exitosamente\nCódigo: ${respuesta.codigo}';
      });

      print('✅ Trámite enviado: ${respuesta.codigo}');

      // Redirigir después de 2 segundos
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Get.back();
      }
    } catch (e) {
      print('❌ Error enviando trámite: $e');
      setState(() => mensajeError = 'Error al enviar trámite: $e');
    } finally {
      setState(() => enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Trámite'),
        elevation: 0,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información de la política
                  if (politica != null)
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              politica!.nombre,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              politica!.descripcion,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Mensajes de error
                  if (mensajeError != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                mensajeError!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (mensajeError != null) const SizedBox(height: 16),

                  // Mensajes de éxito
                  if (mensajeExito != null)
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                mensajeExito!,
                                style: TextStyle(color: Colors.green.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (mensajeExito != null) const SizedBox(height: 16),

                  // Título del formulario
                  if (formulario != null) ...[
                    Text(
                      formulario!.nombre,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formulario!.descripcion ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Campos del formulario
                    ...formulario!.campos.map((campo) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: _construirCampo(campo),
                      );
                    }),
                    const SizedBox(height: 24),

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
                            label: Text(enviando ? 'Enviando...' : 'Enviar Trámite'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: enviando ? null : () => Get.back(),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Info box
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ℹ️ Información Importante',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text('• Los campos con * son obligatorios'),
                            const Text('• Verifica que la información sea correcta'),
                            const Text(
                              '• Recibirás un código para seguimiento del trámite',
                            ),
                            const Text(
                              '• El proceso puede durar varios días',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
