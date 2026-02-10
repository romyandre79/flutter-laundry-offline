import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/core/utils/currency_formatter.dart';
import 'package:kreatif_laundry_offline_app/core/utils/date_formatter.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/report/report_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/report/report_state.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'Bulan Ini';

  @override
  void initState() {
    super.initState();
    _setThisMonth();
    _loadReport();
  }

  void _setThisMonth() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _selectedPeriod = 'Bulan Ini';
  }

  void _setLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    _startDate = lastMonth;
    _endDate = DateTime(now.year, now.month, 0);
    _selectedPeriod = 'Bulan Lalu';
  }

  void _setThisWeek() {
    final now = DateTime.now();
    _startDate = now.subtract(Duration(days: now.weekday - 1));
    _endDate = now;
    _selectedPeriod = 'Minggu Ini';
  }

  void _setToday() {
    final now = DateTime.now();
    _startDate = now;
    _endDate = now;
    _selectedPeriod = 'Hari Ini';
  }

  void _loadReport() {
    context.read<ReportCubit>().loadReport(_startDate, _endDate);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppThemeColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'Custom';
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Period selector
          _buildPeriodSelector(),

          // Report content
          Expanded(
            child: BlocConsumer<ReportCubit, ReportState>(
                listener: (context, state) {
                  if (state is ReportExported) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppThemeColors.success,
                      ),
                    );
                  } else if (state is ReportError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppThemeColors.error,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is ReportLoading || state is ReportExporting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppThemeColors.primary,
                      ),
                    );
                  }

                  if (state is ReportLoaded) {
                    return _buildReportContent(state);
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 64,
                          color: AppThemeColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Pilih periode untuk melihat laporan',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppThemeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
              Expanded(
                child: Text(
                  'Laporan',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              BlocBuilder<ReportCubit, ReportState>(
                builder: (context, state) {
                  final isLoaded = state is ReportLoaded;
                  return GestureDetector(
                    onTap: isLoaded
                        ? () => context.read<ReportCubit>().exportToExcel()
                        : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isLoaded ? 0.2 : 0.1),
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Icon(
                        Icons.file_download_outlined,
                        color: Colors.white.withValues(alpha: isLoaded ? 1.0 : 0.5),
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.small,
      ),
      child: Column(
        children: [
          // Quick period buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodChip('Hari Ini', _setToday),
                const SizedBox(width: AppSpacing.sm),
                _buildPeriodChip('Minggu Ini', _setThisWeek),
                const SizedBox(width: AppSpacing.sm),
                _buildPeriodChip('Bulan Ini', _setThisMonth),
                const SizedBox(width: AppSpacing.sm),
                _buildPeriodChip('Bulan Lalu', _setLastMonth),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Date range display
          GestureDetector(
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppThemeColors.border),
                borderRadius: AppRadius.mdRadius,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppThemeColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${DateFormatter.formatDate(_startDate)} - ${DateFormatter.formatDate(_endDate)}',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: AppThemeColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, VoidCallback onSelect) {
    final isSelected = _selectedPeriod == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          onSelect();
        });
        _loadReport();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppThemeColors.primary : Colors.transparent,
          borderRadius: AppRadius.fullRadius,
          border: Border.all(
            color: isSelected ? AppThemeColors.primary : AppThemeColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppThemeColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(ReportLoaded state) {
    final data = state.data;

    return RefreshIndicator(
      onRefresh: () async => _loadReport(),
      color: AppThemeColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Summary cards
          _buildSummaryCards(data),
          const SizedBox(height: AppSpacing.xl),

          // Revenue chart
          _buildRevenueChart(data),
          const SizedBox(height: AppSpacing.xl),

          // Status breakdown
          _buildStatusBreakdown(data),
          const SizedBox(height: AppSpacing.xl),

          // Top services
          _buildTopServices(data),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ReportData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Main stats - 2x2 grid
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.shopping_bag_outlined,
                label: 'Total Order',
                value: '${data.totalOrders}',
                color: AppThemeColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle_outline,
                label: 'Selesai',
                value: '${data.completedOrders}',
                color: AppThemeColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.payments_outlined,
                label: 'Total Omzet',
                value: CurrencyFormatter.formatCompact(data.totalRevenue),
                color: AppThemeColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Dibayar',
                value: CurrencyFormatter.formatCompact(data.totalPaid),
                color: AppThemeColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Unpaid - full width
        _buildStatCard(
          icon: Icons.pending_actions_outlined,
          label: 'Belum Dibayar',
          value: CurrencyFormatter.format(data.totalUnpaid),
          color: data.totalUnpaid > 0 ? AppThemeColors.warning : AppThemeColors.success,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.small,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppThemeColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(ReportData data) {
    if (data.dailyRevenue.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pendapatan Harian',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 200,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.lgRadius,
            boxShadow: AppShadows.small,
          ),
          child: BarChart(
            BarChartData(
              barGroups: data.dailyRevenue.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.revenue.toDouble(),
                      gradient: AppThemeColors.primaryGradient,
                      width: data.dailyRevenue.length > 10 ? 8 : 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: data.dailyRevenue.length <= 7,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.dailyRevenue.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${data.dailyRevenue[index].date.day}',
                            style: AppTypography.labelSmall,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBreakdown(ReportData data) {
    if (data.ordersByStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Order',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.lgRadius,
            boxShadow: AppShadows.small,
          ),
          child: Column(
            children: data.ordersByStatus.entries.map((entry) {
              final percentage = data.totalOrders > 0
                  ? (entry.value / data.totalOrders * 100).round()
                  : 0;
              return _buildStatusRow(entry.key, entry.value, percentage);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(dynamic status, int count, int percentage) {
    Color color;
    String label;
    IconData icon;

    if (status.toString().contains('pending')) {
      color = AppThemeColors.warning;
      label = 'Pending';
      icon = Icons.pending_actions;
    } else if (status.toString().contains('process')) {
      color = AppThemeColors.primary;
      label = 'Proses';
      icon = Icons.autorenew;
    } else if (status.toString().contains('ready')) {
      color = AppThemeColors.success;
      label = 'Siap Ambil';
      icon = Icons.check_circle_outline;
    } else {
      color = AppThemeColors.completed;
      label = 'Selesai';
      icon = Icons.done_all;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: AppRadius.smRadius,
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppThemeColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$count',
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopServices(ReportData data) {
    if (data.topServices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layanan Terpopuler',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...data.topServices.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final service = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.lgRadius,
              boxShadow: AppShadows.small,
            ),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? AppThemeColors.warning
                        : index == 1
                            ? AppThemeColors.textSecondary
                            : index == 2
                                ? const Color(0xFFCD7F32)
                                : AppThemeColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTypography.labelSmall.copyWith(
                        color: index < 3 ? Colors.white : AppThemeColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.serviceName,
                        style: AppTypography.titleSmall,
                      ),
                      Text(
                        '${service.orderCount} order',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppThemeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.formatCompact(service.totalRevenue),
                  style: AppTypography.titleSmall.copyWith(
                    color: AppThemeColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
