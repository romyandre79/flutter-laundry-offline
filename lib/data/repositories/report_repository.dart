import 'package:kreatif_laundry_offline_app/data/database/database_helper.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/report/report_state.dart';

class ReportRepository {
  final DatabaseHelper _databaseHelper;

  ReportRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Get orders within date range
  Future<List<Order>> getOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;

    // Set start to beginning of day and end to end of day
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final result = await db.query(
      'orders',
      where: 'order_date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'order_date DESC',
    );

    return result.map((map) => Order.fromMap(map)).toList();
  }

  /// Get report data for date range
  Future<ReportData> getReportData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // Get total orders and revenue (based on order_date)
    final summaryResult = await db.rawQuery('''
      SELECT
        COUNT(*) as total_orders,
        SUM(total_price) as total_revenue
      FROM orders
      WHERE order_date BETWEEN ? AND ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final summary = summaryResult.first;
    final totalOrders = (summary['total_orders'] as int?) ?? 0;
    final totalRevenue = (summary['total_revenue'] as int?) ?? 0;

    // Get total paid (based on payment_date from payments table)
    final paidResult = await db.rawQuery('''
      SELECT
        SUM(amount - COALESCE(change, 0)) as total_paid
      FROM payments
      WHERE payment_date BETWEEN ? AND ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final totalPaid = (paidResult.first['total_paid'] as int?) ?? 0;

    // Get orders by status
    final statusResult = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM orders
      WHERE order_date BETWEEN ? AND ?
      GROUP BY status
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final ordersByStatus = <OrderStatus, int>{};
    int completedOrders = 0;
    int pendingOrders = 0;

    for (final row in statusResult) {
      final status = OrderStatusExtension.fromString(row['status'] as String);
      final count = row['count'] as int;
      ordersByStatus[status] = count;

      if (status == OrderStatus.done) {
        completedOrders = count;
      } else if (status != OrderStatus.done) {
        pendingOrders += count;
      }
    }

    // Get daily revenue (orders by order_date)
    final dailyOrderResult = await db.rawQuery('''
      SELECT
        DATE(order_date) as date,
        SUM(total_price) as revenue,
        COUNT(*) as order_count
      FROM orders
      WHERE order_date BETWEEN ? AND ?
      GROUP BY DATE(order_date)
      ORDER BY date ASC
    ''', [start.toIso8601String(), end.toIso8601String()]);

    // Get daily payments (payments by payment_date)
    final dailyPaymentResult = await db.rawQuery('''
      SELECT
        DATE(payment_date) as date,
        SUM(amount - COALESCE(change, 0)) as paid
      FROM payments
      WHERE payment_date BETWEEN ? AND ?
      GROUP BY DATE(payment_date)
    ''', [start.toIso8601String(), end.toIso8601String()]);

    // Create map of daily payments
    final dailyPayments = <String, int>{};
    for (final row in dailyPaymentResult) {
      final date = row['date'] as String;
      dailyPayments[date] = (row['paid'] as int?) ?? 0;
    }

    // Combine orders and payments data
    final dailyRevenue = dailyOrderResult.map((row) {
      final dateStr = row['date'] as String;
      return DailyRevenue(
        date: DateTime.parse(dateStr),
        revenue: (row['revenue'] as int?) ?? 0,
        orderCount: (row['order_count'] as int?) ?? 0,
        paid: dailyPayments[dateStr] ?? 0,
      );
    }).toList();

    // Add days that have payments but no orders
    for (final entry in dailyPayments.entries) {
      final exists = dailyRevenue.any(
        (d) => d.date.toIso8601String().substring(0, 10) == entry.key,
      );
      if (!exists && entry.value > 0) {
        dailyRevenue.add(DailyRevenue(
          date: DateTime.parse(entry.key),
          revenue: 0,
          orderCount: 0,
          paid: entry.value,
        ));
      }
    }

    // Sort by date
    dailyRevenue.sort((a, b) => a.date.compareTo(b.date));

    // Get top services
    final serviceResult = await db.rawQuery('''
      SELECT
        oi.service_name,
        SUM(oi.quantity) as total_quantity,
        SUM(oi.subtotal) as total_revenue,
        COUNT(DISTINCT oi.order_id) as order_count
      FROM order_items oi
      JOIN orders o ON o.id = oi.order_id
      WHERE o.order_date BETWEEN ? AND ?
      GROUP BY oi.service_name
      ORDER BY total_revenue DESC
      LIMIT 10
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final topServices = serviceResult.map((row) {
      return ServiceSummary(
        serviceName: row['service_name'] as String,
        totalQuantity: ((row['total_quantity'] as num?) ?? 0).toInt(),
        totalRevenue: (row['total_revenue'] as int?) ?? 0,
        orderCount: (row['order_count'] as int?) ?? 0,
      );
    }).toList();

    return ReportData(
      startDate: startDate,
      endDate: endDate,
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      pendingOrders: pendingOrders,
      totalRevenue: totalRevenue,
      totalPaid: totalPaid,
      totalUnpaid: totalRevenue - totalPaid,
      ordersByStatus: ordersByStatus,
      dailyRevenue: dailyRevenue,
      topServices: topServices,
    );
  }
}
