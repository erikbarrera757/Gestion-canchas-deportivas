import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/mantenimiento_service.dart';
import '../../services/cancha_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class MaintenanceDashboard extends StatefulWidget {
  const MaintenanceDashboard({super.key});

  @override
  State<MaintenanceDashboard> createState() => _MaintenanceDashboardState();
}

class _MaintenanceDashboardState extends State<MaintenanceDashboard> {
  List<Map<String, dynamic>> _tickets = [];
  List<Map<String, dynamic>> _canchas = [];
  List<Map<String, dynamic>> _personal = [];
  bool _loading = true;
  String? _error;

  bool get _esAdmin => AuthService.currentUser?.role == UserRole.administrador;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        MantenimientoService.getTickets(),
        CanchaService.getCanchas(),
        MantenimientoService.getPersonalMantenimiento(),
      ]);
      if (mounted) {
        setState(() {
          _tickets  = results[0];
          _canchas  = results[1];
          _personal = results[2];
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _error = 'No se pudo conectar. Verifica que XAMPP esté activo.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  // Caso 28 y 6: Registrar Solicitud de Mantenimiento
  void _registrarIncidencia() {
    final disponibleCanchas = _canchas.where((c) => c['estado'] == 'Disponible').toList();
    if (disponibleCanchas.isEmpty) {
      _mostrarAlerta('Sin canchas disponibles', 'No hay canchas disponibles (libres) para poner en mantenimiento en este momento.');
      return;
    }
    String canchaId = disponibleCanchas.first['id'].toString();
    String tipo = 'Daño';
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Reportar Incidencia', style: TextStyle(color: AppTheme.primaryColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: canchaId,
                items: disponibleCanchas
                    .map((c) => DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text(c['nombre'].toString()),
                        ))
                    .toList(),
                onChanged: (val) => canchaId = val!,
                decoration: const InputDecoration(labelText: 'Cancha'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: tipo,
                items: ['Daño', 'Limpieza', 'Falla Eléctrica']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => tipo = val!,
                decoration: const InputDecoration(labelText: 'Tipo de Problema'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción detallada',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              _mostrarCargando('Registrando incidencia...');
              try {
                await MantenimientoService.registrarTicket(
                  canchaId:    int.parse(canchaId),
                  reportadoPor: int.parse(AuthService.currentUser!.id),
                  tipo:         tipo,
                  descripcion:  descCtrl.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  await _cargar();
                  _mostrarSnack('Ticket registrado. Administrador notificado.');
                }
              } on ApiException catch (e) {
                if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', e.message); }
              } catch (_) {
                if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', 'No se pudo conectar con el servidor.'); }
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  // Caso 27 y 7: Asignar Tareas de Mantenimiento
  void _asignarTecnico(Map<String, dynamic> ticket) {
    if (_personal.isEmpty) {
      _mostrarAlerta('Sin personal',
          'No hay personal de mantenimiento registrado en el sistema.');
      return;
    }
    String tecnicoId = _personal.first['id'].toString();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Asignar Personal — ${ticket['id']}',
            style: const TextStyle(color: AppTheme.primaryColor)),
        content: DropdownButtonFormField<String>(
          initialValue: tecnicoId,
          items: _personal
              .map((p) => DropdownMenuItem(
                    value: p['id'].toString(),
                    child: Text(p['nombre'].toString()),
                  ))
              .toList(),
          onChanged: (val) => tecnicoId = val!,
          decoration: const InputDecoration(labelText: 'Personal Disponible'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              _mostrarCargando('Asignando personal...');
              try {
                await MantenimientoService.actualizarTicket(
                  int.parse(ticket['id'].toString()),
                  {'tecnico_id': int.parse(tecnicoId), 'estado': 'En Proceso'},
                );
                if (mounted) {
                  Navigator.pop(context);
                  await _cargar();
                  final tecnico = _personal.firstWhere(
                    (p) => p['id'].toString() == tecnicoId,
                    orElse: () => {'nombre': tecnicoId},
                  );
                  _mostrarSnack('${tecnico['nombre']} asignado al ticket ${ticket['id']}');
                }
              } on ApiException catch (e) {
                if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', e.message); }
              } catch (_) {
                if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', 'No se pudo conectar con el servidor.'); }
              }
            },
            child: const Text('Asignar'),
          ),
        ],
      ),
    );
  }

  // Caso 8: Registrar Avance de Reparación
  void _registrarAvance(Map<String, dynamic> ticket) {
    double avance = double.parse(ticket['avance']?.toString() ?? '0');
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sbCtx, setStateSB) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: Text('Avance — ${ticket['id']}',
              style: const TextStyle(color: AppTheme.primaryColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Porcentaje de avance: ${avance.toInt()}%',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Slider(
                value: avance,
                min: 0,
                max: 100,
                divisions: 10,
                label: '${avance.toInt()}%',
                activeColor: AppTheme.primaryColor,
                onChanged: (val) => setStateSB(() => avance = val),
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
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                _mostrarCargando('Actualizando avance...');
                try {
                  await MantenimientoService.actualizarTicket(
                    int.parse(ticket['id'].toString()),
                    {'avance': avance.toInt()},
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    await _cargar();
                  }
                } on ApiException catch (e) {
                  if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', e.message); }
                } catch (_) {
                  if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', 'No se pudo conectar.'); }
                }
              },
              child: const Text('Guardar Avance'),
            ),
          ],
        ),
      ),
    );
  }

  // Caso 26 y 9: Notificar Finalización de Actividad
  void _finalizarTarea(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Finalizar Tarea', style: TextStyle(color: AppTheme.primaryColor)),
        content: Text(
          '¿La tarea ${ticket['id']} de ${ticket['cancha_nombre']} ha sido completada?\n\n'
          'Si la falla persiste, la cancha permanecerá En Mantenimiento.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              _mostrarCargando('Actualizando...');
              try {
                await MantenimientoService.actualizarTicket(
                  int.parse(ticket['id'].toString()),
                  {'estado': 'En Proceso'},
                );
                if (mounted) {
                  Navigator.pop(context);
                  await _cargar();
                  _mostrarSnack('La cancha sigue En Mantenimiento.');
                }
              } catch (_) {
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Falla Persiste', style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              _mostrarCargando('Cerrando ticket...');
              try {
                await MantenimientoService.actualizarTicket(
                  int.parse(ticket['id'].toString()),
                  {'estado': 'Completada', 'avance': 100},
                );
                if (mounted) {
                  Navigator.pop(context);
                  await _cargar();
                  _mostrarSnack('✓ Tarea cerrada. Cancha liberada.');
                }
              } on ApiException catch (e) {
                if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', e.message); }
              } catch (_) {
                if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', 'No se pudo conectar.'); }
              }
            },
            child: const Text('Completar y Liberar Cancha'),
          ),
        ],
      ),
    );
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
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.primaryColor),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'Completada': return AppTheme.primaryColor;
      case 'En Proceso': return AppTheme.secondaryColor;
      default:           return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off, size: 60, color: Colors.white30),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: _cargar, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
      ]));
    }

    final pendientes   = _tickets.where((t) => t['estado'] == 'Pendiente').length;
    final enProceso    = _tickets.where((t) => t['estado'] == 'En Proceso').length;
    final completadas  = _tickets.where((t) => t['estado'] == 'Completada').length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Panel de Mantenimiento', style: Theme.of(context).textTheme.titleLarge),
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
                  onPressed: _cargar,
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _registrarIncidencia,
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Reportar Incidencia'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 16),

          // Métricas rápidas
          Row(children: [
            _buildMetricCard('Pendientes',  pendientes,  Colors.orange),
            const SizedBox(width: 12),
            _buildMetricCard('En Proceso',  enProceso,   AppTheme.secondaryColor),
            const SizedBox(width: 12),
            _buildMetricCard('Completadas', completadas, AppTheme.primaryColor),
          ]),
          const SizedBox(height: 20),

          // Lista de tickets
          Expanded(
            child: _tickets.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.check_circle_outline, size: 60,
                          color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      const Text('No hay incidencias registradas.',
                          style: TextStyle(color: Colors.white54)),
                    ]),
                  )
                : ListView.builder(
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _tickets[index];
                      final estado = ticket['estado']?.toString() ?? 'Pendiente';
                      final bool isCompletada = estado == 'Completada';
                      final Color borderColor = _estadoColor(estado);
                      final int avance = int.parse(ticket['avance']?.toString() ?? '0');
                      final String cancha = ticket['cancha_nombre']?.toString() ?? '';
                      final String tecnico = ticket['tecnico_nombre']?.toString() ?? '';
                      final String ticketId = 'TK-${ticket['id'].toString().padLeft(3, '0')}';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: borderColor, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Encabezado
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text('$ticketId — $cancha',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                  ),
                                  Chip(
                                    label: Text(estado,
                                        style: TextStyle(color: borderColor, fontWeight: FontWeight.bold)),
                                    backgroundColor: borderColor.withValues(alpha: 0.1),
                                    side: BorderSide(color: borderColor.withValues(alpha: 0.3)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Problema: ${ticket['tipo']}'),
                              const SizedBox(height: 4),
                              if ((ticket['descripcion']?.toString() ?? '').isNotEmpty)
                                Text('Descripción: ${ticket['descripcion']}',
                                    style: const TextStyle(color: Colors.white60, fontSize: 13)),
                              const SizedBox(height: 4),
                              Row(children: [
                                Icon(
                                  tecnico.isEmpty ? Icons.person_off : Icons.engineering,
                                  size: 16,
                                  color: tecnico.isEmpty ? Colors.red : Colors.white54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tecnico.isEmpty ? 'Sin asignar' : 'Asignado: $tecnico',
                                  style: TextStyle(
                                    color: tecnico.isEmpty ? Colors.redAccent : Colors.white70,
                                  ),
                                ),
                              ]),

                              if (!isCompletada) ...[
                                const SizedBox(height: 16),
                                Row(children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: avance / 100,
                                      color: borderColor,
                                      backgroundColor: Colors.white12,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('$avance%',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ]),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Solo el Administrador puede asignar personal
                                    if (tecnico.isEmpty && _esAdmin)
                                      ElevatedButton.icon(
                                        onPressed: () => _asignarTecnico(ticket),
                                        icon: const Icon(Icons.person_add, size: 18),
                                        label: const Text('Asignar Personal'),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.secondaryColor),
                                      ),
                                    // Si no hay técnico y el user es técnico, mostrar mensaje
                                    if (tecnico.isEmpty && !_esAdmin)
                                      const Text(
                                        'Esperando asignación del administrador...',
                                        style: TextStyle(color: Colors.white38, fontSize: 13),
                                      ),
                                    // Técnico (y admin) pueden actualizar avance y finalizar
                                    if (tecnico.isNotEmpty) ...[
                                      OutlinedButton.icon(
                                        onPressed: () => _registrarAvance(ticket),
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Actualizar Avance'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white70,
                                          side: const BorderSide(color: Colors.white30),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _finalizarTarea(ticket),
                                        icon: const Icon(Icons.check_circle, size: 18),
                                        label: const Text('Finalizar'),
                                      ),
                                    ],
                                  ],
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Icon(Icons.check_circle,
                                      color: AppTheme.primaryColor, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Tarea completada. Cancha liberada.',
                                      style: TextStyle(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.8))),
                                ]),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text('$count',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
    );
  }
}
