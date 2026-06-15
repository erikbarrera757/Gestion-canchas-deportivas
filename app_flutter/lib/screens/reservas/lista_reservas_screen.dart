import 'package:flutter/material.dart';
import '../../models/reserva_model.dart';
import '../../services/api_service.dart';
import '../../widgets/status_badge.dart';

class ListaReservasScreen extends StatefulWidget {
  const ListaReservasScreen({super.key});

  @override
  State<ListaReservasScreen> createState() => _ListaReservasScreenState();
}

class _ListaReservasScreenState extends State<ListaReservasScreen> {
  late Future<List<Reserva>> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<List<Reserva>> _cargar() async {
    final data = await ApiService.get('reservas/listar_reservas.php') as List;
    return data.map((e) => Reserva.fromJson(e)).toList();
  }

  Future<void> _cancelar(int idReserva) async {
    try {
      await ApiService.post('reservas/cancelar_reserva.php', {'id_reserva': idReserva});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva cancelada')));
      setState(() => _future = _cargar());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _noShow(int idReserva) async {
    try {
      await ApiService.post('alquileres/marcar_no_show.php', {'id_reserva': idReserva});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva marcada como no presentada')));
      setState(() => _future = _cargar());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/registrar-reserva');
          setState(() => _future = _cargar());
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva reserva'),
      ),
      body: FutureBuilder<List<Reserva>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final reservas = snapshot.data ?? [];
          if (reservas.isEmpty) {
            return const Center(child: Text('No hay reservas registradas'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reservas.length,
            itemBuilder: (context, index) {
              final r = reservas[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('${r.cancha} - ${r.fecha} ${r.hora}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          StatusBadge(text: r.estado),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Cliente: ${r.cliente}'),
                      Text('Productos: ${r.productos}'),
                      Text('Total: Bs. ${r.total.toStringAsFixed(2)}'),
                      if (r.estado == 'Pendiente')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => _noShow(r.idReserva), child: const Text('No se presentó')),
                            TextButton(onPressed: () => _cancelar(r.idReserva), child: const Text('Cancelar')),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
