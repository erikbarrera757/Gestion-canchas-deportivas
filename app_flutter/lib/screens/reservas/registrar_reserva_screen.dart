import 'package:flutter/material.dart';
import '../../models/reserva.dart';
import '../../data/reservas_data.dart';
import '../../data/clientes_data.dart';

class RegistrarReservaScreen extends StatefulWidget {
  const RegistrarReservaScreen({super.key});

  @override
  State<RegistrarReservaScreen> createState() =>
      _RegistrarReservaScreenState();
}

class _RegistrarReservaScreenState
    extends State<RegistrarReservaScreen> {

  String? clienteSeleccionado;
  String? canchaSeleccionada;

  final fechaController = TextEditingController();
  final horaInicioController = TextEditingController();
  final horaFinController = TextEditingController();

  String estadoSeleccionado = "Pendiente";

  Future<void> seleccionarFecha() async {
    DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (fecha != null) {
      setState(() {
        fechaController.text =
            "${fecha.day}/${fecha.month}/${fecha.year}";
      });
    }
  }

  Future<void> seleccionarHoraInicio() async {
    TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (hora != null) {
      setState(() {
        horaInicioController.text =
            hora.format(context);
      });
    }
  }

  Future<void> seleccionarHoraFin() async {
    TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (hora != null) {
      setState(() {
        horaFinController.text =
            hora.format(context);
      });
    }
  }

  void guardarReserva() {
    if (clienteSeleccionado == null ||
        canchaSeleccionada == null ||
        fechaController.text.isEmpty ||
        horaInicioController.text.isEmpty ||
        horaFinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Complete todos los campos",
          ),
        ),
      );
      return;
    }

    final reserva = Reserva(
      clienteCi: clienteSeleccionado!,
      cancha: canchaSeleccionada!,
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
        title: const Text(
          "Registrar Reserva",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Cliente",
                border: OutlineInputBorder(),
              ),
              value: clienteSeleccionado,
              items: clientes.map((cliente) {
                return DropdownMenuItem(
                  value: cliente.ci,
                  child: Text(
                    "${cliente.nombre} ${cliente.apellido}",
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  clienteSeleccionado = value;
                });
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Cancha",
                border: OutlineInputBorder(),
              ),
              value: canchaSeleccionada,
              items: const [
                DropdownMenuItem(
                  value: "Fútbol 5",
                  child: Text("Fútbol 5"),
                ),
                DropdownMenuItem(
                  value: "Fútbol 7",
                  child: Text("Fútbol 7"),
                ),
                DropdownMenuItem(
                  value: "Fútbol 11",
                  child: Text("Fútbol 11"),
                ),
                DropdownMenuItem(
                  value: "Pádel",
                  child: Text("Pádel"),
                ),
                DropdownMenuItem(
                  value: "Tenis",
                  child: Text("Tenis"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  canchaSeleccionada = value;
                });
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: fechaController,
              readOnly: true,
              onTap: seleccionarFecha,
              decoration: InputDecoration(
                labelText: "Fecha",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.calendar_month,
                  ),
                  onPressed: seleccionarFecha,
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: horaInicioController,
              readOnly: true,
              onTap: seleccionarHoraInicio,
              decoration: InputDecoration(
                labelText: "Hora Inicio",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.access_time,
                  ),
                  onPressed: seleccionarHoraInicio,
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: horaFinController,
              readOnly: true,
              onTap: seleccionarHoraFin,
              decoration: InputDecoration(
                labelText: "Hora Fin",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.access_time,
                  ),
                  onPressed: seleccionarHoraFin,
                ),
              ),
            ),

            const SizedBox(height: 15),

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