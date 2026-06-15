class Producto {
  final int idProducto;
  final String nombre;
  final double precio;

  Producto({required this.idProducto, required this.nombre, required this.precio});

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      idProducto: int.parse(json['id_producto'].toString()),
      nombre: json['nombre'] ?? '',
      precio: double.parse(json['precio'].toString()),
    );
  }
}
