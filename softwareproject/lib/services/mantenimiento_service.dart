import 'api_service.dart';

class MantenimientoService {
  static Future<List<Map<String, dynamic>>> getTickets() async {
    final data = await ApiService.get('mantenimiento/tickets.php');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> registrarTicket({
    required int canchaId,
    required int reportadoPor,
    required String tipo,
    required String descripcion,
  }) async {
    return await ApiService.post('mantenimiento/tickets.php', {
      'cancha_id':     canchaId,
      'reportado_por': reportadoPor,
      'tipo':          tipo,
      'descripcion':   descripcion,
    });
  }

  static Future<Map<String, dynamic>> actualizarTicket(
    int id, Map<String, dynamic> datos,
  ) async {
    return await ApiService.put('mantenimiento/tickets.php?id=$id', datos);
  }

  static Future<List<Map<String, dynamic>>> getPersonalMantenimiento() async {
    final data = await ApiService.get('usuarios/index.php?rol=personal_mantenimiento');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getReporte(String tipo) async {
    final data = await ApiService.get('reportes/index.php?tipo=$tipo');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> getResumen() async {
    return await ApiService.get('reportes/index.php?tipo=resumen');
  }
}
