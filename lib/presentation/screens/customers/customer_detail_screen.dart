import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kreatif_laundry_offline_app/core/constants/colors.dart';
import 'package:kreatif_laundry_offline_app/core/utils/currency_formatter.dart';
import 'package:kreatif_laundry_offline_app/core/utils/date_formatter.dart';
import 'package:kreatif_laundry_offline_app/data/models/customer.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/customer/customer_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/customer/customer_state.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/customers/customer_form_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pelanggan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<CustomerCubit>(),
                    child: CustomerFormScreen(customer: customer),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: BlocListener<CustomerCubit, CustomerState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess &&
              state.message.contains('dihapus')) {
            Navigator.pop(context);
          } else if (state is CustomerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer header card
              _buildHeaderCard(context),
              const SizedBox(height: 16),

              // Statistics card
              _buildStatisticsCard(),
              const SizedBox(height: 16),

              // Contact info card
              _buildContactCard(),
              const SizedBox(height: 16),

              // Notes card (if exists)
              if (customer.notes != null && customer.notes!.isNotEmpty)
                _buildNotesCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 36,
              backgroundColor: customer.isLoyalCustomer
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              child: customer.isLoyalCustomer
                  ? const Icon(Icons.star, color: AppColors.warning, size: 36)
                  : Text(
                      customer.name.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            // Name and badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (customer.isLoyalCustomer)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PELANGGAN LOYAL',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Total Order',
                    value: '${customer.totalOrders}',
                    color: AppColors.info,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.payments_outlined,
                    label: 'Total Belanja',
                    value: CurrencyFormatter.format(customer.totalSpent),
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Bergabung',
                    value: customer.createdAt != null
                        ? DateFormatter.formatDate(customer.createdAt!)
                        : '-',
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.update_outlined,
                    label: 'Order Terakhir',
                    value: customer.lastOrderDate != null
                        ? DateFormatter.formatDate(customer.lastOrderDate!)
                        : 'Belum ada',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Kontak',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              icon: Icons.phone_outlined,
              label: 'Nomor HP',
              value: customer.phone ?? '-',
            ),
            const Divider(height: 24),
            _buildContactItem(
              icon: Icons.location_on_outlined,
              label: 'Alamat',
              value: customer.address ?? '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catatan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              customer.notes!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus pelanggan "${customer.name}"?\n\nData pelanggan akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CustomerCubit>().deleteCustomer(customer.id!);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
