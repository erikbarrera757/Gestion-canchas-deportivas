import 'package:flutter/material.dart';
import '../../models/cancha_model.dart';
import '../../models/cliente_model.dart';
import '../../models/reserva_model.dart';
import '../../models/tarifa_model.dart';
import '../../services/api_service.dart';

class RegistrarAlquilerScreen extends StatefulWidget {
  const RegistrarAlquilerScreen({super.key});

  @override
  State<RegistrarAlquilerScreen> createState() => _RegistrarAlquilerScreenState();
}

class _RegistrarAlquilerScreenState extends State<RegistrarAlquilerScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Cliente> clientes = [];
  List<Cancha> canchas = [];
  List<Tarifa> tarifas = [];
  List<Reserva> reservasPendientes = [];

  bool usarReserva = true;
  Reserva? reserva;
  Cliente? cliente;
  Cancha? cancha;
  Tarifa? tarifa;
  int tiempoPactado = 60;
  final observacionController = TextEditingController();

  bool cargando = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    observacionController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final dataClientes = await ApiService.get('clientes/listar_clientes.php') as List;
      final dataCanchas = await ApiService.get('canchas/listar_canchas.php') as List;
      final dataTarifas = await ApiService.get('canchas/listar_tarifas.php') as List;
      final dataReservas = await ApiService.get('reservas/listar_reservas_pendientes.php') as List;
      setState(() {
        clientes = dataClientes.map((e) => Cliente.fromJson(e)).toList();
        canchas = dataCanchas.map((e) => Cancha.fromJson(e)).where((c) => c.estado != 'Ocupada').toList();
        tarifas = dataTarifas.map((e) => Tarifa.fromJson(e)).toList();
        reservasPendientes = dataReservas.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          map['productos'] = 'Sin productos';
          return Reserva.fromJson(map);
        }).toList();
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  double get costoBaseEstimado {
    if (tarifa == null) return 0;
    return (tarifa!.precioHora / 60) * tiempoPactado;
  }

  void _aplicarReserva(Reserva? r) {
    setState(() {
      reserva = r;
      if (r != null) {
        final clientesEncontrados = clientes.where((c) => c.idCliente == r.idCliente).toList();
        final canchasEncontradas = canchas.where((c) => c.idCancha == r.idCancha).toList();
        cliente = clientesEncontrados.isNotEmpty ? clientesEncontrados.first : null;
        cancha = canchasEncontradas.isNotEmpty ? canchasEncontradas.first : null;
        final candidatas = tarifas.where((t) => t.tipoCancha.toLowerCase() == r.tipoCancha.toLowerCase()).toList();
        if (candidatas.isNotEmpty) tarifa = candidatas.first;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => guardando = true);
    try {
      await ApiService.post('alquileres/registrar_alquiler.php', {
        'id_cliente': cliente!.idCliente,
        'id_cancha': cancha!.idCancha,
        'id_reserva': usarReserva ? reserva?.idReserva : null,
        'id_tarifa': tarifa!.idTarifa,
        'tiempo_pactado': tiempoPactado,
        'observacion': observacionController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alquiler iniciado correctamente')));
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
    if (cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Alquiler')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              value: usarReserva,
              title: const Text('Iniciar con reserva pendiente'),
              subtitle: const Text('Apaga esta opción para alquiler directo'),
              onChanged: (v) => setState(() {
                usarReserva = v;
                reserva = null;
                cliente = null;
                cancha = null;
              }),
            ),
            if (usarReserva)
              DropdownButtonFormField<Reserva>(
                value: reserva,
                decoration: const InputDecoration(labelText: 'Reserva pendiente', border: OutlineInputBorder()),
                items: reservasPendientes.map((r) => DropdownMenuItem(value: r, child: Text('#${r.idReserva} - ${r.cliente} - ${r.cancha} - ${r.fecha} ${r.hora}'))).toList(),
                onChanged: _aplicarReserva,
                validator: (v) => usarReserva && v == null ? 'Seleccione una reserva' : null,
              ),
            if (usarReserva) const SizedBox(height: 12),
            DropdownButtonFormField<Cliente>(
              value: cliente,
              decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder()),
              items: clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.nombreCompleto))).toList(),
              onChanged: usarReserva ? null : (v) => setState(() => cliente = v),
              validator: (v) => v == null ? 'Seleccione un cliente' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Cancha>(
              value: cancha,
              decoration: const InputDecoration(labelText: 'Cancha', border: OutlineInputBorder()),
              items: canchas.map((c) => DropdownMenuItem(value: c, child: Text('${c.nombre} - ${c.tipo} - ${c.estado}'))).toList(),
              onChanged: usarReserva ? null : (v) => setState(() => cancha = v),
              validator: (v) => v == null ? 'Seleccione una cancha' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Tarifa>(
              value: tarifa,
              decoration: const InputDecoration(labelText: 'Tarifa', border: OutlineInputBorder()),
              items: tarifas.map((t) => DropdownMenuItem(value: t, child: Text(t.descripcion))).toList(),
              onChanged: (v) => setState(() => tarifa = v),
              validator: (v) => v == null ? 'Seleccione una tarifa' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: tiempoPactado,
              decoration: const InputDecoration(labelText: 'Tiempo pactado', border: OutlineInputBorder()),
              items: const [30, 60, 90, 120, 180].map((m) => DropdownMenuItem(value: m, child: Text('$m minutos'))).toList(),
              onChanged: (v) => setState(() => tiempoPactado = v ?? 60),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: observacionController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Observación', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Costo base estimado'),
                subtitle: Text('No incluye recargo por tiempo extra'),
                trailing: Text('Bs. ${costoBaseEstimado.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: guardando ? null : _guardar,
              icon: guardando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow),
              label: const Text('Iniciar alquiler'),
            ),
          ],
        ),
      ),
    );
  }
}
