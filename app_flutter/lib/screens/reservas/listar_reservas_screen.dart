import 'package:flutter/material.dart';
import '../../data/reservas_data.dart';

class ListarReservasScreen extends StatefulWidget {
  const ListarReservasScreen({super.key});

  @override
  State<ListarReservasScreen> createState() =>
      _ListarReservasScreenState();
}

class _ListarReservasScreenState
    extends State<ListarReservasScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de Reservas"),
      ),
      body: reservas.isEmpty
          ? const Center(
              child: Text(
                "No existen reservas registradas",
              ),
            )
          : ListView.builder(
              itemCount: reservas.length,
              itemBuilder: (context, index) {
                final reserva = reservas[index];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      reserva.cancha,
                    ),
                    subtitle: Text(
                      "Cliente CI: ${reserva.clienteCi}\n"
                      "Fecha: ${reserva.fecha}\n"
                      "Hora: ${reserva.horaInicio} - ${reserva.horaFin}\n"
                      "Estado: ${reserva.estado}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete,
                      ),
                      onPressed: () {
                        setState(() {
                          reservas.removeAt(index);
                        });

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Reserva eliminada",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}