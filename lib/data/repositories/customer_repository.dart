import 'dart:math';
import 'package:kreatif_laundry_offline_app/core/constants/app_constants.dart';
import 'package:kreatif_laundry_offline_app/data/database/database_helper.dart';
import 'package:kreatif_laundry_offline_app/data/models/customer.dart';

class CustomerRepository {
  final DatabaseHelper _databaseHelper;

  CustomerRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Get all customers
  Future<List<Customer>> getAllCustomers() async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'customers',
      orderBy: 'name ASC',
      limit: AppConstants.isDemo ? 5 : null,
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  /// Get customer by ID
  Future<Customer?> getCustomerById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Customer.fromMap(result.first);
  }

  /// Search customers by name or phone
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
      limit: AppConstants.isDemo ? 5 : null,
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  /// Create new customer
  Future<Customer> createCustomer(Customer customer) async {
    final db = await _databaseHelper.database;

    if (customer.name.trim().isEmpty) {
      throw Exception('Nama customer tidak boleh kosong');
    }

    // Check phone uniqueness if provided
    if (customer.phone != null && customer.phone!.isNotEmpty) {
      final existing = await getCustomerByPhone(customer.phone!);
      if (existing != null) {
        throw Exception('Nomor HP sudah terdaftar');
      }
    }

    final now = DateTime.now().toIso8601String();
    final id = await db.insert('customers', {
      'name': customer.name.trim(),
      'phone': customer.phone?.trim(),
      'address': customer.address?.trim(),
      'notes': customer.notes?.trim(),
      'total_orders': 0,
      'total_spent': 0,
      'created_at': now,
      'updated_at': now,
    });

    return customer.copyWith(
      id: id,
      totalOrders: 0,
      totalSpent: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Update customer
  Future<Customer> updateCustomer(Customer customer) async {
    final db = await _databaseHelper.database;

    if (customer.id == null) {
      throw Exception('Customer ID tidak ditemukan');
    }

    if (customer.name.trim().isEmpty) {
      throw Exception('Nama customer tidak boleh kosong');
    }

    // Check phone uniqueness if provided (excluding current customer)
    if (customer.phone != null && customer.phone!.isNotEmpty) {
      final existing = await getCustomerByPhone(customer.phone!);
      if (existing != null && existing.id != customer.id) {
        throw Exception('Nomor HP sudah terdaftar');
      }
    }

    final now = DateTime.now().toIso8601String();
    await db.update(
      'customers',
      {
        'name': customer.name.trim(),
        'phone': customer.phone?.trim(),
        'address': customer.address?.trim(),
        'notes': customer.notes?.trim(),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [customer.id],
    );

    return customer.copyWith(updatedAt: DateTime.now());
  }

  /// Get customer by phone
  Future<Customer?> getCustomerByPhone(String phone) async {
    final db = await _databaseHelper.database;
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    final result = await db.query(
      'customers',
      where: "REPLACE(REPLACE(REPLACE(phone, '-', ''), ' ', ''), '+', '') = ?",
      whereArgs: [cleaned],
    );
    if (result.isEmpty) return null;
    return Customer.fromMap(result.first);
  }

  /// Get or create customer by name (when no phone provided)
  /// If exact name exists, return existing customer
  /// If not, create new customer
  Future<Customer> getOrCreateByName({
    required String name,
  }) async {
    final db = await _databaseHelper.database;

    // Check if customer with this exact name exists
    final result = await db.query(
      'customers',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [name.trim()],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Customer.fromMap(result.first);
    }

    // Create new customer
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('customers', {
      'name': name.trim(),
      'phone': null,
      'total_orders': 0,
      'total_spent': 0,
      'created_at': now,
      'updated_at': now,
    });

    return Customer(
      id: id,
      name: name.trim(),
      totalOrders: 0,
      totalSpent: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Get or create customer by phone (phone is unique identifier)
  /// If phone exists, update name if different and return existing customer
  /// If phone doesn't exist, create new customer
  Future<Customer> getOrCreateByPhone({
    required String name,
    required String phone,
  }) async {
    final db = await _databaseHelper.database;
    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanedPhone.isEmpty) {
      throw Exception('Nomor HP tidak boleh kosong');
    }

    // Check if customer with this phone exists
    final existing = await getCustomerByPhone(cleanedPhone);

    if (existing != null) {
      // Update name if different
      if (existing.name != name.trim()) {
        await db.update(
          'customers',
          {
            'name': name.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        return existing.copyWith(name: name.trim());
      }
      return existing;
    }

    // Create new customer
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('customers', {
      'name': name.trim(),
      'phone': cleanedPhone,
      'total_orders': 0,
      'total_spent': 0,
      'created_at': now,
      'updated_at': now,
    });

    return Customer(
      id: id,
      name: name.trim(),
      phone: cleanedPhone,
      totalOrders: 0,
      totalSpent: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Delete customer
  Future<void> deleteCustomer(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update customer order stats (called after order creation)
  Future<void> updateCustomerStats({
    required int customerId,
    required int orderAmount,
  }) async {
    final db = await _databaseHelper.database;

    final customer = await getCustomerById(customerId);
    if (customer == null) return;

    await db.update(
      'customers',
      {
        'total_orders': customer.totalOrders + 1,
        'total_spent': customer.totalSpent + orderAmount,
        'last_order_date': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  /// Get top customers by total spent
  Future<List<Customer>> getTopCustomers({int limit = 10}) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'customers',
      orderBy: 'total_spent DESC',
      limit: AppConstants.isDemo ? min(limit, 5) : limit,
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  /// Get customer count
  Future<int> getCustomerCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM customers',
    );
    return result.first['count'] as int;
  }
}
