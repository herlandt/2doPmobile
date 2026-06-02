// Cola offline de subidas (CU-33 reforzado).
//
// Cuando el dispositivo no tiene conexión al pulsar "Subir documento", la
// pantalla encola la tarea en UploadQueueService y muestra un aviso al
// usuario. Al recuperar conexión, el servicio procesa la cola en FIFO,
// con reintento exponencial (5s, 15s, 60s) hasta máx. 3 intentos.

enum UploadEstado { pendiente, subiendo, completado, fallido }

UploadEstado _estadoDesdeString(String? s) {
  switch (s) {
    case 'subiendo':
      return UploadEstado.subiendo;
    case 'completado':
      return UploadEstado.completado;
    case 'fallido':
      return UploadEstado.fallido;
    case 'pendiente':
    default:
      return UploadEstado.pendiente;
  }
}

String _estadoAString(UploadEstado e) {
  switch (e) {
    case UploadEstado.subiendo:
      return 'subiendo';
    case UploadEstado.completado:
      return 'completado';
    case UploadEstado.fallido:
      return 'fallido';
    case UploadEstado.pendiente:
      return 'pendiente';
  }
}

class UploadTask {
  final String id;
  final String tramiteId;
  final String actividadId;
  final String documentoNombre;
  final String archivoPath;
  UploadEstado estado;
  int intentos;
  final DateTime creadoEn;
  String? ultimoError;
  DateTime? proximoIntento;

  UploadTask({
    required this.id,
    required this.tramiteId,
    required this.actividadId,
    required this.documentoNombre,
    required this.archivoPath,
    this.estado = UploadEstado.pendiente,
    this.intentos = 0,
    DateTime? creadoEn,
    this.ultimoError,
    this.proximoIntento,
  }) : creadoEn = creadoEn ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'tramiteId': tramiteId,
        'actividadId': actividadId,
        'documentoNombre': documentoNombre,
        'archivoPath': archivoPath,
        'estado': _estadoAString(estado),
        'intentos': intentos,
        'creadoEn': creadoEn.toIso8601String(),
        'ultimoError': ultimoError,
        'proximoIntento': proximoIntento?.toIso8601String(),
      };

  factory UploadTask.fromJson(Map<String, dynamic> json) {
    return UploadTask(
      id: json['id']?.toString() ?? '',
      tramiteId: json['tramiteId']?.toString() ?? '',
      actividadId: json['actividadId']?.toString() ?? '',
      documentoNombre: json['documentoNombre']?.toString() ?? '',
      archivoPath: json['archivoPath']?.toString() ?? '',
      estado: _estadoDesdeString(json['estado']?.toString()),
      intentos: (json['intentos'] as num?)?.toInt() ?? 0,
      creadoEn:
          DateTime.tryParse(json['creadoEn']?.toString() ?? '') ?? DateTime.now(),
      ultimoError: json['ultimoError']?.toString(),
      proximoIntento: DateTime.tryParse(json['proximoIntento']?.toString() ?? ''),
    );
  }
}
