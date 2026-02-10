import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/core/utils/currency_formatter.dart';
import 'package:kreatif_laundry_offline_app/core/utils/date_formatter.dart';
import 'package:kreatif_laundry_offline_app/core/utils/thousand_separator_formatter.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';
import 'package:kreatif_laundry_offline_app/data/models/payment.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/auth/auth_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/auth/auth_state.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/order/order_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/order/order_state.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/printer/printer_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/printer/printer_state.dart';
import 'package:kreatif_laundry_offline_app/core/services/whatsapp_service.dart';
import 'package:kreatif_laundry_offline_app/core/services/pdf_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().loadOrderDetail(widget.orderId);
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppThemeColors.warning;
      case OrderStatus.process:
        return AppThemeColors.primary;
      case OrderStatus.ready:
        return AppThemeColors.success;
      case OrderStatus.done:
        return AppThemeColors.completed;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.process:
        return 'Proses';
      case OrderStatus.ready:
        return 'Siap Ambil';
      case OrderStatus.done:
        return 'Selesai';
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
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

  void _showStatusUpdateDialog(Order order) {
    final nextStatuses = order.getNextStatusOptions();
    if (nextStatuses.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomContext) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ubah Status',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...nextStatuses.map((status) {
              final color = _getStatusColor(status);
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(bottomContext);
                      context.read<OrderCubit>().updateStatus(order.id!, status);
                    },
                    borderRadius: AppRadius.mdRadius,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: Icon(
                              _getStatusIcon(status),
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getStatusLabel(status),
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  status.description,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppThemeColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: color,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _shareViaWhatsApp(Order order) async {
    if (order.customerPhone == null || order.customerPhone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor HP pelanggan tidak tersedia'),
          backgroundColor: AppThemeColors.error,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomContext) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kirim via WhatsApp',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildWhatsAppOption(
              icon: Icons.receipt_long,
              color: AppThemeColors.primary,
              title: 'Kirim Struk',
              subtitle: 'Kirim struk order lengkap',
              onTap: () async {
                Navigator.pop(bottomContext);
                try {
                  await WhatsAppService().shareOrderReceipt(order);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: AppThemeColors.error,
                      ),
                    );
                  }
                }
              },
            ),
            if (order.status == OrderStatus.ready)
              _buildWhatsAppOption(
                icon: Icons.notifications_active,
                color: AppThemeColors.success,
                title: 'Notifikasi Siap Ambil',
                subtitle: 'Beritahu pelanggan laundry sudah siap',
                onTap: () async {
                  Navigator.pop(bottomContext);
                  try {
                    await WhatsAppService().sendOrderNotification(order, 'ready');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: AppThemeColors.error,
                        ),
                      );
                    }
                  }
                },
              ),
            if (order.status == OrderStatus.process)
              _buildWhatsAppOption(
                icon: Icons.hourglass_empty,
                color: AppThemeColors.warning,
                title: 'Notifikasi Proses',
                subtitle: 'Beritahu pelanggan laundry sedang diproses',
                onTap: () async {
                  Navigator.pop(bottomContext);
                  try {
                    await WhatsAppService().sendOrderNotification(order, 'process');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: AppThemeColors.error,
                        ),
                      );
                    }
                  }
                },
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.mdRadius,
        boxShadow: AppShadows.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppThemeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppThemeColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _printReceipt(Order order) async {
    final printerCubit = PrinterCubit();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: printerCubit,
        child: BlocListener<PrinterCubit, PrinterState>(
          listener: (context, state) {
            if (state is PrinterPrintSuccess) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppThemeColors.success,
                ),
              );
            } else if (state is PrinterError) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppThemeColors.error,
                ),
              );
            }
          },
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgRadius,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: AppThemeColors.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Mencetak struk...',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Panggil print setelah dialog ditampilkan
    await Future.delayed(const Duration(milliseconds: 100));
    printerCubit.printReceipt(order);
  }

  void _printLabels(Order order) async {
    try {
      await PdfService.instance.printItemLabels(order);
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppThemeColors.error,
          ),
        );
      }
    }
  }

  void _showAddPaymentDialog(Order order) {
    final amountController = TextEditingController();
    PaymentMethod selectedMethod = PaymentMethod.cash;
    final remaining = order.remainingPayment;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lgRadius,
          ),
          title: Text(
            'Tambah Pembayaran',
            style: AppTypography.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppThemeColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppThemeColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Kurang: ${CurrencyFormatter.format(remaining)}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppThemeColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  labelStyle: AppTypography.bodyMedium,
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                  ),
                  suffixIcon: TextButton(
                    onPressed: () {
                      amountController.text = ThousandSeparatorFormatter.format(remaining);
                    },
                    child: Text(
                      'Lunas',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppThemeColors.primary,
                      ),
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandSeparatorFormatter(),
                ],
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<PaymentMethod>(
                value: selectedMethod,
                decoration: InputDecoration(
                  labelText: 'Metode',
                  labelStyle: AppTypography.bodyMedium,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                  ),
                ),
                items: PaymentMethod.values.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(
                      m.displayName,
                      style: AppTypography.bodyMedium,
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedMethod = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Batal',
                style: AppTypography.labelMedium.copyWith(
                  color: AppThemeColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = ThousandSeparatorFormatter.parseToInt(amountController.text);
                if (amount <= 0) return;

                Navigator.pop(dialogContext);

                final authState = this.context.read<AuthCubit>().state;
                final userId =
                    authState is AuthAuthenticated ? authState.user.id : null;

                this.context.read<OrderCubit>().addPayment(
                      orderId: order.id!,
                      amount: amount,
                      method: selectedMethod,
                      receivedBy: userId,
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.smRadius,
                ),
              ),
              child: Text(
                'Bayar',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderCubit, OrderState>(
      listenWhen: (previous, current) {
        // Hanya listen jika state berubah ke success atau error
        // dan bukan dari loading ke detail loaded
        return current is OrderOperationSuccess || current is OrderError;
      },
      listener: (context, state) {
        if (state is OrderOperationSuccess) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppThemeColors.success,
            ),
          );
          context.read<OrderCubit>().loadOrderDetail(widget.orderId);
        } else if (state is OrderError) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppThemeColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is OrderLoading) {
          return Scaffold(
            backgroundColor: AppThemeColors.background,
            body: Column(
              children: [
                _buildHeader(null),
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppThemeColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is! OrderDetailLoaded) {
          return Scaffold(
            backgroundColor: AppThemeColors.background,
            body: Column(
              children: [
                _buildHeader(null),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: AppThemeColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Order tidak ditemukan',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppThemeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final order = state.order;

        return Scaffold(
          backgroundColor: AppThemeColors.background,
          body: Column(
            children: [
              _buildHeader(order),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Status Card
                    _buildStatusCard(order),

                    const SizedBox(height: AppSpacing.md),

                    // Customer Info
                    _buildCustomerCard(order),

                    const SizedBox(height: AppSpacing.md),

                    // Images
                    _buildImagesCard(order),

                    if (order.images.isNotEmpty) const SizedBox(height: AppSpacing.md),

                    // Items
                    _buildItemsCard(order),

                    const SizedBox(height: AppSpacing.md),

                    // Payment
                    _buildPaymentCard(order),

                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildNotesCard(order),
                    ],

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Order? order) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppThemeColors.headerGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Order',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      order?.invoiceNo ?? 'Loading...',
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (order != null) ...[
                GestureDetector(
                  onTap: () => _shareViaWhatsApp(order),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () => _printLabels(order),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () => _printReceipt(order),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: const Icon(
                      Icons.print,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(Order order) {
    final statuses = OrderStatus.values;
    final currentIndex = statuses.indexOf(order.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.small,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Order',
              style: AppTypography.labelMedium.copyWith(
                color: AppThemeColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Status Stepper
            Row(
              children: List.generate(statuses.length * 2 - 1, (index) {
                // Connector line (odd indices)
                if (index.isOdd) {
                  final stepIndex = index ~/ 2;
                  final isCompleted = stepIndex < currentIndex;
                  return Expanded(
                    child: Container(
                      height: 3,
                      color: isCompleted
                          ? AppThemeColors.primary
                          : AppThemeColors.border,
                    ),
                  );
                }

                // Status circle (even indices)
                final stepIndex = index ~/ 2;
                final status = statuses[stepIndex];
                final isCompleted = stepIndex < currentIndex;
                final isCurrent = stepIndex == currentIndex;
                final isNext = stepIndex == currentIndex + 1;
                final color = _getStatusColor(status);

                return GestureDetector(
                  onTap: isNext && order.status != OrderStatus.done
                      ? () => _confirmStatusUpdate(order, status)
                      : null,
                  child: Column(
                    children: [
                      // Circle indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isCurrent ? 44 : 36,
                        height: isCurrent ? 44 : 36,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? color
                              : isNext
                                  ? color.withValues(alpha: 0.15)
                                  : AppThemeColors.border.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: isNext
                              ? Border.all(color: color, width: 2)
                              : null,
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check
                              : _getStatusIcon(status),
                          size: isCurrent ? 22 : 18,
                          color: isCompleted || isCurrent
                              ? Colors.white
                              : isNext
                                  ? color
                                  : AppThemeColors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Label
                      Text(
                        _getStatusLabel(status),
                        style: AppTypography.labelSmall.copyWith(
                          color: isCurrent
                              ? color
                              : isCompleted
                                  ? AppThemeColors.textPrimary
                                  : AppThemeColors.textSecondary,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            // Next action hint
            if (order.status != OrderStatus.done) ...[
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: () {
                  final nextStatuses = order.getNextStatusOptions();
                  if (nextStatuses.isNotEmpty) {
                    _confirmStatusUpdate(order, nextStatuses.first);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppThemeColors.primary.withValues(alpha: 0.1),
                        AppThemeColors.primaryLight.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                      color: AppThemeColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: AppThemeColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Tap untuk update ke ${_getNextStatusLabel(order.status)}',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppThemeColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.arrow_forward,
                        color: AppThemeColors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Overdue warning
            if (order.isOverdue) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppThemeColors.error.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppThemeColors.error, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'OVERDUE - Sudah lewat tanggal ambil',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppThemeColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getNextStatusLabel(OrderStatus currentStatus) {
    switch (currentStatus) {
      case OrderStatus.pending:
        return 'Proses';
      case OrderStatus.process:
        return 'Siap Ambil';
      case OrderStatus.ready:
        return 'Selesai';
      case OrderStatus.done:
        return '';
    }
  }

  void _confirmStatusUpdate(Order order, OrderStatus newStatus) {
    // Jika update ke Selesai tapi belum lunas, buka dialog pembayaran
    if (newStatus == OrderStatus.done && !order.isPaid) {
      _showAddPaymentDialog(order);
      return;
    }

    final color = _getStatusColor(newStatus);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgRadius,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(newStatus),
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Update Status',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ubah status order menjadi "${_getStatusLabel(newStatus)}"?',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppThemeColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: AppTypography.labelMedium.copyWith(
                color: AppThemeColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<OrderCubit>().updateStatus(order.id!, newStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.smRadius,
              ),
            ),
            child: Text(
              'Ya, Update',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Order order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.small,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pelanggan',
              style: AppTypography.labelMedium.copyWith(
                color: AppThemeColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppThemeColors.primarySurface,
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppThemeColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (order.customerPhone != null)
                        Text(
                          order.customerPhone!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppThemeColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 1,
              color: AppThemeColors.divider,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildInfoRow(
              Icons.calendar_today,
              'Order',
              DateFormatter.formatDateTime(order.orderDate),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildInfoRow(
              Icons.schedule,
              'Ambil',
              DateFormatter.formatDate(order.dueDate ?? order.orderDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppThemeColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(
            color: AppThemeColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCard(Order order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.small,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item',
              style: AppTypography.labelMedium.copyWith(
                color: AppThemeColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (order.items != null)
              ...order.items!.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppThemeColors.primarySurface,
                            borderRadius: AppRadius.smRadius,
                          ),
                          child: const Icon(
                            Icons.local_laundry_service,
                            color: AppThemeColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.serviceName,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${item.quantity} ${item.unit} x ${CurrencyFormatter.format(item.pricePerUnit)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppThemeColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.subtotal),
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
            Container(
              height: 1,
              color: AppThemeColors.divider,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(order.totalPrice),
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppThemeColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Order order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.small,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pembayaran',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppThemeColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!order.isPaid)
                  GestureDetector(
                    onTap: () => _showAddPaymentDialog(order),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppThemeColors.primarySurface,
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add,
                            size: 14,
                            color: AppThemeColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Tambah',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppThemeColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (order.payments != null && order.payments!.isNotEmpty)
              ...order.payments!.map((payment) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppThemeColors.success.withValues(alpha: 0.1),
                                borderRadius: AppRadius.smRadius,
                              ),
                              child: const Icon(
                                Icons.payment,
                                color: AppThemeColors.success,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    payment.paymentMethod.displayName,
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    DateFormatter.formatDateTime(payment.paymentDate),
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppThemeColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(payment.amount),
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppThemeColors.success,
                              ),
                            ),
                          ],
                        ),
                        // Tampilkan kembalian jika ada
                        if (payment.change > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 48, top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kembalian',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppThemeColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(payment.change),
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppThemeColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ))
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'Belum ada pembayaran',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppThemeColors.textSecondary,
                  ),
                ),
              ),
            Container(
              height: 1,
              color: AppThemeColors.divider,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dibayar',
                  style: AppTypography.bodyMedium,
                ),
                Text(
                  CurrencyFormatter.format(order.paid),
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppThemeColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Jika lunas dan ada kelebihan bayar, tampilkan sebagai "Kembalian"
            // Jika belum lunas, tampilkan sebagai "Sisa"
            if (order.isPaid && order.paidAmount > order.totalAmount) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kembalian',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(order.paidAmount - order.totalAmount),
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppThemeColors.success,
                    ),
                  ),
                ],
              ),
            ] else if (!order.isPaid) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kurang',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(order.remainingPayment),
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppThemeColors.error,
                    ),
                  ),
                ],
              ),
            ],
            if (order.isPaid) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppThemeColors.success.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: AppThemeColors.success),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'LUNAS',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppThemeColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(Order order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.small,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppThemeColors.primarySurface,
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(
                    Icons.note_alt_outlined,
                    color: AppThemeColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Catatan',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppThemeColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              order.notes!,
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildImagesCard(Order order) {
    if (order.images.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.small,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Foto Laundry',
              style: AppTypography.labelMedium.copyWith(
                color: AppThemeColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: InteractiveViewer(
                            child: Image.file(
                              File(order.images[index]),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: AppRadius.mdRadius,
                      child: Image.file(
                        File(order.images[index]),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
