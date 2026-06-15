import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/reservas/lista_reservas_screen.dart';
import 'screens/reservas/registrar_reserva_screen.dart';
import 'screens/alquileres/panel_alquiler_screen.dart';
import 'screens/alquileres/registrar_alquiler_screen.dart';
import 'screens/alquileres/finalizar_alquiler_screen.dart';

void main() {
  runApp(const ReservaCanchasApp());
}

class ReservaCanchasApp extends StatelessWidget {
  const ReservaCanchasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reserva Canchas',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/reservas': (_) => const ListaReservasScreen(),
        '/registrar-reserva': (_) => const RegistrarReservaScreen(),
        '/panel-alquiler': (_) => const PanelAlquilerScreen(),
        '/registrar-alquiler': (_) => const RegistrarAlquilerScreen(),
        '/finalizar-alquiler': (_) => const FinalizarAlquilerScreen(),
      },
    );
  }
}
