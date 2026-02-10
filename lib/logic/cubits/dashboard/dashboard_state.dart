import 'package:equatable/equatable.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final Map<OrderStatus, int> todayStatusCounts;
  final int todayRevenue;
  final int monthOrderCount;
  final List<Order> recentOrders;

  const DashboardLoaded({
    required this.todayStatusCounts,
    required this.todayRevenue,
    required this.monthOrderCount,
    required this.recentOrders,
  });

  @override
  List<Object?> get props => [
        todayStatusCounts,
        todayRevenue,
        monthOrderCount,
        recentOrders,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
