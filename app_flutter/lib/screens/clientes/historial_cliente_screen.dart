import 'package:flutter/material.dart';
import '../../models/cliente.dart';

class HistorialClienteScreen extends StatelessWidget {
  final Cliente cliente;

  const HistorialClienteScreen({
    super.key,
    required this.cliente,
  });

  @override
  Widget build(BuildContext context) {
    final reservas = [
      {
        "fecha": "01/06/2026",
        "cancha": "Cancha Fútbol",
        "estado": "Completada"
      },
      {
        "fecha": "05/06/2026",
        "cancha": "Cancha Pádel",
        "estado": "Completada"
      },
      {
        "fecha": "08/06/2026",
        "cancha": "Cancha Fútbol",
        "estado": "Cancelada"
      },
    ];

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
              child: ListView.builder(
                itemCount: reservas.length,
                itemBuilder: (context, index) {
                  final reserva = reservas[index];

                  return Card(
                    child: ListTile(
                      title: Text(
                        reserva["cancha"]!,
                      ),
                      subtitle: Text(
                        "Fecha: ${reserva["fecha"]}\nEstado: ${reserva["estado"]}",
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