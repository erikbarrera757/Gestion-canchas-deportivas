import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../data/clientes_data.dart';
class RegistrarClienteScreen extends StatefulWidget {
  const RegistrarClienteScreen({super.key});

  @override
  State<RegistrarClienteScreen> createState() =>
      _RegistrarClienteScreenState();
}

class _RegistrarClienteScreenState
    extends State<RegistrarClienteScreen> {

  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final ciController = TextEditingController();
  final telefonoController = TextEditingController();
  final correoController = TextEditingController();
  final direccionController = TextEditingController();

  void guardarCliente() {
  final nuevoCliente = Cliente(
    nombre: nombreController.text,
    apellido: apellidoController.text,
    ci: ciController.text,
    telefono: telefonoController.text,
    correo: correoController.text,
    direccion: direccionController.text,
  );

  clientes.add(nuevoCliente);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Cliente registrado correctamente"),
    ),
  );

  Navigator.pop(context);
}

  Widget campo(String label, TextEditingController controller) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Cliente"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            campo("Nombre", nombreController),
            campo("Apellido", apellidoController),
            campo("CI", ciController),
            campo("Teléfono", telefonoController),
            campo("Correo", correoController),
            campo("Dirección", direccionController),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: guardarCliente,
              child: const Text("Guardar Cliente"),
            ),
          ],
        ),
      ),
    );
  }
}