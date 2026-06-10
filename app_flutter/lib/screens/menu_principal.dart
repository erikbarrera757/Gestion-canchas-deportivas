import 'package:flutter/material.dart';
import 'clientes/registrar_cliente_screen.dart';
import 'clientes/listar_clientes_screen.dart';

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clientes'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegistrarClienteScreen(),
                  ),
                );
              },
              child: const Text('Registrar Cliente'),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ListarClientesScreen(),
                  ),
                );
              },
              child: const Text('Listar Clientes'),
            ),
          ],
        ),
      ),
    );
  }
}