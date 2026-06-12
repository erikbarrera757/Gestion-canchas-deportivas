import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../data/reservas_data.dart';

class HistorialClienteScreen extends StatelessWidget {
  final Cliente cliente;

  const HistorialClienteScreen({
    super.key,
    required this.cliente,
  });

  @override
  Widget build(BuildContext context) {

    final reservasCliente = reservas.where(
      (reserva) => reserva.clienteCi == cliente.ci,
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial Cliente"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(
                  "${cliente.nombre} ${cliente.apellido}",
                ),
                subtitle: Text(
                  "CI: ${cliente.ci}",
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Historial de Reservas",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: reservasCliente.isEmpty
                  ? const Center(
                      child: Text(
                        "Este cliente no tiene reservas registradas",
                      ),
                    )
                  : ListView.builder(
                      itemCount: reservasCliente.length,
                      itemBuilder: (context, index) {

                        final reserva =
                            reservasCliente[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.sports_soccer,
                            ),
                            title: Text(
                              reserva.cancha,
                            ),
                            subtitle: Text(
                              "Fecha: ${reserva.fecha}\n"
                              "Hora: ${reserva.horaInicio} - ${reserva.horaFin}\n"
                              "Estado: ${reserva.estado}",
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}