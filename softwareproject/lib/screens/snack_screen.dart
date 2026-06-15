import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/snack_service.dart';
import '../services/api_service.dart';

class SnackScreen extends StatefulWidget {
  const SnackScreen({super.key});

  @override
  State<SnackScreen> createState() => _SnackScreenState();
}

class _SnackScreenState extends State<SnackScreen> {
  List<Map<String, dynamic>> _productos = [];
  final List<Map<String, dynamic>> _carrito = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await SnackService.getProductos();
      setState(() { _productos = data; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; });
    } catch (_) {
      setState(() { _error = 'No se pudo conectar. Verifica XAMPP.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    final stock = int.parse(producto['stock'].toString());
    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${producto['nombre']} no tiene stock'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    final enCarrito = _carrito.where((p) => p['id'].toString() == producto['id'].toString()).length;
    if (enCarrito >= stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay más stock disponible'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    setState(() { _carrito.add(producto); });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${producto['nombre']} agregado al carrito ✓'),
          backgroundColor: AppTheme.primaryColor, duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _procesarVenta() async {
    if (_carrito.isEmpty) return;

    // Agrupar items por producto
    final Map<String, int> grupos = {};
    for (final item in _carrito) {
      final key = item['id'].toString();
      grupos[key] = (grupos[key] ?? 0) + 1;
    }
    final items = grupos.entries.map((e) => {'producto_id': int.parse(e.key), 'cantidad': e.value}).toList();

    _mostrarCargando('Procesando venta...');
    try {
      await SnackService.registrarVenta(
        items:      items,
        usuarioId:  int.parse(AuthService.currentUser!.id),
      );
      if (mounted) Navigator.pop(context);
      setState(() { _carrito.clear(); });
      await _cargarProductos();
      _mostrarAlerta('Venta Exitosa', 'Comprobante generado. Pago procesado correctamente.');
    } on ApiException catch (e) {
      if (mounted) Navigator.pop(context);
      _mostrarAlerta('Error en la venta', e.message);
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

  double get _totalCarrito => _carrito.fold(0, (s, p) => s + double.parse(p['precio'].toString()));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off, size: 60, color: Colors.white30),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: _cargarProductos, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
      ]));
    }

    return Row(
      children: [
        // Catálogo de productos
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Punto de Venta — Snack', style: Theme.of(context).textTheme.titleLarge),
                    IconButton(icon: const Icon(Icons.refresh, color: AppTheme.primaryColor), onPressed: _cargarProductos),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
                    ),
                    itemCount: _productos.length,
                    itemBuilder: (_, i) {
                      final p = _productos[i];
                      final int stock = int.parse(p['stock'].toString());
                      final bool hayStock = stock > 0;
                      return InkWell(
                        onTap: () => _agregarAlCarrito(p),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: AppTheme.glassDecoration,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_drink, size: 36, color: hayStock ? Colors.white : Colors.white24),
                              const SizedBox(height: 8),
                              Text(p['nombre'], textAlign: TextAlign.center, style: TextStyle(color: hayStock ? Colors.white : Colors.white38)),
                              Text('\$${p['precio']}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                              Text('Stock: ${p['stock']}', style: TextStyle(color: hayStock ? Colors.white54 : Colors.red, fontSize: 11)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Carrito
        Container(
          width: 300,
          color: AppTheme.cardColor,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Carrito', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white12),
              Expanded(
                child: _carrito.isEmpty
                    ? const Center(child: Text('Selecciona productos', style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: _carrito.length,
                        itemBuilder: (_, i) {
                          final item = _carrito[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item['nombre'], style: const TextStyle(fontSize: 13)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('\$${item['precio']}'),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => setState(() => _carrito.removeAt(i)),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white38),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(color: Colors.white12),
              Text('Total: \$${_totalCarrito.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _carrito.isEmpty ? null : _procesarVenta,
                  child: Text('Cobrar (${_carrito.length} items)'),
                ),
              ),
              if (_carrito.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => setState(() => _carrito.clear()),
                    child: const Text('Cancelar compra', style: TextStyle(color: Colors.white38)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
