import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../data/clientes_data.dart';
import 'editar_cliente_screen.dart';
import 'historial_cliente_screen.dart';

class ListarClientesScreen extends StatefulWidget {
  const ListarClientesScreen({super.key});

  @override
  State<ListarClientesScreen> createState() =>
      _ListarClientesScreenState();
}

class _ListarClientesScreenState
    extends State<ListarClientesScreen> {
  @override
  Widget build(BuildContext context) {
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
                    icon: const Icon(Icons.history),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HistorialClienteScreen(
                            cliente: cliente,
                          ),
                        ),
                      );
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditarClienteScreen(
                            cliente: cliente,
                          ),
                        ),
                      );

                      setState(() {});
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text(
                            "Eliminar Cliente",
                          ),
                          content: Text(
                            "¿Desea eliminar a ${cliente.nombre} ${cliente.apellido}?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Cancelar",
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  clientes.removeAt(index);
                                });

                                Navigator.pop(context);

                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "${cliente.nombre} eliminado correctamente",
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "Eliminar",
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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