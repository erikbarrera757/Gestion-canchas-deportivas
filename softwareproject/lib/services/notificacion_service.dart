import 'api_service.dart';
import '../models/notificacion_model.dart';

class NotificacionService {
  static Future<List<NotificacionModel>> getNotificaciones(int usuarioId) async {
    try {
      final data = await ApiService.get('notificaciones/?usuario_id=$usuarioId');
      if (data is List) {
        return data.map((j) => NotificacionModel.fromJson(j)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Marca una notificación específica como leída.
  static Future<void> marcarLeida(int id) async {
    try {
      await ApiService.put('notificaciones/?id=$id', {});
    } catch (_) {}
  }

  /// Marca TODAS las notificaciones de un usuario como leídas.
  static Future<void> marcarTodasLeidas(int usuarioId) async {
    try {
      await ApiService.put('notificaciones/?usuario_id=$usuarioId', {});
    } catch (_) {}
  }

  /// Cantidad de notificaciones NO leídas.
  static int contarNoLeidas(List<NotificacionModel> lista) {
    return lista.where((n) => !n.leida).length;
  }
}
