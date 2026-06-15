import 'api_service.dart';

class CanchaService {
  static Future<List<Map<String, dynamic>>> getCanchas() async {
    final data = await ApiService.get('canchas/index.php');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> crearCancha({
    required String nombre,
    required String tipo,
    required double precio,
  }) async {
    return await ApiService.post('canchas/index.php', {
      'nombre': nombre,
      'tipo': tipo,
      'precio': precio,
    });
  }

  static Future<Map<String, dynamic>> actualizarCancha(
    int id, Map<String, dynamic> datos,
  ) async {
    return await ApiService.put('canchas/index.php?id=$id', datos);
  }

  static Future<void> eliminarCancha(int id) async {
    await ApiService.delete('canchas/index.php?id=$id');
  }
}
