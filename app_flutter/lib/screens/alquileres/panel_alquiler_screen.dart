import 'package:flutter/material.dart';
import '../../models/alquiler_model.dart';
import '../../models/cancha_model.dart';
import '../../services/api_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/status_badge.dart';

class PanelAlquilerScreen extends StatefulWidget {
  const PanelAlquilerScreen({super.key});

  @override
  State<PanelAlquilerScreen> createState() => _PanelAlquilerScreenState();
}

class _PanelAlquilerScreenState extends State<PanelAlquilerScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<Map<String, dynamic>> _cargar() async {
    final panel = await ApiService.get('alquileres/listar_panel.php') as Map<String, dynamic>;
    final alquileresData = await ApiService.get('alquileres/listar_alquileres_activos.php') as List;
    return {
      'panel': panel,
      'alquileres': alquileresData.map((e) => Alquiler.fromJson(e)).toList(),
    };
  }

  void _refrescar() => setState(() => _future = _cargar());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Alquileres')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/registrar-alquiler');
          _refrescar();
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Iniciar alquiler'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));

          final panel = snapshot.data!['panel'] as Map<String, dynamic>;
          final alquileres = snapshot.data!['alquileres'] as List<Alquiler>;
          final canchas = (panel['canchas'] as List).map((e) => Cancha.fromJson(e)).toList();

          return RefreshIndicator(
            onRefresh: () async => _refrescar(),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                DashboardCard(title: 'Alquileres activos', value: '${panel['alquileres_activos']}', icon: Icons.timer),
                DashboardCard(title: 'Ingresos del dia', value: 'Bs. ${(panel['ingresos_dia'] as num).toStringAsFixed(2)}', icon: Icons.payments),
                DashboardCard(title: 'Reservas pendientes', value: '${panel['reservas_pendientes']}', icon: Icons.event),
                DashboardCard(title: 'Con tiempo extra', value: '${panel['con_tiempo_extra']}', icon: Icons.warning_amber),
                const SizedBox(height: 16),
                const Text('Estado de canchas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...canchas.map((c) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.sports_soccer),
                        title: Text(c.nombre),
                        subtitle: Text('${c.tipo} - Bs. ${c.precio.toStringAsFixed(2)}'),
                        trailing: StatusBadge(text: c.estado),
                      ),
                    )),
                const SizedBox(height: 16),
                const Text('Alquileres activos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (alquileres.isEmpty) const Card(child: ListTile(title: Text('No hay alquileres activos'))),
                ...alquileres.map((a) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(a.cancha, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                StatusBadge(text: a.tieneExtra ? 'Tiempo extra' : a.estado),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Cliente: ${a.cliente}'),
                            Text('Inicio: ${a.horaInicio}'),
                            Text('Tiempo: ${a.minutosTranscurridos} / ${a.tiempoPactado} minutos'),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.tonalIcon(
                                onPressed: () async {
                                  await Navigator.pushNamed(context, '/finalizar-alquiler', arguments: a.idAlquiler);
                                  _refrescar();
                                },
                                icon: const Icon(Icons.stop_circle),
                                label: const Text('Finalizar'),
                              ),
                            )
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 90),
              ],
            ),
          );
        },
      ),
    );
  }
}
