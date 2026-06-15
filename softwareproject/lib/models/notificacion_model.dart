import 'package:flutter/foundation.dart';

class NotificacionModel {
  final int id;
  final int usuarioDestinoId;
  final String tipo;
  final String mensaje;
  final bool leida;
  final int? referenciaId;
  final DateTime creadoEn;

  NotificacionModel({
    required this.id,
    required this.usuarioDestinoId,
    required this.tipo,
    required this.mensaje,
    required this.leida,
    this.referenciaId,
    required this.creadoEn,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: int.parse(json['id'].toString()),
      usuarioDestinoId: int.parse(json['usuario_destino_id'].toString()),
      tipo: json['tipo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      leida: (json['leida'] ?? 0).toString() == '1',
      referenciaId: json['referencia_id'] != null ? int.parse(json['referencia_id'].toString()) : null,
      creadoEn: DateTime.tryParse(json['creado_en'] ?? '') ?? DateTime.now(),
    );
  }

  NotificacionModel copyWith({
    int? id,
    int? usuarioDestinoId,
    String? tipo,
    String? mensaje,
    bool? leida,
    int? referenciaId,
    DateTime? creadoEn,
  }) {
    return NotificacionModel(
      id: id ?? this.id,
      usuarioDestinoId: usuarioDestinoId ?? this.usuarioDestinoId,
      tipo: tipo ?? this.tipo,
      mensaje: mensaje ?? this.mensaje,
      leida: leida ?? this.leida,
      referenciaId: referenciaId ?? this.referenciaId,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }
}
