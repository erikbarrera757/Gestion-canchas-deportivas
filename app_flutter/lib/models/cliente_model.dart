class Cliente {
  final int idCliente;
  final String nombre;
  final String apellido;
  final String telefono;
  final String correo;

  Cliente({
    required this.idCliente,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.correo,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      idCliente: int.parse(json['id_cliente'].toString()),
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      telefono: json['telefono'] ?? '',
      correo: json['correo'] ?? '',
    );
  }
}
