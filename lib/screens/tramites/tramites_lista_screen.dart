import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/politica_model.dart';
import '../../services/tramites_service.dart';

class TramitesListaScreen extends StatefulWidget {
  const TramitesListaScreen({Key? key}) : super(key: key);

  @override
  State<TramitesListaScreen> createState() => _TramitesListaScreenState();
}

class _TramitesListaScreenState extends State<TramitesListaScreen> {
  late TramitesService tramitesService;
  String _filtroEstado = '';
  String _busqueda = '';

  final List<String> _estadosDisponibles = ['activa', 'borrador', 'archivada'];

  @override
  void initState() {
    super.initState();
    tramitesService = Get.find<TramitesService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPoliticas();
    });
  }

  Future<void> _cargarPoliticas({String? estado}) async {
    try {
      await tramitesService.obtenerPoliticas(estado: estado);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  List<Politica> get _politicasFiltradas {
    List<Politica> resultado = tramitesService.politicas;

    // Filtrar por estado
    if (_filtroEstado.isNotEmpty) {
      resultado = resultado.where((p) => p.estado == _filtroEstado).toList();
    }

    // Filtrar por búsqueda
    if (_busqueda.isNotEmpty) {
      final termino = _busqueda.toLowerCase();
      resultado = resultado
          .where((p) =>
              p.nombre.toLowerCase().contains(termino) ||
              p.descripcion.toLowerCase().contains(termino))
          .toList();
    }

    return resultado;
  }

  String _getEstadoIcono(String estado) {
    const iconos = {
      'activa': '✓',
      'borrador': '⚙',
      'archivada': '📦',
    };
    return iconos[estado] ?? '•';
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'activa':
        return Colors.green;
      case 'borrador':
        return Colors.orange;
      case 'archivada':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trámites Disponibles'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _cargarPoliticas(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Búsqueda
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _busqueda = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Buscar trámite',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filtro por estado
                DropdownButton<String>(
                  isExpanded: true,
                  value: _filtroEstado.isEmpty ? null : _filtroEstado,
                  hint: const Text('Filtrar por estado'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Todos los estados'),
                    ),
                    ..._estadosDisponibles.map((estado) {
                      return DropdownMenuItem(
                        value: estado,
                        child: Text('${_getEstadoIcono(estado)} ${estado.toUpperCase()}'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filtroEstado = value ?? '';
                    });
                    if (value != null && value.isNotEmpty) {
                      _cargarPoliticas(estado: value);
                    } else {
                      _cargarPoliticas();
                    }
                  },
                ),
              ],
            ),
          ),

          // Lista de trámites
          Expanded(
            child: Obx(
              () {
                if (tramitesService.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_politicasFiltradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay trámites disponibles',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        if (_busqueda.isNotEmpty || _filtroEstado.isNotEmpty)
                          const Text(
                            'Intenta cambiar los filtros',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _politicasFiltradas.length,
                  itemBuilder: (context, index) {
                    final politica = _politicasFiltradas[index];
                    return _buildTramiteCard(politica);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTramiteCard(Politica politica) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Get.toNamed('/tramite-detalle', arguments: politica.id),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: Título y Estado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          politica.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          politica.descripcion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(politica.estado).withOpacity(0.2),
                      border: Border.all(
                        color: _getEstadoColor(politica.estado),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      politica.estado.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getEstadoColor(politica.estado),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Información
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${politica.duracionDiasLimite} días límite',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (politica.requiereAprobacion)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.verified, size: 16, color: Colors.blue[600]),
                          const SizedBox(width: 6),
                          Text(
                            'Requiere aprobación',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: politica.estado == 'activa'
                          ? () => Get.toNamed(
                                '/tramite-nuevo',
                                arguments: politica.id,
                              )
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Iniciar Trámite'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Get.toNamed('/tramite-detalle', arguments: politica.id),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Ver Detalles'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
