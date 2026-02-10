import 'package:kreatif_laundry_offline_app/data/database/database_helper.dart';

class SettingsRepository {
  final DatabaseHelper _databaseHelper;

  SettingsRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Get single setting value
  Future<String?> getSetting(String key) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  /// Set setting value
  Future<void> setSetting(String key, String value) async {
    final db = await _databaseHelper.database;

    // Check if exists
    final existing = await getSetting(key);

    if (existing != null) {
      await db.update(
        'app_settings',
        {'value': value},
        where: 'key = ?',
        whereArgs: [key],
      );
    } else {
      await db.insert('app_settings', {
        'key': key,
        'value': value,
      });
    }
  }

  /// Get all settings
  Future<Map<String, String>> getAllSettings() async {
    final db = await _databaseHelper.database;

    final result = await db.query('app_settings');

    return Map.fromEntries(
      result.map((e) => MapEntry(e['key'] as String, e['value'] as String)),
    );
  }

  /// Batch update settings
  Future<void> updateSettings(Map<String, String> settings) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      for (final entry in settings.entries) {
        final existing = await txn.query(
          'app_settings',
          where: 'key = ?',
          whereArgs: [entry.key],
        );

        if (existing.isNotEmpty) {
          await txn.update(
            'app_settings',
            {'value': entry.value},
            where: 'key = ?',
            whereArgs: [entry.key],
          );
        } else {
          await txn.insert('app_settings', {
            'key': entry.key,
            'value': entry.value,
          });
        }
      }
    });
  }
}
