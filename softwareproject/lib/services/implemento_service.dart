import 'api_service.dart';

class ImplementoService {
  static Future<List<Map<String, dynamic>>> getImplementos() async {
    final data = await ApiService.get('implementos/index.php');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> procesarTransaccion({
    required int implementoId,
    required int usuarioId,
    required String tipo, // 'Alquiler' o 'Venta'
  }) async {
    return await ApiService.post('implementos/index.php', {
      'implemento_id': implementoId,
      'usuario_id':    usuarioId,
      'tipo':          tipo,
    });
  }
}
