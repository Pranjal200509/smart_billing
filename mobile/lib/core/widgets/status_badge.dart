import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color fg;
    Color bg;

    final s = status.toUpperCase();

    if (s == 'PAID' || s == 'ACTIVE' || s == 'VERIFIED' || s == 'RESOLVED' || s == 'COMPLETED' || s == 'SUCCESS') {
      fg = AppColors.success;
      bg = AppColors.successBg;
    } else if (s == 'PENDING' || s == 'SUBMITTED' || s == 'IN_PROGRESS' || s == 'IN PROGRESS') {
      fg = AppColors.warning;
      bg = AppColors.warningBg;
    } else if (s == 'OVERDUE' || s == 'FAULTY' || s == 'REJECTED' || s == 'SUSPENDED' || s == 'FAILED') {
      fg = AppColors.danger;
      bg = AppColors.dangerBg;
    } else {
      fg = AppColors.info;
      bg = AppColors.infoBg;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
