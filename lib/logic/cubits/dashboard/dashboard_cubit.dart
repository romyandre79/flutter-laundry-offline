import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';
import 'package:kreatif_laundry_offline_app/data/repositories/order_repository.dart';
import 'package:kreatif_laundry_offline_app/data/repositories/payment_repository.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/dashboard/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final OrderRepository _orderRepository;
  final PaymentRepository _paymentRepository;

  DashboardCubit({
    OrderRepository? orderRepository,
    PaymentRepository? paymentRepository,
  })  : _orderRepository = orderRepository ?? OrderRepository(),
        _paymentRepository = paymentRepository ?? PaymentRepository(),
        super(const DashboardInitial());

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());

    try {
      // Load all dashboard data in parallel
      final results = await Future.wait([
        _orderRepository.getTodayOrderCountByStatus(),
        _paymentRepository.getTodayRevenue(),
        _paymentRepository.getThisMonthOrderCount(),
        _orderRepository.getRecentOrders(limit: 5),
      ]);

      emit(DashboardLoaded(
        todayStatusCounts: results[0] as Map<OrderStatus, int>,
        todayRevenue: results[1] as int,
        monthOrderCount: results[2] as int,
        recentOrders: results[3] as List<Order>,
      ));
    } catch (e) {
      emit(DashboardError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
