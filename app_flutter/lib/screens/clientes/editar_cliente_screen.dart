import 'package:flutter/material.dart';
import '../../models/cliente.dart';

class EditarClienteScreen extends StatefulWidget {
  final Cliente cliente;

  const EditarClienteScreen({
    super.key,
    required this.cliente,
  });

  @override
  State<EditarClienteScreen> createState() =>
      _EditarClienteScreenState();
}

class _EditarClienteScreenState
    extends State<EditarClienteScreen> {

  late TextEditingController nombreController;
  late TextEditingController apellidoController;
  late TextEditingController ciController;
  late TextEditingController telefonoController;
  late TextEditingController correoController;
  late TextEditingController direccionController;

  @override
  void initState() {
    super.initState();

    nombreController =
        TextEditingController(text: widget.cliente.nombre);

    apellidoController =
        TextEditingController(text: widget.cliente.apellido);

    ciController =
        TextEditingController(text: widget.cliente.ci);

    telefonoController =
        TextEditingController(text: widget.cliente.telefono);

    correoController =
        TextEditingController(text: widget.cliente.correo);

    direccionController =
        TextEditingController(text: widget.cliente.direccion);
  }

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

  void guardarCambios() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Cliente actualizado correctamente"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Cliente"),
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
              onPressed: guardarCambios,
              child: const Text("Guardar Cambios"),
            ),
          ],
        ),
      ),
    );
  }
}