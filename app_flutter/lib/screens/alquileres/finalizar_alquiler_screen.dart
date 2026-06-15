import 'package:flutter/material.dart';
import '../../models/alquiler_model.dart';
import '../../services/api_service.dart';
import '../../widgets/status_badge.dart';

class FinalizarAlquilerScreen extends StatefulWidget {
  const FinalizarAlquilerScreen({super.key});

  @override
  State<FinalizarAlquilerScreen> createState() => _FinalizarAlquilerScreenState();
}

class _FinalizarAlquilerScreenState extends State<FinalizarAlquilerScreen> {
  List<Alquiler> alquileres = [];
  Alquiler? alquiler;
  String metodoPago = 'Efectivo';
  String estadoCancha = 'Disponible';
  bool cargando = true;
  bool finalizando = false;
  bool argumentoLeido = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!argumentoLeido) {
      argumentoLeido = true;
      _cargarDatos();
    }
  }

  Future<void> _cargarDatos() async {
    try {
      final data = await ApiService.get('alquileres/listar_alquileres_activos.php') as List;
      final lista = data.map((e) => Alquiler.fromJson(e)).toList();
      final arg = ModalRoute.of(context)?.settings.arguments;
      Alquiler? seleccionado;
      if (arg is int) {
        final encontrados = lista.where((a) => a.idAlquiler == arg).toList();
        seleccionado = encontrados.isNotEmpty ? encontrados.first : null;
      }
      setState(() {
        alquileres = lista;
        alquiler = seleccionado ?? (lista.isNotEmpty ? lista.first : null);
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _finalizar() async {
    if (alquiler == null) return;
    setState(() => finalizando = true);
    try {
      final data = await ApiService.post('alquileres/finalizar_alquiler.php', {
        'id_alquiler': alquiler!.idAlquiler,
        'metodo_pago': metodoPago,
        'estado_cancha': estadoCancha,
      }) as Map<String, dynamic>;
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Comprobante generado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Duración: ${data['duracion_minutos']} minutos'),
              Text('Minutos extra: ${data['minutos_extra']}'),
              Text('Costo base: Bs. ${data['costo_base']}'),
              Text('Recargo: Bs. ${data['recargo']}'),
              const Divider(),
              Text('Total: Bs. ${data['total_pagar']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Aceptar'))],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => finalizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar Alquiler')),
      body: alquileres.isEmpty
          ? const Center(child: Text('No hay alquileres activos'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<Alquiler>(
                  value: alquiler,
                  decoration: const InputDecoration(labelText: 'Alquiler activo', border: OutlineInputBorder()),
                  items: alquileres.map((a) => DropdownMenuItem(value: a, child: Text('#${a.idAlquiler} - ${a.cancha} - ${a.cliente}'))).toList(),
                  onChanged: (v) => setState(() => alquiler = v),
                ),
                const SizedBox(height: 12),
                if (alquiler != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [Expanded(child: Text(alquiler!.cancha, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))), StatusBadge(text: alquiler!.tieneExtra ? 'Tiempo extra' : 'Activo')]),
                          const SizedBox(height: 8),
                          Text('Cliente: ${alquiler!.cliente}'),
                          Text('Tarifa: ${alquiler!.tarifa}'),
                          Text('Inicio: ${alquiler!.horaInicio}'),
                          Text('Tiempo pactado: ${alquiler!.tiempoPactado} minutos'),
                          Text('Tiempo transcurrido: ${alquiler!.minutosTranscurridos} minutos'),
                          Text('Recargo por hora extra: Bs. ${alquiler!.recargoExtra.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: metodoPago,
                  decoration: const InputDecoration(labelText: 'Método de pago', border: OutlineInputBorder()),
                  items: const ['Efectivo', 'QR', 'Depósito', 'Tarjeta'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => metodoPago = v ?? 'Efectivo'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: estadoCancha,
                  decoration: const InputDecoration(labelText: 'Estado final de la cancha', border: OutlineInputBorder()),
                  items: const ['Disponible', 'En Limpieza'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => estadoCancha = v ?? 'Disponible'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: finalizando ? null : _finalizar,
                  icon: finalizando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.receipt_long),
                  label: const Text('Finalizar y generar pago'),
                ),
              ],
            ),
    );
  }
}
