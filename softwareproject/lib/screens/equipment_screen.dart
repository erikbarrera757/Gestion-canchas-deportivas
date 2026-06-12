import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/implemento_service.dart';
import '../services/api_service.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  List<Map<String, dynamic>> _implementos = [];
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
      final data = await ImplementoService.getImplementos();
      setState(() { _implementos = data; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; });
    } catch (_) {
      setState(() { _error = 'No se pudo conectar. Verifica XAMPP.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _procesarTransaccion(Map<String, dynamic> impl, String tipo) async {
    final int stock = int.parse(impl['stock'].toString());
    if (stock < 1) {
      _mostrarAlerta('Sin Stock', 'El implemento ${impl['nombre']} no está disponible.');
      return;
    }
    final double precio = tipo == 'Alquiler'
        ? double.parse(impl['precio_alquiler'].toString())
        : double.parse(impl['precio_venta'].toString());

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Confirmar $tipo', style: const TextStyle(color: AppTheme.primaryColor)),
        content: Text('¿Confirmas el $tipo de ${impl['nombre']} por \$${precio.toStringAsFixed(2)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm != true) return;

    _mostrarCargando('Procesando $tipo...');
    try {
      await ImplementoService.procesarTransaccion(
        implementoId: int.parse(impl['id'].toString()),
        usuarioId:    int.parse(AuthService.currentUser!.id),
        tipo:         tipo,
      );
      if (mounted) Navigator.pop(context);
      await _cargar();
      _mostrarAlerta('Comprobante Generado', '$tipo de ${impl['nombre']} procesado. Total: \$${precio.toStringAsFixed(2)}');
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
        actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Aceptar'))],
      ),
    );
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alquiler y Venta de Implementos', style: Theme.of(context).textTheme.titleLarge),
              IconButton(icon: const Icon(Icons.refresh, color: AppTheme.primaryColor), onPressed: _cargar),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _implementos.length,
              itemBuilder: (_, i) {
                final impl = _implementos[i];
                final int stock = int.parse(impl['stock'].toString());
                final bool disponible = stock > 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.sports, size: 48, color: disponible ? Colors.white : Colors.white24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(impl['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              Text('Stock disponible: $stock',
                                  style: TextStyle(color: disponible ? Colors.white70 : Colors.redAccent)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _procesarTransaccion(impl, 'Alquiler'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
                          child: Text('Alquilar \$${impl['precio_alquiler']}'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _procesarTransaccion(impl, 'Venta'),
                          child: Text('Comprar \$${impl['precio_venta']}'),
                        ),
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
}
