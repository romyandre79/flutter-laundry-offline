import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kreatif_laundry_offline_app/core/constants/colors.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool showIcon;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 12,
  });

  Color get _backgroundColor {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.process:
        return AppColors.statusProcess;
      case OrderStatus.ready:
        return AppColors.statusReady;
      case OrderStatus.done:
        return AppColors.statusDone;
    }
  }

  IconData get _icon {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending_actions;
      case OrderStatus.process:
        return Icons.autorenew;
      case OrderStatus.ready:
        return Icons.check_circle_outline;
      case OrderStatus.done:
        return Icons.done_all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _backgroundColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _icon,
              size: fontSize + 2,
              color: _backgroundColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status.displayName,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: _backgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
