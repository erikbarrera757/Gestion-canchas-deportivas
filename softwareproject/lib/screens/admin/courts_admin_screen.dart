import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/cancha_service.dart';
import '../../services/api_service.dart';

class CourtsAdminScreen extends StatefulWidget {
  const CourtsAdminScreen({super.key});

  @override
  State<CourtsAdminScreen> createState() => _CourtsAdminScreenState();
}

class _CourtsAdminScreenState extends State<CourtsAdminScreen> {
  List<Map<String, dynamic>> _canchas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await CanchaService.getCanchas();
      if (mounted) setState(() { _canchas = data; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _error = 'No se pudo conectar. Verifica que XAMPP esté activo.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  // Caso 23: Registrar Cancha
  void _registrarCancha() {
    final nombreCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    String tipo = 'Fútbol 5';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Registrar Nueva Cancha', style: TextStyle(color: AppTheme.primaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre de la Cancha *'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: tipo,
              decoration: const InputDecoration(labelText: 'Tipo de Deporte'),
              items: ['Fútbol 5', 'Fútbol 7', 'Tenis', 'Básquet', 'Vóley']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => tipo = val!,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: precioCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio por hora *', prefixText: '\$'),
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
              final nombre = nombreCtrl.text.trim();
              final precio = double.tryParse(precioCtrl.text.trim()) ?? 0;
              if (nombre.isEmpty) {
                _mostrarAlerta('Campos incompletos', 'El nombre es obligatorio.');
                return;
              }
              if (precio <= 0) {
                _mostrarAlerta('Precio inválido', 'Ingresa un precio mayor a 0.');
                return;
              }
              if (_canchas.any((c) =>
                  c['nombre'].toString().toLowerCase() == nombre.toLowerCase())) {
                _mostrarAlerta('Duplicado', 'Ya existe una cancha con ese nombre.');
                return;
              }
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              _mostrarCargando('Registrando cancha...');
              try {
                await CanchaService.crearCancha(nombre: nombre, tipo: tipo, precio: precio);
                if (mounted) {
                  Navigator.pop(context);
                  await _cargar();
                  _mostrarSnack('Cancha "$nombre" registrada con éxito ✓');
                }
              } on ApiException catch (e) {
                if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', e.message); }
              } catch (_) {
                if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', 'No se pudo conectar con el servidor.'); }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Caso 24: Modificar Cancha
  void _modificarCancha(Map<String, dynamic> cancha) {
    final nombreCtrl = TextEditingController(text: cancha['nombre'].toString());
    final precioCtrl = TextEditingController(text: cancha['precio'].toString());
    String tipo = cancha['tipo'].toString();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Modificar Cancha', style: TextStyle(color: AppTheme.primaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: tipo,
              decoration: const InputDecoration(labelText: 'Tipo de Deporte'),
              items: ['Fútbol 5', 'Fútbol 7', 'Tenis', 'Básquet', 'Vóley']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => tipo = val!,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: precioCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio por hora', prefixText: '\$'),
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
              final nombre = nombreCtrl.text.trim();
              final precio = double.tryParse(precioCtrl.text.trim()) ?? 0;
              if (nombre.isEmpty) { _mostrarAlerta('Datos erróneos', 'El nombre no puede estar vacío.'); return; }
              if (_canchas.any((c) =>
                  c['id'].toString() != cancha['id'].toString() &&
                  c['nombre'].toString().toLowerCase() == nombre.toLowerCase())) {
                _mostrarAlerta('Duplicado', 'Ya existe otra cancha con ese nombre.');
                return;
              }
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              _mostrarCargando('Actualizando cancha...');
              try {
                await CanchaService.actualizarCancha(
                  int.parse(cancha['id'].toString()),
                  {'nombre': nombre, 'tipo': tipo, 'precio': precio},
                );
                if (mounted) {
                  Navigator.pop(context);
                  await _cargar();
                  _mostrarSnack('Cancha actualizada correctamente ✓');
                }
              } on ApiException catch (e) {
                if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', e.message); }
              } catch (_) {
                if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', 'No se pudo conectar con el servidor.'); }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  // Caso 23b: Cambiar Estado
  void _cambiarEstado(Map<String, dynamic> cancha) {
    String nuevoEstado = cancha['estado'].toString();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Actualizar Disponibilidad', style: TextStyle(color: AppTheme.primaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cancha: ${cancha['nombre']}'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: nuevoEstado,
              items: ['Disponible', 'Ocupada', 'Mantenimiento']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => nuevoEstado = val!,
              decoration: const InputDecoration(labelText: 'Nuevo Estado'),
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
              if (cancha['estado'] == 'Mantenimiento' && nuevoEstado == 'Ocupada') {
                _mostrarAlerta('Cambio incorrecto', 'No se puede poner en Ocupada una cancha que está en Mantenimiento.');
                return;
              }
              if (cancha['estado'] == 'Ocupada' && nuevoEstado == 'Mantenimiento') {
                _mostrarAlerta('Cambio incorrecto', 'No se puede poner en Mantenimiento una cancha que está Ocupada en juego.');
                return;
              }
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              _mostrarCargando('Actualizando estado...');
              try {
                await CanchaService.actualizarCancha(int.parse(cancha['id'].toString()), {'estado': nuevoEstado});
                if (mounted) { Navigator.pop(context); await _cargar(); _mostrarSnack('Estado actualizado a "$nuevoEstado"'); }
              } on ApiException catch (e) {
                if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', e.message); }
              } catch (_) {
                if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', 'No se pudo conectar con el servidor.'); }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Caso 25: Eliminar Cancha
  void _eliminarCancha(Map<String, dynamic> cancha) {
    if (cancha['estado'] == 'Ocupada' || cancha['estado'] == 'Mantenimiento') {
      _mostrarAlerta(
        'No se puede eliminar',
        'La cancha "${cancha['nombre']}" está ${cancha['estado']}. Resuelve los conflictos antes de eliminarla.',
      );
      return;
    }
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Eliminar Cancha', style: TextStyle(color: AppTheme.errorColor)),
        content: Text('¿Eliminar "${cancha['nombre']}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              _mostrarCargando('Eliminando cancha...');
              try {
                await CanchaService.eliminarCancha(int.parse(cancha['id'].toString()));
                if (mounted) { Navigator.pop(context); await _cargar(); _mostrarSnack('Cancha eliminada.'); }
              } on ApiException catch (e) {
                if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', e.message); }
              } catch (_) {
                if (mounted) { Navigator.pop(context); _mostrarAlerta('Error', 'No se pudo conectar con el servidor.'); }
              }
            },
            child: const Text('Sí, Eliminar'),
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
      case 'Disponible':    return AppTheme.primaryColor;
      case 'Mantenimiento': return Colors.orange;
      default:              return Colors.redAccent;
    }
  }

  IconData _estadoIcon(String estado) {
    switch (estado) {
      case 'Disponible':    return Icons.check_circle;
      case 'Mantenimiento': return Icons.build;
      default:              return Icons.sports_soccer;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off, size: 60, color: Colors.white30),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: _cargar, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
      ]));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gestión de Canchas', style: Theme.of(context).textTheme.titleLarge),
              Row(children: [
                IconButton(icon: const Icon(Icons.refresh, color: AppTheme.primaryColor), onPressed: _cargar),
                const SizedBox(width: 8),
                ElevatedButton.icon(onPressed: _registrarCancha, icon: const Icon(Icons.add), label: const Text('Registrar Cancha')),
              ]),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _canchas.isEmpty
                ? const Center(child: Text('No hay canchas registradas.', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    itemCount: _canchas.length,
                    itemBuilder: (context, index) {
                      final c = _canchas[index];
                      final estado = c['estado']?.toString() ?? 'Disponible';
                      final Color color = _estadoColor(estado);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: Icon(_estadoIcon(estado), color: color),
                          ),
                          title: Text(c['nombre']?.toString() ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Tipo: ${c['tipo']}'),
                            Text('Precio: \$${c['precio']} / hora'),
                            Text('Estado: $estado', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                            if (estado == 'Ocupada' && c['reserva_fecha'] != null)
                              Text(
                                'Reserva: ${c['reserva_fecha']} (${c['reserva_horario']})',
                                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                          ]),
                          isThreeLine: true,
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.swap_horiz, color: AppTheme.secondaryColor), tooltip: 'Actualizar Disponibilidad', onPressed: () => _cambiarEstado(c)),
                            IconButton(icon: const Icon(Icons.edit, color: Colors.amber), tooltip: 'Modificar Cancha', onPressed: () => _modificarCancha(c)),
                            IconButton(icon: const Icon(Icons.delete, color: AppTheme.errorColor), tooltip: 'Eliminar Cancha', onPressed: () => _eliminarCancha(c)),
                          ]),
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
