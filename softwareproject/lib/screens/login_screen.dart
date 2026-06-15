import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  String? _errorMsg;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _doLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    // Simula latencia de red (en producción sería una llamada HTTP a XAMPP)
    await Future.delayed(const Duration(milliseconds: 800));

    final user = await AuthService.login(_emailCtrl.text, _passCtrl.text);

    if (!mounted) return;
    if (user != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const HomeScreen(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Correo o contraseña incorrectos. Verifica tus datos.';
      });
    }
  }

  void _fillDemo(String email, String pass) {
    _emailCtrl.text = email;
    _passCtrl.text = pass;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      ),
    );
  }

  // Layout para web / escritorio (dos columnas)
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Panel izquierdo decorativo
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.15),
                  AppTheme.secondaryColor.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stadium_rounded, size: 100, color: AppTheme.primaryColor),
                const SizedBox(height: 24),
                Text(
                  'SportManager Pro',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: AppTheme.primaryColor.withValues(alpha: 0.5), blurRadius: 20)],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sistema de Gestión de Canchas Deportivas',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                _buildFeatureBadge(Icons.calendar_month, 'Reservas en tiempo real'),
                const SizedBox(height: 12),
                _buildFeatureBadge(Icons.build_circle, 'Control de Mantenimiento'),
                const SizedBox(height: 12),
                _buildFeatureBadge(Icons.bar_chart, 'Reportes y Estadísticas'),
                const SizedBox(height: 12),
                _buildFeatureBadge(Icons.people, 'Múltiples Roles de Usuario'),
              ],
            ),
          ),
        ),
        // Panel derecho — formulario de login
        Container(
          width: 480,
          color: AppTheme.cardColor,
          padding: const EdgeInsets.all(48),
          child: Center(child: _buildLoginForm()),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.stadium_rounded, size: 70, color: AppTheme.primaryColor),
            const SizedBox(height: 12),
            const Text('SportManager Pro',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 40),
            _buildLoginForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Iniciar Sesión',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Ingresa con tu cuenta asignada',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 36),

          // Email
          TextFormField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined, color: Colors.white54),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'El correo es requerido' : null,
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
              suffixIcon: IconButton(
                icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onFieldSubmitted: (_) => _doLogin(),
            validator: (v) => (v == null || v.isEmpty) ? 'La contraseña es requerida' : null,
          ),
          const SizedBox(height: 12),

          // Error message
          if (_errorMsg != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMsg!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 8),
          // Botón principal
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _doLogin,
              child: _isLoading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                  : const Text('Ingresar al Sistema', style: TextStyle(fontSize: 16)),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),

          // Cuentas de demostración
          const Text('Accesos de demostración:', style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _demoChip('🛡️ Admin', 'admin@canchas.com', 'admin123'),
              _demoChip('🧑 Cliente', 'cliente@canchas.com', 'cliente123'),
              _demoChip('🥤 Snack', 'snack@canchas.com', 'snack123'),
              _demoChip('🔧 Técnico', 'tecnico@canchas.com', 'tecnico123'),
              _demoChip('🎽 Tienda', 'tienda@canchas.com', 'tienda123'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _demoChip(String label, String email, String pass) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      backgroundColor: Colors.white.withValues(alpha: 0.07),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      onPressed: () => _fillDemo(email, pass),
      tooltip: email,
    );
  }

  Widget _buildFeatureBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 15)),
      ],
    );
  }
}
