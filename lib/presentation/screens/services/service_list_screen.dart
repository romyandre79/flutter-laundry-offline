import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/core/utils/currency_formatter.dart';
import 'package:kreatif_laundry_offline_app/data/models/service.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/service/service_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/service/service_state.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/services/service_form_screen.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ServiceCubit>().loadServices();
  }

  void _showDeleteDialog(Service service) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgRadius,
        ),
        title: Text(
          'Hapus Layanan',
          style: AppTypography.titleLarge,
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${service.name}"?',
          style: AppTypography.bodyMedium,
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
              context.read<ServiceCubit>().deleteService(service.id!);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.smRadius,
              ),
            ),
            child: Text(
              'Hapus',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToForm({Service? service}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ServiceCubit>(),
          child: ServiceFormScreen(service: service),
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
            child: BlocConsumer<ServiceCubit, ServiceState>(
              listener: (context, state) {
                if (state is ServiceOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppThemeColors.success,
                    ),
                  );
                } else if (state is ServiceError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppThemeColors.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ServiceLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppThemeColors.primary,
                    ),
                  );
                }

                final services = context.read<ServiceCubit>().services;

                if (services.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<ServiceCubit>().loadServices(),
                  color: AppThemeColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return _buildServiceCard(service);
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
          child: Row(
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
                  'Paket Layanan',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Add button
              GestureDetector(
                onTap: () => _navigateToForm(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
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
                Icons.local_laundry_service_outlined,
                size: 40,
                color: AppThemeColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Belum ada paket layanan',
              style: AppTypography.titleMedium.copyWith(
                color: AppThemeColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tambahkan paket layanan laundry Anda',
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
                      'Tambah Layanan',
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

  Widget _buildServiceCard(Service service) {
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
          onTap: () => _navigateToForm(service: service),
          borderRadius: AppRadius.lgRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppThemeColors.primarySurface,
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: const Icon(
                    Icons.local_laundry_service,
                    color: AppThemeColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          // Price badge
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
                              CurrencyFormatter.format(service.price),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppThemeColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '/ ${service.unit.value}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppThemeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppThemeColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${service.durationDays} hari pengerjaan',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppThemeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppThemeColors.background,
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: AppThemeColors.textSecondary,
                      size: 18,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdRadius,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _navigateToForm(service: service);
                        break;
                      case 'delete':
                        _showDeleteDialog(service);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppThemeColors.primarySurface,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: AppThemeColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Edit',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppThemeColors.error.withValues(alpha: 0.1),
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: const Icon(
                              Icons.delete,
                              size: 16,
                              color: AppThemeColors.error,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Hapus',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppThemeColors.error,
                            ),
                          ),
                        ],
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
