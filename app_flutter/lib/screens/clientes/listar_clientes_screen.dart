import 'package:flutter/material.dart';
import '../../models/cliente.dart';

class ListarClientesScreen extends StatelessWidget {
  const ListarClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Cliente> clientes = [
      Cliente(
        nombre: "Juan",
        apellido: "Pérez",
        ci: "123456",
        telefono: "77777777",
        correo: "juan@gmail.com",
        direccion: "Cochabamba",
      ),
      Cliente(
        nombre: "María",
        apellido: "Gómez",
        ci: "987654",
        telefono: "66666666",
        correo: "maria@gmail.com",
        direccion: "La Paz",
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de Clientes"),
      ),
      body: ListView.builder(
        itemCount: clientes.length,
        itemBuilder: (context, index) {
          final cliente = clientes[index];

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(
                "${cliente.nombre} ${cliente.apellido}",
              ),
              subtitle: Text(
                "CI: ${cliente.ci}\nTel: ${cliente.telefono}",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}