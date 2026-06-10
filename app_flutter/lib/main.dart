import 'package:flutter/material.dart';
import 'screens/clientes/registrar_cliente_screen.dart';

void main() {
  runApp(const GestionCanchasApp());
}

class GestionCanchasApp extends StatelessWidget {
  const GestionCanchasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión de Canchas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RegistrarClienteScreen(),
    );
  }
}