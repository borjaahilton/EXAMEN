import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pendiente':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Pendiente';
        icon = Icons.access_time_rounded;
        break;
      case 'en preparacion':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        label = 'En preparación';
        icon = Icons.soup_kitchen_rounded;
        break;
      case 'listo':
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF6B21A8);
        label = 'Listo para entrega';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'entregado':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Entregado';
        icon = Icons.task_alt_rounded;
        break;
      default:
        bg = AppColors.border;
        fg = AppColors.textMuted;
        label = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
