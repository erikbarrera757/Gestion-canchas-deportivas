class Cancha {
  final int idCancha;
  final String nombre;
  final String tipo;
  final double precio;
  final String estado;

  Cancha({
    required this.idCancha,
    required this.nombre,
    required this.tipo,
    required this.precio,
    required this.estado,
  });

  factory Cancha.fromJson(Map<String, dynamic> json) {
    return Cancha(
      idCancha: int.parse(json['id_cancha'].toString()),
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      precio: double.parse(json['precio'].toString()),
      estado: json['estado'] ?? '',
    );
  }
}
