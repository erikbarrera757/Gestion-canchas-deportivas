import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/cancha_service.dart';
import '../services/reserva_service.dart';
import '../services/api_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  List<Map<String, dynamic>> _canchas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCanchas();
  }

  Future<void> _cargarCanchas() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await CanchaService.getCanchas();
      setState(() { _canchas = data; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; });
    } catch (_) {
      setState(() { _error = 'No se pudo conectar con el servidor. Verifica que XAMPP esté activo.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _reservarCancha(Map<String, dynamic> cancha) {
    if (cancha['estado'] != 'Disponible') {
      _mostrarAlerta('No disponible',
          'La cancha ${cancha['nombre']} no está disponible. Por favor selecciona otra.');
      return;
    }

    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sbCtx, setStateSB) {
          final String dateText = selectedDate == null
              ? 'Seleccionar Fecha'
              : '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}';

          final String timeText = selectedTime == null
              ? 'Seleccionar Hora'
              : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';

          return AlertDialog(
            backgroundColor: AppTheme.cardColor,
            title: const Text('Confirmar Reserva', style: TextStyle(color: AppTheme.primaryColor)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cancha: ${cancha['nombre']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Tipo: ${cancha['tipo']}', style: const TextStyle(color: Colors.white70)),
                Text('Precio: \$${cancha['precio']} / hora', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                
                // Botón Fecha
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  title: Text(dateText, style: TextStyle(color: selectedDate == null ? Colors.white54 : Colors.white)),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: sbCtx,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(minutes: 5)), // allow today
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppTheme.primaryColor,
                            onPrimary: Colors.black,
                            surface: AppTheme.cardColor,
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (pickedDate != null) {
                      setStateSB(() {
                        selectedDate = pickedDate;
                        // Si cambiaron la fecha y ya tenían hora seleccionada, re-validar
                        if (selectedTime != null) {
                          final now = DateTime.now();
                          final selectedDateTime = DateTime(
                            selectedDate!.year,
                            selectedDate!.month,
                            selectedDate!.day,
                            selectedTime!.hour,
                            selectedTime!.minute,
                          );
                          if (selectedDateTime.isBefore(now)) {
                            selectedTime = null; // resetear si es del pasado
                            ScaffoldMessenger.of(sbCtx).showSnackBar(
                              const SnackBar(content: Text('La fecha seleccionada invalida la hora anterior.')),
                            );
                          }
                        }
                      });
                    }
                  },
                ),
                const Divider(color: Colors.white12),

                // Botón Hora
                ListTile(
                  leading: const Icon(Icons.access_time, color: AppTheme.primaryColor),
                  title: Text(timeText, style: TextStyle(color: selectedTime == null ? Colors.white54 : Colors.white)),
                  onTap: () async {
                    final pickedTime = await showTimePicker(
                      context: sbCtx,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppTheme.primaryColor,
                            onPrimary: Colors.black,
                            surface: AppTheme.cardColor,
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (pickedTime != null) {
                      // Validar que no sea del pasado si seleccionaron hoy
                      final now = DateTime.now();
                      final date = selectedDate ?? DateTime.now();
                      final selectedDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                      if (selectedDateTime.isBefore(now)) {
                        if (sbCtx.mounted) {
                          ScaffoldMessenger.of(sbCtx).showSnackBar(
                            const SnackBar(content: Text('No se puede seleccionar una hora del pasado.')),
                          );
                        }
                      } else {
                        setStateSB(() {
                          selectedTime = pickedTime;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedDate == null || selectedTime == null) {
                    ScaffoldMessenger.of(sbCtx).showSnackBar(
                      const SnackBar(content: Text('Por favor selecciona fecha y hora.')),
                    );
                    return;
                  }
                  
                  // Re-validar antes de enviar
                  final now = DateTime.now();
                  final selectedDateTime = DateTime(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                    selectedTime!.hour,
                    selectedTime!.minute,
                  );
                  if (selectedDateTime.isBefore(now)) {
                    ScaffoldMessenger.of(sbCtx).showSnackBar(
                      const SnackBar(content: Text('La fecha/hora seleccionada ya ha pasado.')),
                    );
                    return;
                  }

                  // Calcular hora fin (+1 hora)
                  final endDateTime = selectedDateTime.add(const Duration(hours: 1));
                  final String startStr = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                  final String endStr = '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
                  final String horarioStr = '$startStr - $endStr';
                  
                  final String fechaStr = '${selectedDate!.year.toString().padLeft(4, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';

                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                  
                  await _confirmarReserva(cancha, horarioStr, fechaStr);
                },
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmarReserva(Map<String, dynamic> cancha, String horario, String fecha) async {
    _mostrarCargando('Registrando reserva...');
    try {
      await ReservaService.crearReserva(
        canchaId:   int.parse(cancha['id'].toString()),
        usuarioId:  int.parse(AuthService.currentUser!.id),
        horario:    horario,
        fecha:      fecha,
      );
      if (mounted) Navigator.pop(context); // cierra loading
      _mostrarAlerta('¡Reserva Confirmada!',
          'Se generó el comprobante para ${cancha['nombre']} el $fecha en el horario $horario.');
      await _cargarCanchas(); // recargar datos reales
    } on ApiException catch (e) {
      if (mounted) Navigator.pop(context);
      _mostrarAlerta('Error', e.message);
    } catch (_) {
      if (mounted) Navigator.pop(context);
      _mostrarAlerta('Error', 'No se pudo conectar con el servidor.');
    }
  }

  void _mostrarCargando(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        content: Row(children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Text(msg),
        ]),
      ),
    );
  }

  void _mostrarAlerta(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(titulo, style: const TextStyle(color: AppTheme.primaryColor)),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Aceptar', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'Disponible':    return AppTheme.primaryColor;
      case 'Mantenimiento': return Colors.orange;
      default:              return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off, size: 60, color: Colors.white30),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _cargarCanchas, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Canchas Disponibles', style: Theme.of(context).textTheme.titleLarge),
              IconButton(icon: const Icon(Icons.refresh, color: AppTheme.primaryColor), onPressed: _cargarCanchas),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _canchas.isEmpty
                ? const Center(child: Text('No hay canchas registradas.', style: TextStyle(color: Colors.white54)))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.2,
                    ),
                    itemCount: _canchas.length,
                    itemBuilder: (_, i) {
                      final c = _canchas[i];
                      final bool disponible = c['estado'] == 'Disponible';
                      final Color acent = _estadoColor(c['estado']);
                      return Container(
                        decoration: BoxDecoration(
                          color: acent.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: acent.withValues(alpha: 0.3)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_soccer, size: 40, color: disponible ? AppTheme.primaryColor : Colors.white38),
                            const SizedBox(height: 8),
                            Text(c['nombre'], style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            Text(c['tipo'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(c['estado'], style: TextStyle(color: acent, fontWeight: FontWeight.w600)),
                            if (c['estado'] == 'Ocupada' && c['reserva_fecha'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2, bottom: 2),
                                child: Text(
                                  'Reservado: ${c['reserva_fecha']}\n${c['reserva_horario']}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Text('\$${c['precio']}', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                            const Spacer(),
                             SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: disponible ? () => _reservarCancha(c) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: disponible ? AppTheme.primaryColor : Colors.grey[800],
                                  disabledBackgroundColor: Colors.grey[900],
                                  disabledForegroundColor: Colors.white24,
                                ),
                                child: const Text('Reservar'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
