enum UserRole {
  administrador,
  cliente,
  vendedorSnack,
  personalMantenimiento,
  encargadoTienda,
}

class UserModel {
  final String id;
  final String nombre;
  final String email;
  final String password; // En producción esto se valida en el backend
  final UserRole role;

  const UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.password,
    required this.role,
  });

  String get roleLabel {
    switch (role) {
      case UserRole.administrador:
        return 'Administrador';
      case UserRole.cliente:
        return 'Cliente';
      case UserRole.vendedorSnack:
        return 'Vendedor Snack';
      case UserRole.personalMantenimiento:
        return 'Personal de Mantenimiento';
      case UserRole.encargadoTienda:
        return 'Encargado de Tienda';
    }
  }

  String get roleIcon {
    switch (role) {
      case UserRole.administrador:
        return '🛡️';
      case UserRole.cliente:
        return '🧑';
      case UserRole.vendedorSnack:
        return '🥤';
      case UserRole.personalMantenimiento:
        return '🔧';
      case UserRole.encargadoTienda:
        return '🎽';
    }
  }
}
