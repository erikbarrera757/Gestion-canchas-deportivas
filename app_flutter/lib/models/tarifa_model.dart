class Tarifa {
  final int idTarifa;
  final String tipoCancha;
  final String tipoTarifa;
  final double precioHora;
  final double recargoExtra;
  final String estado;

  Tarifa({
    required this.idTarifa,
    required this.tipoCancha,
    required this.tipoTarifa,
    required this.precioHora,
    required this.recargoExtra,
    required this.estado,
  });

  String get descripcion => '$tipoCancha - $tipoTarifa (Bs. ${precioHora.toStringAsFixed(2)}/h)';

  factory Tarifa.fromJson(Map<String, dynamic> json) {
    return Tarifa(
      idTarifa: int.parse(json['id_tarifa'].toString()),
      tipoCancha: json['tipo_cancha'] ?? '',
      tipoTarifa: json['tipo_tarifa'] ?? '',
      precioHora: double.parse(json['precio_hora'].toString()),
      recargoExtra: double.parse(json['recargo_extra'].toString()),
      estado: json['estado'] ?? '',
    );
  }
}
