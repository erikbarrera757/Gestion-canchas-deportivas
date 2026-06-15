import 'package:flutter/material.dart';
import '../../models/cancha_model.dart';
import '../../models/cliente_model.dart';
import '../../models/producto_model.dart';
import '../../services/api_service.dart';

class RegistrarReservaScreen extends StatefulWidget {
  const RegistrarReservaScreen({super.key});

  @override
  State<RegistrarReservaScreen> createState() => _RegistrarReservaScreenState();
}

class _RegistrarReservaScreenState extends State<RegistrarReservaScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Cliente> clientes = [];
  List<Cancha> canchas = [];
  List<Producto> productos = [];
  final Set<int> productosSeleccionados = {};

  Cliente? cliente;
  Cancha? cancha;
  DateTime? fecha;
  TimeOfDay? hora;
  bool cargando = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final dataClientes = await ApiService.get('clientes/listar_clientes.php') as List;
      final dataCanchas = await ApiService.get('canchas/listar_canchas.php') as List;
      final dataProductos = await ApiService.get('productos/listar_productos.php') as List;
      setState(() {
        clientes = dataClientes.map((e) => Cliente.fromJson(e)).toList();
        canchas = dataCanchas.map((e) => Cancha.fromJson(e)).toList();
        productos = dataProductos.map((e) => Producto.fromJson(e)).toList();
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  double get totalEstimado {
    final precioCancha = cancha?.precio ?? 0;
    final precioProductos = productos.where((p) => productosSeleccionados.contains(p.idProducto)).fold<double>(0, (sum, p) => sum + p.precio);
    return precioCancha + precioProductos;
  }

  String _fechaSql(DateTime f) {
    return '${f.year.toString().padLeft(4, '0')}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
  }

  String _horaSql(TimeOfDay h) {
    return '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || fecha == null || hora == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete todos los campos')));
      return;
    }
    setState(() => guardando = true);
    try {
      await ApiService.post('reservas/registrar_reserva.php', {
        'id_cliente': cliente!.idCliente,
        'id_cancha': cancha!.idCancha,
        'fecha': _fechaSql(fecha!),
        'hora': _horaSql(hora!),
        'productos': productosSeleccionados.toList(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva registrada correctamente')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Reserva')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<Cliente>(
              value: cliente,
              decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder()),
              items: clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.nombreCompleto))).toList(),
              onChanged: (v) => setState(() => cliente = v),
              validator: (v) => v == null ? 'Seleccione un cliente' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Cancha>(
              value: cancha,
              decoration: const InputDecoration(labelText: 'Cancha', border: OutlineInputBorder()),
              items: canchas.map((c) => DropdownMenuItem(value: c, child: Text('${c.nombre} - ${c.tipo} - Bs. ${c.precio}'))).toList(),
              onChanged: (v) => setState(() => cancha = v),
              validator: (v) => v == null ? 'Seleccione una cancha' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final selected = await showDatePicker(context: context, firstDate: now, lastDate: DateTime(now.year + 2), initialDate: now);
                      if (selected != null) setState(() => fecha = selected);
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(fecha == null ? 'Fecha' : _fechaSql(fecha!)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (selected != null) setState(() => hora = selected);
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(hora == null ? 'Hora' : _horaSql(hora!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Productos adicionales', style: TextStyle(fontWeight: FontWeight.bold)),
            ...productos.map((p) => CheckboxListTile(
                  value: productosSeleccionados.contains(p.idProducto),
                  title: Text('${p.nombre} - Bs. ${p.precio.toStringAsFixed(2)}'),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        productosSeleccionados.add(p.idProducto);
                      } else {
                        productosSeleccionados.remove(p.idProducto);
                      }
                    });
                  },
                )),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Total estimado'),
                trailing: Text('Bs. ${totalEstimado.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: guardando ? null : _guardar,
              icon: guardando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: const Text('Guardar Reserva'),
            ),
          ],
        ),
      ),
    );
  }
}
