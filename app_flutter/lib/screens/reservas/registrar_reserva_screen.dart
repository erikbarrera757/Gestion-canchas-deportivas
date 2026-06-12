import 'package:flutter/material.dart';
import '../../models/reserva.dart';
import '../../data/reservas_data.dart';

class RegistrarReservaScreen extends StatefulWidget {
  const RegistrarReservaScreen({super.key});

  @override
  State<RegistrarReservaScreen> createState() =>
      _RegistrarReservaScreenState();
}

class _RegistrarReservaScreenState
    extends State<RegistrarReservaScreen> {

  final clienteCiController = TextEditingController();
  final canchaController = TextEditingController();
  final fechaController = TextEditingController();
  final horaInicioController = TextEditingController();
  final horaFinController = TextEditingController();

  String estadoSeleccionado = "Pendiente";

  Widget campo(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void guardarReserva() {
    final reserva = Reserva(
      clienteCi: clienteCiController.text,
      cancha: canchaController.text,
      fecha: fechaController.text,
      horaInicio: horaInicioController.text,
      horaFin: horaFinController.text,
      estado: estadoSeleccionado,
    );

    reservas.add(reserva);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Reserva registrada correctamente",
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Reserva"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            campo(
              "CI Cliente",
              clienteCiController,
            ),

            campo(
              "Cancha",
              canchaController,
            ),

            campo(
              "Fecha",
              fechaController,
            ),

            campo(
              "Hora Inicio",
              horaInicioController,
            ),

            campo(
              "Hora Fin",
              horaFinController,
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: estadoSeleccionado,
              decoration: const InputDecoration(
                labelText: "Estado",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: "Pendiente",
                  child: Text("Pendiente"),
                ),
                DropdownMenuItem(
                  value: "Confirmada",
                  child: Text("Confirmada"),
                ),
                DropdownMenuItem(
                  value: "Cancelada",
                  child: Text("Cancelada"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  estadoSeleccionado = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: guardarReserva,
              child: const Text(
                "Guardar Reserva",
              ),
            ),
          ],
        ),
      ),
    );
  }
}