import 'package:kreatif_laundry_offline_app/data/database/database_helper.dart';
import 'package:kreatif_laundry_offline_app/data/models/payment.dart';

class PaymentRepository {
  final DatabaseHelper _databaseHelper;

  PaymentRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Get all payments for an order
  Future<List<Payment>> getPaymentsByOrderId(int orderId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'payments',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'payment_date DESC',
    );

    return result.map((map) => Payment.fromMap(map)).toList();
  }

  /// Add payment and update order paid amount
  Future<Payment> addPayment(Payment payment) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      // Insert payment
      final now = DateTime.now().toIso8601String();
      final paymentId = await txn.insert('payments', {
        'order_id': payment.orderId,
        'amount': payment.amount,
        'change': payment.change,
        'payment_date': payment.paymentDate.toIso8601String(),
        'payment_method': payment.paymentMethod.value,
        'notes': payment.notes,
        'received_by': payment.receivedBy,
        'created_at': now,
      });

      // Get current paid amount and total price
      final orderResult = await txn.query(
        'orders',
        columns: ['paid', 'total_price'],
        where: 'id = ?',
        whereArgs: [payment.orderId],
      );

      if (orderResult.isNotEmpty) {
        final currentPaid = orderResult.first['paid'] as int;
        final totalPrice = orderResult.first['total_price'] as int;

        // Hitung berapa yang masuk ke paid (dikurangi kembalian)
        final actualPaid = payment.amount - payment.change;
        var newPaid = currentPaid + actualPaid;

        // Pastikan tidak melebihi total price
        if (newPaid > totalPrice) {
          newPaid = totalPrice;
        }

        // Update order paid amount
        await txn.update(
          'orders',
          {
            'paid': newPaid,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [payment.orderId],
        );
      }

      return payment.copyWith(id: paymentId);
    });
  }

  /// Get total paid amount for an order
  Future<int> getTotalPaidAmount(int orderId) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE order_id = ?',
      [orderId],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get payments by date range
  Future<List<Payment>> getPaymentsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseHelper.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.query(
      'payments',
      where: 'payment_date >= ? AND payment_date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'payment_date DESC',
    );

    return result.map((map) => Payment.fromMap(map)).toList();
  }

  /// Get total revenue by date range (amount - change = actual revenue)
  Future<int> getTotalRevenueByDateRange(DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(amount - change) as total FROM payments WHERE payment_date >= ? AND payment_date <= ?',
      [startStr, endStr],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get today's total revenue
  Future<int> getTodayRevenue() async {
    final today = DateTime.now();
    return getTotalRevenueByDateRange(today, today);
  }

  /// Get revenue by payment method (amount - change = actual revenue)
  Future<Map<PaymentMethod, int>> getRevenueByPaymentMethod(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseHelper.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final revenue = <PaymentMethod, int>{};
    for (final method in PaymentMethod.values) {
      final result = await db.rawQuery(
        'SELECT SUM(amount - change) as total FROM payments WHERE payment_method = ? AND payment_date >= ? AND payment_date <= ?',
        [method.value, startStr, endStr],
      );
      revenue[method] = (result.first['total'] as int?) ?? 0;
    }

    return revenue;
  }

  /// Get this month's total order count
  Future<int> getThisMonthOrderCount() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE created_at >= ? AND created_at <= ?',
      [startOfMonth, endOfMonth],
    );

    return result.first['count'] as int;
  }
}
