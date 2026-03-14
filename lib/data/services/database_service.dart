import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:kreatif_laundry_offline_app/core/constants/app_constants.dart';
import 'package:kreatif_laundry_offline_app/data/database/database_helper.dart';
import 'package:share_plus/share_plus.dart';

class DatabaseService {
  final DatabaseHelper _databaseHelper;

  DatabaseService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<String> get _dbPath async {
    return await _databaseHelper.getDbPath();
  }

  Future<void> backupDatabase() async {
    final dbPath = await _dbPath;
    final file = File(dbPath);
    
    if (!await file.exists()) {
      throw Exception('Database file not found at $dbPath');
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Select where to save the backup',
        fileName: 'backup_${AppConstants.databaseName}_${DateTime.now().toIso8601String().replaceAll(':', '-')}.db',
      );

      if (outputFile != null) {
        await file.copy(outputFile);
      }
    } else {
      // Android/iOS: Share the file
      await Share.shareXFiles([XFile(dbPath)], text: 'Database Backup');
    }
  }

  Future<void> restoreDatabase() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select backup file',
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final sourcePath = result.files.single.path!;
      final dbPath = await _dbPath;

      // Close DB connection
      await _databaseHelper.close();

      // Overwrite DB
      await File(sourcePath).copy(dbPath);

      // Re-open DB (handled by next access to database getter, but checking effectively re-opens)
      // We might need to restart the app or trigger a re-provider of blocs
    }
  }

  Future<void> resetDatabase() async {
    await _databaseHelper.resetDatabase();
  }
}
