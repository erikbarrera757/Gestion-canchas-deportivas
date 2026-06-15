class Reserva {
  final int idReserva;
  final int idCliente;
  final int idCancha;
  final String cliente;
  final String cancha;
  final String tipoCancha;
  final String fecha;
  final String hora;
  final double total;
  final String estado;
  final String productos;

  Reserva({
    required this.idReserva,
    required this.idCliente,
    required this.idCancha,
    required this.cliente,
    required this.cancha,
    required this.tipoCancha,
    required this.fecha,
    required this.hora,
    required this.total,
    required this.estado,
    required this.productos,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      idReserva: int.parse(json['id_reserva'].toString()),
      idCliente: int.parse(json['id_cliente'].toString()),
      idCancha: int.parse(json['id_cancha'].toString()),
      cliente: json['cliente'] ?? '',
      cancha: json['cancha'] ?? '',
      tipoCancha: json['tipo_cancha'] ?? '',
      fecha: json['fecha'] ?? '',
      hora: json['hora'] ?? '',
      total: double.parse(json['total'].toString()),
      estado: json['estado'] ?? '',
      productos: json['productos'] ?? 'Sin productos',
    );
  }
}
