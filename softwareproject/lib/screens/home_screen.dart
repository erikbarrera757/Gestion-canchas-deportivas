import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'reservations_screen.dart';
import 'snack_screen.dart';
import 'equipment_screen.dart';
import 'maintenance/maintenance_dashboard.dart';
import 'admin/courts_admin_screen.dart';
import 'admin/reports_screen.dart';
import 'login_screen.dart';
import '../widgets/notificacion_bell.dart';

/// Definición de cada ítem de navegación con su rol requerido
class _NavItem {
  final String title;
  final IconData icon;
  final Widget screen;
  final List<UserRole> allowedRoles; // roles que pueden verlo

  const _NavItem({
    required this.title,
    required this.icon,
    required this.screen,
    required this.allowedRoles,
  });
}

const List<_NavItem> _allNavItems = [
  _NavItem(
    title: 'Reservar Cancha',
    icon: Icons.calendar_month,
    screen: ReservationsScreen(),
    allowedRoles: [UserRole.administrador, UserRole.cliente],
  ),
  _NavItem(
    title: 'Snack & Bebidas',
    icon: Icons.fastfood,
    screen: SnackScreen(),
    allowedRoles: [UserRole.administrador, UserRole.vendedorSnack],
  ),
  _NavItem(
    title: 'Tienda Deportiva',
    icon: Icons.shopping_bag,
    screen: EquipmentScreen(),
    allowedRoles: [UserRole.administrador, UserRole.encargadoTienda],
  ),
  _NavItem(
    title: 'Gestión de Canchas',
    icon: Icons.stadium,
    screen: CourtsAdminScreen(),
    allowedRoles: [UserRole.administrador],
  ),
  _NavItem(
    title: 'Mantenimiento',
    icon: Icons.build,
    screen: MaintenanceDashboard(),
    allowedRoles: [UserRole.administrador, UserRole.personalMantenimiento],
  ),
  _NavItem(
    title: 'Reportes',
    icon: Icons.bar_chart,
    screen: ReportsScreen(),
    allowedRoles: [UserRole.administrador],
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<_NavItem> get _visibleItems {
    final role = AuthService.currentUser!.role;
    return _allNavItems.where((item) => item.allowedRoles.contains(role)).toList();
  }

  /// Navega a una sección del sidebar por su título (usado desde notificaciones)
  void _navegarASeccion(String titulo) {
    final items = _visibleItems;
    final idx = items.indexWhere((item) => item.title == titulo);
    if (idx >= 0) setState(() => _selectedIndex = idx);
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      AuthService.logout();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const LoginScreen(),
          transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser!;
    final items = _visibleItems;
    // Protección: si el índice actual queda fuera de rango
    if (_selectedIndex >= items.length) _selectedIndex = 0;

    final size = MediaQuery.of(context).size;
    final isWide = size.width > 720;

    if (isWide) {
      return _buildDesktopLayout(user, items);
    } else {
      return _buildMobileLayout(user, items);
    }
  }

  // ─────────── LAYOUT DESKTOP / WEB ───────────
  Widget _buildDesktopLayout(UserModel user, List<_NavItem> items) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar fijo
          Container(
            width: 260,
            color: AppTheme.cardColor,
            child: Column(
              children: [
                // Logo y usuario
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground,
                    border: Border(bottom: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stadium_rounded, color: AppTheme.primaryColor, size: 30),
                          const SizedBox(width: 10),
                          const Text('SportManager', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildUserAvatar(user),
                    ],
                  ),
                ),
                // Menú
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _buildSidebarTile(items[i], i),
                  ),
                ),
                // Logout
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: AppTheme.errorColor, size: 18),
                      label: const Text('Cerrar Sesión', style: TextStyle(color: AppTheme.errorColor)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // Topbar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: AppTheme.darkBackground,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        items[_selectedIndex].title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          // Notificación (solo admin)
                          if (user.role == UserRole.administrador) ...[
                            NotificacionBell(
                              onNavigateToSection: _navegarASeccion,
                            ),
                          ],
                          const SizedBox(width: 8),
                          Text(user.roleIcon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(user.nombre, style: const TextStyle(color: Colors.white70)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(user.roleLabel, style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: items[_selectedIndex].screen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile(_NavItem item, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          children: [
            Icon(item.icon, color: isSelected ? AppTheme.primaryColor : Colors.white54, size: 22),
            const SizedBox(width: 12),
            Text(
              item.title,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────── LAYOUT MÓVIL ───────────
  Widget _buildMobileLayout(UserModel user, List<_NavItem> items) {
    return Scaffold(
      appBar: AppBar(
        title: Text(items[_selectedIndex].title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(user.roleIcon, style: const TextStyle(fontSize: 22)),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.cardColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                border: Border(bottom: BorderSide(color: AppTheme.primaryColor, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.stadium_rounded, size: 40, color: AppTheme.primaryColor),
                  const SizedBox(height: 8),
                  _buildUserAvatar(user),
                ],
              ),
            ),
            ...List.generate(items.length, (i) => ListTile(
              leading: Icon(items[i].icon, color: _selectedIndex == i ? AppTheme.primaryColor : Colors.white70),
              title: Text(items[i].title, style: TextStyle(color: _selectedIndex == i ? AppTheme.primaryColor : Colors.white)),
              selected: _selectedIndex == i,
              selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              onTap: () {
                setState(() => _selectedIndex = i);
                Navigator.pop(context);
              },
            )),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor),
              title: const Text('Cerrar Sesión', style: TextStyle(color: AppTheme.errorColor)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: items[_selectedIndex].screen,
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel user) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
          child: Text(user.nombre[0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
              Text(user.roleLabel, style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
