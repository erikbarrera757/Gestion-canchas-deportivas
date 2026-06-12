import 'api_service.dart';

class ReservaService {
  static Future<List<Map<String, dynamic>>> getReservas() async {
    final data = await ApiService.get('reservas/index.php');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> crearReserva({
    required int canchaId,
    required int usuarioId,
    required String horario,
    required String fecha,
  }) async {
    return await ApiService.post('reservas/index.php', {
      'cancha_id':  canchaId,
      'usuario_id': usuarioId,
      'horario':    horario,
      'fecha':      fecha,
    });
  }

  static Future<void> cancelarReserva(int id) async {
    await ApiService.delete('reservas/index.php?id=$id');
  }
}
