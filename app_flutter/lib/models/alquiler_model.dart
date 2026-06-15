class Alquiler {
  final int idAlquiler;
  final int idCliente;
  final int idCancha;
  final int? idReserva;
  final int idTarifa;
  final String cliente;
  final String cancha;
  final String tipoCancha;
  final String tarifa;
  final double precioHora;
  final double recargoExtra;
  final String horaInicio;
  final int tiempoPactado;
  final int minutosTranscurridos;
  final bool tieneExtra;
  final String estado;
  final String observacion;

  Alquiler({
    required this.idAlquiler,
    required this.idCliente,
    required this.idCancha,
    required this.idReserva,
    required this.idTarifa,
    required this.cliente,
    required this.cancha,
    required this.tipoCancha,
    required this.tarifa,
    required this.precioHora,
    required this.recargoExtra,
    required this.horaInicio,
    required this.tiempoPactado,
    required this.minutosTranscurridos,
    required this.tieneExtra,
    required this.estado,
    required this.observacion,
  });

  factory Alquiler.fromJson(Map<String, dynamic> json) {
    return Alquiler(
      idAlquiler: int.parse(json['id_alquiler'].toString()),
      idCliente: int.parse(json['id_cliente'].toString()),
      idCancha: int.parse(json['id_cancha'].toString()),
      idReserva: json['id_reserva'] == null ? null : int.parse(json['id_reserva'].toString()),
      idTarifa: int.parse(json['id_tarifa'].toString()),
      cliente: json['cliente'] ?? '',
      cancha: json['cancha'] ?? '',
      tipoCancha: json['tipo_cancha'] ?? '',
      tarifa: json['tarifa'] ?? '',
      precioHora: double.parse(json['precio_hora'].toString()),
      recargoExtra: double.parse(json['recargo_extra'].toString()),
      horaInicio: json['hora_inicio'] ?? '',
      tiempoPactado: int.parse(json['tiempo_pactado'].toString()),
      minutosTranscurridos: int.parse(json['minutos_transcurridos'].toString()),
      tieneExtra: json['tiene_extra'].toString() == '1',
      estado: json['estado'] ?? '',
      observacion: json['observacion'] ?? '',
    );
  }
}
