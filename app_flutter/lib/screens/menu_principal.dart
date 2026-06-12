import 'package:flutter/material.dart';
import 'clientes/registrar_cliente_screen.dart';
import 'clientes/listar_clientes_screen.dart';
import 'reservas/registrar_reserva_screen.dart';
import 'reservas/listar_reservas_screen.dart';

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Canchas Deportivas'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CLIENTES

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const RegistrarClienteScreen(),
                  ),
                );
              },
              child: const Text(
                'Registrar Cliente',
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ListarClientesScreen(),
                  ),
                );
              },
              child: const Text(
                'Listar Clientes',
              ),
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 15),

            // RESERVAS

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const RegistrarReservaScreen(),
                  ),
                );
              },
              child: const Text(
                'Registrar Reserva',
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ListarReservasScreen(),
                  ),
                );
              },
              child: const Text(
                'Listar Reservas',
              ),
            ),
          ],
        ),
      ),
    );
  }
}