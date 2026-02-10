import 'package:equatable/equatable.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';

class ReportData {
  final DateTime startDate;
  final DateTime endDate;
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int totalRevenue;
  final int totalPaid;
  final int totalUnpaid;
  final Map<OrderStatus, int> ordersByStatus;
  final List<DailyRevenue> dailyRevenue;
  final List<ServiceSummary> topServices;

  ReportData({
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.totalRevenue,
    required this.totalPaid,
    required this.totalUnpaid,
    required this.ordersByStatus,
    required this.dailyRevenue,
    required this.topServices,
  });
}

class DailyRevenue {
  final DateTime date;
  final int revenue;
  final int orderCount;
  final int paid; // Pembayaran yang diterima pada tanggal ini

  DailyRevenue({
    required this.date,
    required this.revenue,
    required this.orderCount,
    this.paid = 0,
  });
}

class ServiceSummary {
  final String serviceName;
  final int totalQuantity;
  final int totalRevenue;
  final int orderCount;

  ServiceSummary({
    required this.serviceName,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.orderCount,
  });
}

abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

class ReportLoaded extends ReportState {
  final ReportData data;
  final List<Order> orders;

  const ReportLoaded({required this.data, required this.orders});

  @override
  List<Object?> get props => [data, orders];
}

class ReportExporting extends ReportState {
  const ReportExporting();
}

class ReportExported extends ReportState {
  final String filePath;
  final String message;

  const ReportExported({required this.filePath, required this.message});

  @override
  List<Object?> get props => [filePath, message];
}

class ReportError extends ReportState {
  final String message;

  const ReportError(this.message);

  @override
  List<Object?> get props => [message];
}
