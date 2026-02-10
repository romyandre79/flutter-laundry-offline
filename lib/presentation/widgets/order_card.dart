import 'package:flutter/material.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/core/utils/currency_formatter.dart';
import 'package:kreatif_laundry_offline_app/core/utils/date_formatter.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Invoice & Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.invoiceNo,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppThemeColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Customer Info
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppThemeColors.primarySurface,
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 18,
                        color: AppThemeColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        order.customerPhone != null && order.customerPhone!.isNotEmpty
                            ? '${order.customerName} - ${order.customerPhone}'
                            : order.customerName,
                        style: AppTypography.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Divider
                Container(
                  height: 1,
                  color: AppThemeColors.divider,
                ),

                const SizedBox(height: AppSpacing.md),

                // Bottom: Total, Payment & Due Date
                Row(
                  children: [
                    // Total
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppThemeColors.textSecondary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(order.totalPrice),
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Payment Badge
                    _buildPaymentBadge(),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Due Date
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: order.isOverdue
                          ? AppThemeColors.error
                          : AppThemeColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Ambil: ${DateFormatter.formatDate(order.dueDate ?? order.orderDate)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: order.isOverdue
                              ? AppThemeColors.error
                              : AppThemeColors.textSecondary,
                        ),
                      ),
                    ),
                    if (order.isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppThemeColors.error.withValues(alpha: 0.1),
                          borderRadius: AppRadius.smRadius,
                        ),
                        child: Text(
                          'OVERDUE',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppThemeColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;
    IconData icon;

    switch (order.status) {
      case OrderStatus.pending:
        color = AppThemeColors.warning;
        label = 'Pending';
        icon = Icons.pending_actions;
        break;
      case OrderStatus.process:
        color = AppThemeColors.primary;
        label = 'Proses';
        icon = Icons.autorenew;
        break;
      case OrderStatus.ready:
        color = AppThemeColors.success;
        label = 'Siap';
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.done:
        color = AppThemeColors.completed;
        label = 'Selesai';
        icon = Icons.done_all;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.smRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge() {
    if (order.isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppThemeColors.success.withValues(alpha: 0.1),
          borderRadius: AppRadius.smRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 14,
              color: AppThemeColors.success,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'LUNAS',
              style: AppTypography.labelSmall.copyWith(
                color: AppThemeColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (order.hasDeposit) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppThemeColors.warning.withValues(alpha: 0.1),
          borderRadius: AppRadius.smRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DP: ${CurrencyFormatter.formatCompact(order.paid)}',
              style: AppTypography.labelSmall.copyWith(
                color: AppThemeColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Kurang: ${CurrencyFormatter.formatCompact(order.remainingPayment)}',
              style: AppTypography.labelSmall.copyWith(
                color: AppThemeColors.warning,
                fontSize: 9,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppThemeColors.error.withValues(alpha: 0.1),
          borderRadius: AppRadius.smRadius,
        ),
        child: Text(
          'BELUM BAYAR',
          style: AppTypography.labelSmall.copyWith(
            color: AppThemeColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}
