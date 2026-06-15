import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  const StatusBadge({super.key, required this.text});

  Color _color() {
    switch (text.toLowerCase()) {
      case 'disponible':
      case 'finalizado':
      case 'pagado':
        return Colors.green;
      case 'ocupada':
      case 'activo':
      case 'no presentada':
        return Colors.red;
      case 'pendiente':
      case 'confirmada':
        return Colors.orange;
      case 'en limpieza':
        return Colors.blueGrey;
      case 'cancelada':
        return Colors.grey;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
