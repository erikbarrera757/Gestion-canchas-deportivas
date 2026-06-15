import 'api_service.dart';

class SnackService {
  static Future<List<Map<String, dynamic>>> getProductos() async {
    final data = await ApiService.get('snack/productos.php');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> registrarVenta({
    required List<Map<String, dynamic>> items,
    required int usuarioId,
  }) async {
    await ApiService.post('snack/ventas.php', {
      'items':      items,
      'usuario_id': usuarioId,
    });
  }

  static Future<List<Map<String, dynamic>>> getVentas() async {
    final data = await ApiService.get('snack/ventas.php');
    return List<Map<String, dynamic>>.from(data);
  }
}
