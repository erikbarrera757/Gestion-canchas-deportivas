import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notificacion_service.dart';
import '../models/notificacion_model.dart';
import '../theme/app_theme.dart';

/// Ícono de campana con badge rojo y panel flotante premium.
/// Usa showDialog con barrera transparente para flotar sobre todo el contenido.
class NotificacionBell extends StatefulWidget {
  const NotificacionBell({Key? key, this.onNavigateToSection}) : super(key: key);
  /// Callback para navegar a una sección por nombre ('Mantenimiento', 'Reservar Cancha', etc.)
  final void Function(String sectionTitle)? onNavigateToSection;

  @override
  State<NotificacionBell> createState() => _NotificacionBellState();
}

class _NotificacionBellState extends State<NotificacionBell>
    with SingleTickerProviderStateMixin {
  List<NotificacionModel> _notificaciones = [];
  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cargar();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      await _cargar();
      return mounted;
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final userId = AuthService.currentUser?.id;
    if (userId == null) return;
    final lista = await NotificacionService.getNotificaciones(int.parse(userId));
    if (!mounted) return;
    final prevNoLeidas = NotificacionService.contarNoLeidas(_notificaciones);
    final newNoLeidas = NotificacionService.contarNoLeidas(lista);
    if (newNoLeidas > prevNoLeidas) _shakeCtrl.forward(from: 0);
    setState(() => _notificaciones = lista);
  }

  void _abrirPanel() {
    // Obtenemos posición del widget en pantalla
    final renderBox = context.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = renderBox?.size ?? Size.zero;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (ctx) => _PanelOverlay(
        anchorOffset: offset,
        anchorSize: size,
        notificaciones: _notificaciones,
        onMarcarTodas: () async {
          final userId = AuthService.currentUser?.id;
          if (userId == null) return;
          await NotificacionService.marcarTodasLeidas(int.parse(userId));
          setState(() {
            _notificaciones =
                _notificaciones.map((n) => n.copyWith(leida: true)).toList();
          });
        },
        onMarcarUna: (n) async {
          await NotificacionService.marcarLeida(n.id);
          setState(() {
            final idx = _notificaciones.indexWhere((x) => x.id == n.id);
            if (idx >= 0) {
              _notificaciones[idx] = n.copyWith(leida: true);
            }
          });
        },
        onNavegar: (n) {
          Navigator.pop(ctx);
          _navegar(n);
        },
      ),
    ).then((_) => _cargar());
  }

  void _navegar(NotificacionModel n) {
    if (widget.onNavigateToSection != null) {
      // Navegar DENTRO del HomeScreen (con sidebar)
      switch (n.tipo) {
        case 'nueva_incidencia':
        case 'ticket_completado':
        case 'ticket_asignado':
          widget.onNavigateToSection!('Mantenimiento');
          break;
        case 'nueva_reserva':
        case 'reserva_cancelada':
        case 'reserva_confirmada':
          widget.onNavigateToSection!('Reservar Cancha');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final noLeidas = NotificacionService.contarNoLeidas(_notificaciones);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _shakeCtrl,
          builder: (_, child) {
            final offset =
                ((_shakeCtrl.value * 6) % 1 < 0.5 ? 1 : -1) *
                    _shakeCtrl.value *
                    4.0;
            return Transform.translate(
                offset: Offset(offset, 0), child: child!);
          },
          child: IconButton(
            icon: Icon(
              noLeidas > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: noLeidas > 0 ? Colors.orangeAccent : Colors.white60,
              size: 26,
            ),
            tooltip: noLeidas > 0
                ? '$noLeidas sin leer'
                : 'Notificaciones',
            onPressed: _abrirPanel,
          ),
        ),
        if (noLeidas > 0)
          Positioned(
            top: 4,
            right: 4,
            child: IgnorePointer(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black87, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 6)
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  noLeidas > 9 ? '9+' : '$noLeidas',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Panel flotante como overlay sobre todo
// ─────────────────────────────────────────────
class _PanelOverlay extends StatefulWidget {
  final Offset anchorOffset;
  final Size anchorSize;
  final List<NotificacionModel> notificaciones;
  final Future<void> Function() onMarcarTodas;
  final Future<void> Function(NotificacionModel) onMarcarUna;
  final void Function(NotificacionModel) onNavegar;

  const _PanelOverlay({
    required this.anchorOffset,
    required this.anchorSize,
    required this.notificaciones,
    required this.onMarcarTodas,
    required this.onMarcarUna,
    required this.onNavegar,
  });

  @override
  State<_PanelOverlay> createState() => _PanelOverlayState();
}

class _PanelOverlayState extends State<_PanelOverlay>
    with SingleTickerProviderStateMixin {
  late List<NotificacionModel> _lista;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _lista = List.from(widget.notificaciones);
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  int get _noLeidas => _lista.where((n) => !n.leida).length;

  String _tiempoRelativo(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inSeconds < 60) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'nueva_incidencia':  return Colors.orangeAccent;
      case 'ticket_completado': return const Color(0xFF4CAF82);
      case 'ticket_asignado':   return AppTheme.primaryColor;
      case 'nueva_reserva':
      case 'reserva_confirmada': return const Color(0xFF4A9EFF);
      case 'reserva_cancelada': return Colors.redAccent;
      default:                  return Colors.blueGrey;
    }
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo) {
      case 'nueva_incidencia':  return Icons.warning_amber_rounded;
      case 'ticket_completado': return Icons.check_circle_outline_rounded;
      case 'ticket_asignado':   return Icons.engineering_rounded;
      case 'nueva_reserva':     return Icons.calendar_month_rounded;
      case 'reserva_confirmada': return Icons.event_available_rounded;
      case 'reserva_cancelada': return Icons.event_busy_rounded;
      default:                  return Icons.info_outline_rounded;
    }
  }

  String _labelTipo(String tipo) {
    switch (tipo) {
      case 'nueva_incidencia':  return 'INCIDENCIA';
      case 'ticket_completado': return 'COMPLETADO';
      case 'ticket_asignado':   return 'ASIGNADO';
      case 'nueva_reserva':     return 'RESERVA';
      case 'reserva_confirmada': return 'CONFIRMADA';
      case 'reserva_cancelada': return 'CANCELADA';
      default:                  return 'AVISO';
    }
  }

  bool _tieneDestino(String tipo) => [
        'nueva_incidencia', 'ticket_completado', 'ticket_asignado',
        'nueva_reserva', 'reserva_cancelada', 'reserva_confirmada',
      ].contains(tipo);

  String _labelDestino(String tipo) {
    switch (tipo) {
      case 'nueva_incidencia':
      case 'ticket_completado':
      case 'ticket_asignado':   return 'Mantenimiento';
      default:                  return 'Reservas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    const panelW = 380.0;
    // Posicionar a la derecha de la pantalla, debajo del AppBar
    final left = (screenW - panelW - 16).clamp(0.0, screenW - panelW);

    return Stack(
      children: [
        // Capa transparente para cerrar al tocar fuera
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
        ),

        // Panel flotante
        Positioned(
          top: 62,
          left: left,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              alignment: Alignment.topRight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: panelW,
                  constraints: const BoxConstraints(maxHeight: 500),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14142B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Cabecera ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.07))),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.notifications_rounded,
                                  color: AppTheme.primaryColor, size: 16),
                            ),
                            const SizedBox(width: 10),
                            const Text('Notificaciones',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white)),
                            if (_noLeidas > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('$_noLeidas',
                                    style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                            const Spacer(),
                            if (_noLeidas > 0)
                              TextButton(
                                onPressed: () async {
                                  await widget.onMarcarTodas();
                                  setState(() {
                                    _lista = _lista
                                        .map((n) => n.copyWith(leida: true))
                                        .toList();
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  foregroundColor: AppTheme.primaryColor,
                                ),
                                child: const Text('Leer todas',
                                    style: TextStyle(fontSize: 11)),
                              ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: Colors.white38),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                      // ── Lista ──
                      _lista.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.notifications_off_outlined,
                                      size: 48, color: Colors.white24),
                                  SizedBox(height: 10),
                                  Text('Sin notificaciones',
                                      style:
                                          TextStyle(color: Colors.white38)),
                                ],
                              ),
                            )
                          : Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                itemCount: _lista.length,
                                itemBuilder: (_, i) =>
                                    _buildItem(_lista[i], i),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(NotificacionModel n, int index) {
    final isNew = !n.leida;
    final color = _colorTipo(n.tipo);

    return GestureDetector(
      onTap: () async {
        if (isNew) {
          await widget.onMarcarUna(n);
          setState(() {
            _lista[index] = n.copyWith(leida: true);
          });
        }
        if (_tieneDestino(n.tipo)) {
          widget.onNavegar(n);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isNew
              ? color.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNew
                ? color.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconoTipo(n.tipo), color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo + tiempo
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(_labelTipo(n.tipo),
                            style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                      ),
                      const Spacer(),
                      Text(_tiempoRelativo(n.creadoEn),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10)),
                      if (isNew)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Mensaje
                  Text(
                    n.mensaje,
                    style: TextStyle(
                      color: isNew ? Colors.white : Colors.white54,
                      fontSize: 12,
                      fontWeight:
                          isNew ? FontWeight.w500 : FontWeight.normal,
                      height: 1.4,
                    ),
                  ),
                  // Destino
                  if (_tieneDestino(n.tipo)) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.arrow_forward_rounded,
                            size: 11,
                            color: color.withValues(alpha: 0.8)),
                        const SizedBox(width: 3),
                        Text(
                          'Ir a ${_labelDestino(n.tipo)}',
                          style: TextStyle(
                            color: color.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
