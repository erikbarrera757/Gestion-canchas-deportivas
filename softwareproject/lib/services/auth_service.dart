import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static UserModel? _currentUser;
  static UserModel? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;

  /// Login real contra la API PHP/XAMPP
  static Future<UserModel?> login(String email, String password) async {
    final data = await ApiService.post('auth/login.php', {
      'email': email,
      'password': password,
    });

    if (data['success'] == true) {
      final u = data['user'];
      _currentUser = UserModel(
        id: u['id'].toString(),
        nombre: u['nombre'],
        email: u['email'],
        password: '',
        role: _parseRole(u['rol']),
      );
      return _currentUser;
    }
    return null;
  }

  static void logout() => _currentUser = null;

  static UserRole _parseRole(String rol) {
    switch (rol) {
      case 'administrador':
        return UserRole.administrador;
      case 'vendedor_snack':
        return UserRole.vendedorSnack;
      case 'personal_mantenimiento':
        return UserRole.personalMantenimiento;
      case 'encargado_tienda':
        return UserRole.encargadoTienda;
      default:
        return UserRole.cliente;
    }
  }
}
