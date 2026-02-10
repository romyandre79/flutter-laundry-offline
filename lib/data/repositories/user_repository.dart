import 'package:kreatif_laundry_offline_app/core/utils/password_helper.dart';
import 'package:kreatif_laundry_offline_app/data/database/database_helper.dart';
import 'package:kreatif_laundry_offline_app/data/models/user.dart';

class UserRepository {
  final DatabaseHelper _databaseHelper;

  UserRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Get all users (for owner management)
  Future<List<User>> getAllUsers() async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'users',
      orderBy: 'role ASC, name ASC',
    );
    return result.map((map) => User.fromMap(map)).toList();
  }

  /// Get all active users
  Future<List<User>> getActiveUsers() async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'users',
      where: 'is_active = 1',
      orderBy: 'role ASC, name ASC',
    );
    return result.map((map) => User.fromMap(map)).toList();
  }

  /// Get user by ID
  Future<User?> getUserById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  /// Get user by username
  Future<User?> getUserByUsername(String username) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.toLowerCase().trim()],
    );
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  /// Create new user
  Future<User> createUser({
    required String username,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final db = await _databaseHelper.database;

    // Validate username
    final usernameValidation = PasswordHelper.validateUsername(username);
    if (usernameValidation != null) {
      throw Exception(usernameValidation);
    }

    // Check username uniqueness
    final existing = await getUserByUsername(username);
    if (existing != null) {
      throw Exception('Username sudah digunakan');
    }

    // Validate password
    final passwordValidation = PasswordHelper.validatePassword(password);
    if (passwordValidation != null) {
      throw Exception(passwordValidation);
    }

    // Hash password
    final passwordHash = PasswordHelper.hashPassword(password);

    // Create user
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('users', {
      'username': username.toLowerCase().trim(),
      'password_hash': passwordHash,
      'name': name.trim(),
      'role': role.value,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });

    return User(
      id: id,
      username: username.toLowerCase().trim(),
      passwordHash: passwordHash,
      name: name.trim(),
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Update user info (not password)
  Future<User> updateUser({
    required int id,
    required String name,
    required UserRole role,
  }) async {
    final db = await _databaseHelper.database;

    // Check user exists
    final existing = await getUserById(id);
    if (existing == null) {
      throw Exception('User tidak ditemukan');
    }

    // Update user
    final now = DateTime.now().toIso8601String();
    await db.update(
      'users',
      {
        'name': name.trim(),
        'role': role.value,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    return existing.copyWith(
      name: name.trim(),
      role: role,
      updatedAt: DateTime.now(),
    );
  }

  /// Reset user password (owner only)
  Future<void> resetPassword({
    required int userId,
    required String newPassword,
  }) async {
    final db = await _databaseHelper.database;

    // Check user exists
    final existing = await getUserById(userId);
    if (existing == null) {
      throw Exception('User tidak ditemukan');
    }

    // Validate password
    final validation = PasswordHelper.validatePassword(newPassword);
    if (validation != null) {
      throw Exception(validation);
    }

    // Hash new password
    final newHash = PasswordHelper.hashPassword(newPassword);

    // Update password
    await db.update(
      'users',
      {
        'password_hash': newHash,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Soft delete user (set is_active = 0)
  Future<void> deactivateUser(int id) async {
    final db = await _databaseHelper.database;

    await db.update(
      'users',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Activate user
  Future<void> activateUser(int id) async {
    final db = await _databaseHelper.database;

    await db.update(
      'users',
      {
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Toggle user active status
  Future<bool> toggleUserStatus(int id) async {
    final user = await getUserById(id);
    if (user == null) {
      throw Exception('User tidak ditemukan');
    }

    if (user.isActive) {
      await deactivateUser(id);
      return false;
    } else {
      await activateUser(id);
      return true;
    }
  }

  /// Get user count by role
  Future<Map<UserRole, int>> getUserCountByRole() async {
    final db = await _databaseHelper.database;

    final ownerCount = await db.rawQuery(
      "SELECT COUNT(*) as count FROM users WHERE role = 'owner' AND is_active = 1",
    );
    final kasirCount = await db.rawQuery(
      "SELECT COUNT(*) as count FROM users WHERE role = 'kasir' AND is_active = 1",
    );

    return {
      UserRole.owner: ownerCount.first['count'] as int,
      UserRole.kasir: kasirCount.first['count'] as int,
    };
  }
}
