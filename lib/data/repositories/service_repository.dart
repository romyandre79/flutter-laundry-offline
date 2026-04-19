import 'package:kreatif_laundry_offline_app/data/database/database_helper.dart';
import 'package:kreatif_laundry_offline_app/data/models/service.dart';

class ServiceRepository {
  final DatabaseHelper _databaseHelper;

  ServiceRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Get all active services
  Future<List<Service>> getAllServices() async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'services',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
    return result.map((map) => Service.fromMap(map)).toList();
  }

  /// Get all services (including inactive)
  Future<List<Service>> getAllServicesIncludingInactive() async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'services',
      orderBy: 'is_active DESC, name ASC',
    );
    return result.map((map) => Service.fromMap(map)).toList();
  }

  /// Get service by ID
  Future<Service?> getServiceById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'services',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Service.fromMap(result.first);
  }

  /// Create new service
  Future<Service> createService(Service service) async {
    final db = await _databaseHelper.database;

    // Validate
    if (service.name.trim().isEmpty) {
      throw Exception('Nama layanan tidak boleh kosong');
    }
    if (service.price <= 0) {
      throw Exception('Harga harus lebih dari 0');
    }

    final now = DateTime.now().toIso8601String();
    final id = await db.insert('services', {
      'name': service.name.trim(),
      'unit': service.unit.value,
      'price': service.price,
      'duration_days': service.durationDays,
      'is_active': 1,
      'barcode': service.barcode,
      'created_at': now,
    });

    return service.copyWith(
      id: id,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  /// Update existing service
  Future<Service> updateService(Service service) async {
    final db = await _databaseHelper.database;

    if (service.id == null) {
      throw Exception('Service ID tidak ditemukan');
    }

    // Validate
    if (service.name.trim().isEmpty) {
      throw Exception('Nama layanan tidak boleh kosong');
    }
    if (service.price <= 0) {
      throw Exception('Harga harus lebih dari 0');
    }

    await db.update(
      'services',
      {
        'name': service.name.trim(),
        'unit': service.unit.value,
        'price': service.price,
        'duration_days': service.durationDays,
        'barcode': service.barcode,
      },
      where: 'id = ?',
      whereArgs: [service.id],
    );

    return service;
  }

  /// Soft delete service (set is_active = 0)
  Future<void> deleteService(int id) async {
    final db = await _databaseHelper.database;

    await db.update(
      'services',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Restore deleted service
  Future<void> restoreService(int id) async {
    final db = await _databaseHelper.database;

    await db.update(
      'services',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Check if service name exists (for validation)
  Future<bool> serviceNameExists(String name, {int? excludeId}) async {
    final db = await _databaseHelper.database;

    String where = 'LOWER(name) = ? AND is_active = 1';
    List<dynamic> whereArgs = [name.toLowerCase().trim()];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.query(
      'services',
      where: where,
      whereArgs: whereArgs,
    );

    return result.isNotEmpty;
  }

  /// Get service count
  Future<int> getServiceCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM services WHERE is_active = 1',
    );
    return result.first['count'] as int;
  }
}
