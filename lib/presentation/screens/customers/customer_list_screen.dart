import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/core/utils/currency_formatter.dart';
import 'package:kreatif_laundry_offline_app/data/models/customer.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/customer/customer_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/customer/customer_state.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/customers/customer_form_screen.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/customers/customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<CustomerCubit>().loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<CustomerCubit>().loadCustomers();
      }
    });
  }

  void _performSearch(String query) {
    context.read<CustomerCubit>().searchCustomers(query);
  }

  void _navigateToForm({Customer? customer}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CustomerCubit>(),
          child: CustomerFormScreen(customer: customer),
        ),
      ),
    );
  }

  void _navigateToDetail(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CustomerCubit>(),
          child: CustomerDetailScreen(customer: customer),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: BlocConsumer<CustomerCubit, CustomerState>(
              listener: (context, state) {
                if (state is CustomerOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppThemeColors.success,
                    ),
                  );
                } else if (state is CustomerError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppThemeColors.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is CustomerLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppThemeColors.primary,
                    ),
                  );
                }

                final customers = context.read<CustomerCubit>().customers;

                if (customers.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<CustomerCubit>().loadCustomers(),
                  color: AppThemeColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return _buildCustomerCard(customer);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppThemeColors.headerGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  // Back button
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
                  // Title
                  Expanded(
                    child: Text(
                      'Pelanggan',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Search toggle
                  GestureDetector(
                    onTap: _toggleSearch,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Icon(
                        _isSearching ? Icons.close : Icons.search,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              // Search Field
              if (_isSearching) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau nomor HP...',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppThemeColors.textHint,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppThemeColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onChanged: _performSearch,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppThemeColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 40,
                color: AppThemeColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Belum ada pelanggan',
              style: AppTypography.titleMedium.copyWith(
                color: AppThemeColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tambahkan data pelanggan Anda',
              style: AppTypography.bodySmall.copyWith(
                color: AppThemeColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: () => _navigateToForm(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  gradient: AppThemeColors.primaryGradient,
                  borderRadius: AppRadius.mdRadius,
                  boxShadow: AppShadows.purple,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Tambah Pelanggan',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetail(customer),
          borderRadius: AppRadius.lgRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: customer.isLoyalCustomer
                        ? AppThemeColors.warning.withValues(alpha: 0.1)
                        : AppThemeColors.primarySurface,
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: customer.isLoyalCustomer
                      ? const Icon(
                          Icons.star,
                          color: AppThemeColors.warning,
                          size: 26,
                        )
                      : Center(
                          child: Text(
                            customer.name.substring(0, 1).toUpperCase(),
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppThemeColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              customer.name,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (customer.isLoyalCustomer) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppThemeColors.warning.withValues(alpha: 0.1),
                                borderRadius: AppRadius.smRadius,
                              ),
                              child: Text(
                                'LOYAL',
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppThemeColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          customer.phone!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppThemeColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          // Order count
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeColors.primarySurface,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: Text(
                              '${customer.totalOrders} order',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppThemeColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          // Total spent
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeColors.success.withValues(alpha: 0.1),
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: Text(
                              CurrencyFormatter.formatCompact(customer.totalSpent),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppThemeColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppThemeColors.background,
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: AppThemeColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppThemeColors.primaryGradient,
        borderRadius: AppRadius.fullRadius,
        boxShadow: AppShadows.purple,
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Tambah',
          style: AppTypography.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
