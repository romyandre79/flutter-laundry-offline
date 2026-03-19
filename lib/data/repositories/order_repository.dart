import 'dart:math';
import 'package:kreatif_laundry_offline_app/core/constants/app_constants.dart';
import 'package:kreatif_laundry_offline_app/data/database/database_helper.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';
import 'package:kreatif_laundry_offline_app/data/models/order_item.dart';
import 'package:kreatif_laundry_offline_app/data/models/payment.dart';
import 'package:kreatif_laundry_offline_app/data/repositories/customer_repository.dart';

class OrderRepository {
  final DatabaseHelper _databaseHelper;
  final CustomerRepository _customerRepository;

  OrderRepository({
    DatabaseHelper? databaseHelper,
    CustomerRepository? customerRepository,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        _customerRepository = customerRepository ?? CustomerRepository();

  /// Get all orders with optional filter and pagination
  Future<List<Order>> getAllOrders({
    OrderStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await _databaseHelper.database;

    String? where;
    List<dynamic>? whereArgs;

    if (status != null) {
      where = 'status = ?';
      whereArgs = [status.value];
    }

    final result = await db.query(
      'orders',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: AppConstants.isDemo ? min(limit, 5) : limit,
      offset: offset,
    );

    return result.map((map) => Order.fromMap(map)).toList();
  }

  /// Get order by ID with items and payments
  Future<Order?> getOrderById(int id) async {
    final db = await _databaseHelper.database;

    final orderResult = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (orderResult.isEmpty) return null;

    final order = Order.fromMap(orderResult.first);

    // Get items
    final itemsResult = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [id],
    );
    final items = itemsResult.map((map) => OrderItem.fromMap(map)).toList();

    // Get payments
    final paymentsResult = await db.query(
      'payments',
      where: 'order_id = ?',
      whereArgs: [id],
      orderBy: 'payment_date DESC',
    );
    final payments = paymentsResult.map((map) => Payment.fromMap(map)).toList();

    // Get images
    final imagesResult = await db.query(
      'order_images',
      where: 'order_id = ?',
      whereArgs: [id],
    );
    final images = imagesResult.map((map) => map['image_path'] as String).toList();

    return order.copyWith(items: items, payments: payments, images: images);
  }

  /// Create new order with items
  Future<Order> createOrder({
    required Order order,
    required List<OrderItem> items,
    Payment? initialPayment,
  }) async {
    final db = await _databaseHelper.database;

    // Auto-save customer if phone is provided (before transaction)
    int? customerId = order.customerId;
    if (order.customerPhone != null && order.customerPhone!.isNotEmpty) {
      try {
        final customer = await _customerRepository.getOrCreateByPhone(
          name: order.customerName,
          phone: order.customerPhone!,
        );
        customerId = customer.id;
      } catch (_) {
        // Ignore customer creation errors, continue with order
      }
    }

    // Create order in transaction
    final createdOrder = await db.transaction((txn) async {
      // Insert order
      final now = DateTime.now().toIso8601String();
      final orderId = await txn.insert('orders', {
        'invoice_no': order.invoiceNo,
        'customer_id': customerId,
        'customer_name': order.customerName,
        'customer_phone': order.customerPhone,
        'order_date': order.orderDate.toIso8601String(),
        'due_date': order.dueDate?.toIso8601String(),
        'status': order.status.value,
        'total_items': order.totalItems,
        'total_weight': order.totalWeight,
        'total_price': order.totalPrice,
        'paid': order.paid,
        'notes': order.notes,
        'created_by': order.createdBy,
        'created_at': now,
        'updated_at': now,
      });

      // Insert items
      for (final item in items) {
        await txn.insert('order_items', {
          'order_id': orderId,
          'service_id': item.serviceId,
          'service_name': item.serviceName,
          'quantity': item.quantity,
          'unit': item.unit,
          'price_per_unit': item.pricePerUnit,
          'subtotal': item.subtotal,
        });
      }

      // Insert initial payment if provided
      if (initialPayment != null && initialPayment.amount > 0) {
        await txn.insert('payments', {
          'order_id': orderId,
          'amount': initialPayment.amount,
          'change': initialPayment.change,
          'payment_date': initialPayment.paymentDate.toIso8601String(),
          'payment_method': initialPayment.paymentMethod.value,
          'notes': initialPayment.notes,
          'received_by': initialPayment.receivedBy,
          'created_at': now,
        });
      }

      // Insert images
      if (order.images.isNotEmpty) {
        for (final imagePath in order.images) {
          await txn.insert('order_images', {
            'order_id': orderId,
            'image_path': imagePath,
            'created_at': now,
          });
        }
      }
      
      return order.copyWith(id: orderId, customerId: customerId);
    });

    // Update customer stats AFTER transaction completes (to avoid deadlock)
    if (customerId != null) {
      try {
        await _customerRepository.updateCustomerStats(
          customerId: customerId,
          orderAmount: order.totalPrice,
        );
      } catch (_) {
        // Ignore stats update errors
      }
    }

    return createdOrder;
  }

  /// Update order status
  Future<void> updateOrderStatus(int id, OrderStatus newStatus) async {
    final db = await _databaseHelper.database;

    await db.update(
      'orders',
      {
        'status': newStatus.value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete order
  Future<void> deleteOrder(int id) async {
    final db = await _databaseHelper.database;
    // Items and payments will be cascade deleted
    await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search orders
  Future<List<Order>> searchOrders(String query) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'customer_name LIKE ? OR customer_phone LIKE ? OR invoice_no LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
      limit: AppConstants.isDemo ? 5 : null,
    );

    return result.map((map) => Order.fromMap(map)).toList();
  }

  /// Get orders by date range
  Future<List<Order>> getOrdersByDateRange(DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;

    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final result = await db.query(
      'orders',
      where: 'order_date >= ? AND order_date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'created_at DESC',
      limit: AppConstants.isDemo ? 5 : null,
    );

    return result.map((map) => Order.fromMap(map)).toList();
  }

  /// Get orders by status count
  Future<Map<OrderStatus, int>> getOrderCountByStatus() async {
    final db = await _databaseHelper.database;

    final counts = <OrderStatus, int>{};
    for (final status in OrderStatus.values) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM orders WHERE status = ?',
        [status.value],
      );
      counts[status] = result.first['count'] as int;
    }

    return counts;
  }

  /// Get today's order count by status
  Future<Map<OrderStatus, int>> getTodayOrderCountByStatus() async {
    final db = await _databaseHelper.database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

    final counts = <OrderStatus, int>{};
    for (final status in OrderStatus.values) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM orders WHERE status = ? AND created_at >= ? AND created_at <= ?',
        [status.value, startOfDay, endOfDay],
      );
      counts[status] = result.first['count'] as int;
    }

    return counts;
  }

  /// Get recent orders
  Future<List<Order>> getRecentOrders({int limit = 5}) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return result.map((map) => Order.fromMap(map)).toList();
  }

  /// Update paid amount after payment
  Future<void> updatePaidAmount(int orderId, int newPaidAmount) async {
    final db = await _databaseHelper.database;

    await db.update(
      'orders',
      {
        'paid': newPaidAmount,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }
}
