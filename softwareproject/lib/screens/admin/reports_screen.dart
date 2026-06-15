import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/mantenimiento_service.dart';
import '../../services/api_service.dart';
import '../../utils/export_helper.dart' as helper;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReport = 'reservas';
  bool _isGenerating = false;
  List<Map<String, dynamic>> _datos = [];
  Map<String, dynamic>? _resumen;
  String? _error;


  static const Map<String, String> _reportLabels = {
    'reservas':       'Reservas',
    'ingresos_snack': 'Ingresos de Snack',
    'stock_tienda':   'Stock de Tienda',
    'mantenimiento':  'Incidencias de Mantenimiento',
  };

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  Future<void> _cargarResumen() async {
    try {
      final data = await MantenimientoService.getResumen();
      setState(() { _resumen = data; });
    } catch (_) {
      // Ignorar error
    }
  }

  Future<void> _generarReporte() async {
    setState(() { _isGenerating = true; _error = null; _datos = []; });
    try {
      final data = await MantenimientoService.getReporte(_selectedReport);
      setState(() { _datos = data; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; });
    } catch (_) {
      setState(() { _error = 'No se pudo conectar. Verifica que XAMPP esté activo.'; });
    } finally {
      setState(() { _isGenerating = false; });
    }
  }

  Map<String, dynamic> _obtenerDatosReporte() {
    String title = '';
    List<String> headers = [];
    List<List<String>> rows = [];

    switch (_selectedReport) {
      case 'reservas':
        title = 'Reporte de Reservas';
        headers = const ['Fecha', 'Cliente', 'Cancha', 'Horario', 'Estado', 'Precio'];
        rows = _datos.map((r) => [
          r['fecha']?.toString() ?? '',
          r['cliente']?.toString() ?? '',
          r['cancha']?.toString() ?? '',
          r['horario']?.toString() ?? '',
          r['estado']?.toString() ?? '',
          '\$${r['precio'] ?? 0}',
        ]).toList();
        break;

      case 'ingresos_snack':
        title = 'Reporte de Ingresos — Snack';
        headers = const ['Fecha', 'Producto', 'Cantidad', 'Total', 'Vendedor'];
        rows = _datos.map((r) => [
          r['fecha']?.toString() ?? '',
          r['producto']?.toString() ?? '',
          r['cantidad']?.toString() ?? '1',
          '\$${r['total'] ?? 0}',
          r['vendedor']?.toString() ?? '',
        ]).toList();
        break;

      case 'stock_tienda':
        title = 'Reporte de Stock — Tienda Deportiva';
        headers = const ['Nombre', 'Categoría', 'Stock', 'Alquiler', 'Venta'];
        rows = _datos.map((r) => [
          r['nombre']?.toString() ?? '',
          r['categoria']?.toString() ?? '',
          r['stock']?.toString() ?? '0',
          '\$${r['precio_alquiler'] ?? 0}',
          '\$${r['precio_venta'] ?? 0}',
        ]).toList();
        break;

      case 'mantenimiento':
        title = 'Reporte de Incidencias de Mantenimiento';
        headers = const ['Ticket', 'Cancha', 'Tipo', 'Estado', 'Avance', 'Técnico'];
        rows = _datos.asMap().entries.map((e) {
          final r = e.value;
          final ticketId = 'TK-${(e.key + 1).toString().padLeft(3, '0')}';
          return [
            ticketId,
            r['cancha']?.toString() ?? '',
            r['tipo']?.toString() ?? '',
            r['estado']?.toString() ?? '',
            '${r['avance'] ?? 0}%',
            r['tecnico']?.toString() ?? 'Sin asignar',
          ];
        }).toList();
        break;
    }

    return {
      'title': title,
      'headers': headers,
      'rows': rows,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generación de Reportes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // KPIs de resumen
          if (_resumen != null) _buildKpiRow(),
          if (_resumen != null) const SizedBox(height: 20),

          // Panel de selección
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassDecoration,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedReport,
                    decoration: const InputDecoration(labelText: 'Tipo de Reporte'),
                    items: _reportLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) {
                      setState(() { _selectedReport = val!; _datos = []; _error = null; });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generarReporte,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.bar_chart),
                      label: Text(_isGenerating ? 'Generando...' : 'Generar'),
                    ),
                    if (_datos.isNotEmpty) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          final reportData = _obtenerDatosReporte();
                          helper.exportToCsv(
                            reportData['title'] as String,
                            reportData['headers'] as List<String>,
                            reportData['rows'] as List<List<String>>,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('CSV descargado con éxito')),
                          );
                        },
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Exportar CSV'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final reportData = _obtenerDatosReporte();
                          helper.exportToPdf(
                            reportData['title'] as String,
                            reportData['headers'] as List<String>,
                            reportData['rows'] as List<List<String>>,
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar PDF'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Vista previa del reporte
          Expanded(
            child: _error != null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.wifi_off, size: 60, color: Colors.white30),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.white54)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(onPressed: _generarReporte, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
                  ]))
                : _datos.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.insert_chart, size: 80, color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 12),
                        Text('Selecciona un reporte y haz clic en Generar.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16)),
                      ]))
                    : _buildReportPreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    final r = _resumen!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _kpiCard('Reservas Total', r['total_reservas']?.toString() ?? '0', Icons.event_available, AppTheme.primaryColor),
        const SizedBox(width: 12),
        _kpiCard('Ingresos Reservas', '\$${(r['ingresos_reservas'] ?? 0).toStringAsFixed(2)}', Icons.attach_money, Colors.greenAccent),
        const SizedBox(width: 12),
        _kpiCard('Ingresos Snack', '\$${(r['ingresos_snack'] ?? 0).toStringAsFixed(2)}', Icons.local_drink, AppTheme.secondaryColor),
        const SizedBox(width: 12),
        _kpiCard('Tickets Pendientes', r['tickets_pendientes']?.toString() ?? '0', Icons.warning_amber, Colors.orange),
        const SizedBox(width: 12),
        _kpiCard('Tickets Cerrados', r['tickets_completados']?.toString() ?? '0', Icons.check_circle, Colors.greenAccent),
        const SizedBox(width: 12),
        _kpiCard('Canchas Disponibles', r['canchas_disponibles']?.toString() ?? '0', Icons.sports_soccer, AppTheme.primaryColor),
      ]),
    );
  }

  Widget _kpiCard(String label, String valor, IconData icon, Color color) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _buildReportPreview() {
    switch (_selectedReport) {
      case 'reservas':
        return _buildTable(
          title: 'Reporte de Reservas',
          columns: const ['Fecha', 'Cliente', 'Cancha', 'Horario', 'Estado', 'Precio'],
          rows: _datos.map((r) => [
            r['fecha']?.toString() ?? '',
            r['cliente']?.toString() ?? '',
            r['cancha']?.toString() ?? '',
            r['horario']?.toString() ?? '',
            r['estado']?.toString() ?? '',
            '\$${r['precio'] ?? 0}',
          ]).toList(),
        );

      case 'ingresos_snack':
        return _buildTable(
          title: 'Reporte de Ingresos — Snack',
          columns: const ['Fecha', 'Producto', 'Cantidad', 'Total', 'Vendedor'],
          rows: _datos.map((r) => [
            r['fecha']?.toString() ?? '',
            r['producto']?.toString() ?? '',
            r['cantidad']?.toString() ?? '1',
            '\$${r['total'] ?? 0}',
            r['vendedor']?.toString() ?? '',
          ]).toList(),
        );

      case 'stock_tienda':
        return _buildTable(
          title: 'Reporte de Stock — Tienda Deportiva',
          columns: const ['Nombre', 'Categoría', 'Stock', 'Alquiler', 'Venta'],
          rows: _datos.map((r) => [
            r['nombre']?.toString() ?? '',
            r['categoria']?.toString() ?? '',
            r['stock']?.toString() ?? '0',
            '\$${r['precio_alquiler'] ?? 0}',
            '\$${r['precio_venta'] ?? 0}',
          ]).toList(),
        );

      case 'mantenimiento':
        return _buildTable(
          title: 'Reporte de Incidencias de Mantenimiento',
          columns: const ['Ticket', 'Cancha', 'Tipo', 'Estado', 'Avance', 'Técnico'],
          rows: _datos.asMap().entries.map((e) {
            final r = e.value;
            final ticketId = 'TK-${(e.key + 1).toString().padLeft(3, '0')}';
            return [
              ticketId,
              r['cancha']?.toString() ?? '',
              r['tipo']?.toString() ?? '',
              r['estado']?.toString() ?? '',
              '${r['avance'] ?? 0}%',
              r['tecnico']?.toString() ?? 'Sin asignar',
            ];
          }).toList(),
        );

      default:
        return const Center(child: Text('Reporte no reconocido.'));
    }
  }

  Widget _buildTable({
    required String title,
    required List<String> columns,
    required List<List<String>> rows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(width: 12),
          Chip(
            label: Text('${rows.length} registros',
                style: const TextStyle(fontSize: 12)),
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: rows.isEmpty
              ? const Center(
                  child: Text('No hay registros para este reporte.',
                      style: TextStyle(color: Colors.white54)))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          AppTheme.primaryColor.withValues(alpha: 0.15)),
                      border: TableBorder.all(
                          color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                      columns: columns
                          .map((c) => DataColumn(
                                label: Text(c,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor)),
                              ))
                          .toList(),
                      rows: rows
                          .map((row) => DataRow(
                                cells: row
                                    .map((cell) => DataCell(Text(cell,
                                        style: const TextStyle(fontSize: 13))))
                                    .toList(),
                              ))
                          .toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
