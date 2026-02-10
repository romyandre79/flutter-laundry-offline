import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/customer/customer_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/order/order_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/order/order_state.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/service/service_cubit.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/orders/order_form_screen.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/orders/order_detail_screen.dart';
import 'package:kreatif_laundry_offline_app/presentation/widgets/order_card.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  OrderStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near the bottom
      context.read<OrderCubit>().loadMoreOrders();
    }
  }

  void _loadOrders() {
    context.read<OrderCubit>().loadOrders(status: _selectedStatus);
  }

  void _onStatusChanged(OrderStatus? status) {
    setState(() {
      _selectedStatus = status;
    });
    context.read<OrderCubit>().loadOrders(status: status);
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _loadOrders();
    } else {
      context.read<OrderCubit>().searchOrders(query);
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

          // Filter Chips
          _buildFilterChips(),

          // Order List
          Expanded(
            child: BlocConsumer<OrderCubit, OrderState>(
                listener: (context, state) {
                  if (state is OrderOperationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppThemeColors.success,
                      ),
                    );
                  } else if (state is OrderError) {
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
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppThemeColors.primary,
                      ),
                    );
                  }

                  final orders = context.read<OrderCubit>().orders;

                  if (orders.isEmpty) {
                    return _buildEmptyState();
                  }

                  final hasMore = state is OrderLoaded ? state.hasMore : false;
                  final isLoadingMore = state is OrderLoaded ? state.isLoadingMore : false;

                  return RefreshIndicator(
                    onRefresh: () async {
                      _loadOrders();
                    },
                    color: AppThemeColors.primary,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: orders.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Loading indicator at the bottom
                        if (index >= orders.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            child: Center(
                              child: isLoadingMore
                                  ? const CircularProgressIndicator(
                                      color: AppThemeColors.primary,
                                      strokeWidth: 2,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }

                        final order = orders[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: OrderCard(
                            order: order,
                            onTap: () => _navigateToDetail(order),
                          ),
                        );
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
              // Title Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Orders',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Close button - only show when can pop (pushed from another screen)
                  if (Navigator.canPop(context))
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
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),

              // Search Field (Always visible)
              const SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Cari nama, HP, atau invoice...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppThemeColors.textHint,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppThemeColors.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppThemeColors.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _loadOrders();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {}); // Update UI for clear button
                    _performSearch(value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Semua',
              isSelected: _selectedStatus == null,
              onTap: () => _onStatusChanged(null),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterChip(
              label: 'Pending',
              isSelected: _selectedStatus == OrderStatus.pending,
              onTap: () => _onStatusChanged(OrderStatus.pending),
              color: AppThemeColors.warning,
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterChip(
              label: 'Proses',
              isSelected: _selectedStatus == OrderStatus.process,
              onTap: () => _onStatusChanged(OrderStatus.process),
              color: AppThemeColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterChip(
              label: 'Siap Ambil',
              isSelected: _selectedStatus == OrderStatus.ready,
              onTap: () => _onStatusChanged(OrderStatus.ready),
              color: AppThemeColors.success,
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterChip(
              label: 'Selesai',
              isSelected: _selectedStatus == OrderStatus.done,
              onTap: () => _onStatusChanged(OrderStatus.done),
              color: AppThemeColors.completed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? AppThemeColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: AppRadius.fullRadius,
          border: Border.all(
            color: isSelected ? chipColor : AppThemeColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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
                Icons.receipt_long_outlined,
                size: 40,
                color: AppThemeColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Belum ada order',
              style: AppTypography.titleMedium.copyWith(
                color: AppThemeColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap tombol + untuk membuat order baru',
              style: AppTypography.bodySmall.copyWith(
                color: AppThemeColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
        onPressed: _navigateToCreateOrder,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Order Baru',
          style: AppTypography.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<OrderCubit>(),
          child: OrderDetailScreen(orderId: order.id!),
        ),
      ),
    );
  }

  void _navigateToCreateOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<OrderCubit>()),
            BlocProvider(create: (_) => ServiceCubit()..loadServices()),
            BlocProvider(create: (_) => CustomerCubit()..loadCustomers()),
          ],
          child: const OrderFormScreen(),
        ),
      ),
    );
  }
}
