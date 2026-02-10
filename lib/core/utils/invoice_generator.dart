import 'package:kreatif_laundry_offline_app/core/constants/app_constants.dart';
import 'package:kreatif_laundry_offline_app/core/utils/date_formatter.dart';
import 'package:kreatif_laundry_offline_app/data/database/database_helper.dart';

class InvoiceGenerator {
  /// Generate invoice number
  /// Format: PREFIX-YYMMDD-NNNN
  /// Example: LNDR-260115-0001
  static Future<String> generate() async {
    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now();
    final dateStr = DateFormatter.formatForInvoice(today);
    final todayStr = DateFormatter.formatIsoDate(today);

    // Get settings
    final settingsResult = await db.query(
      'app_settings',
      where: 'key IN (?, ?, ?)',
      whereArgs: [
        AppConstants.keyInvoicePrefix,
        AppConstants.keyLastInvoiceDate,
        AppConstants.keyLastInvoiceNumber,
      ],
    );

    final settings = Map.fromEntries(
      settingsResult.map((e) => MapEntry(e['key'] as String, e['value'] as String)),
    );

    final prefix = settings[AppConstants.keyInvoicePrefix] ?? AppConstants.defaultInvoicePrefix;
    final lastDate = settings[AppConstants.keyLastInvoiceDate] ?? '';
    final lastNumber = int.parse(settings[AppConstants.keyLastInvoiceNumber] ?? '0');

    int nextNumber;
    if (lastDate == todayStr) {
      // Same day, increment
      nextNumber = lastNumber + 1;
    } else {
      // New day, reset to 1
      nextNumber = 1;
    }

    // Update settings
    await db.rawInsert('''
      INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)
    ''', [AppConstants.keyLastInvoiceDate, todayStr]);

    await db.rawInsert('''
      INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)
    ''', [AppConstants.keyLastInvoiceNumber, nextNumber.toString()]);

    // Format: LNDR-260115-0001
    final paddedNumber = nextNumber.toString().padLeft(AppConstants.invoiceNumberLength, '0');
    return '$prefix-$dateStr-$paddedNumber';
  }

  /// Validate invoice format
  static bool isValidInvoice(String invoice) {
    // Pattern: PREFIX-YYMMDD-NNNN
    final pattern = RegExp(r'^[A-Z]+-\d{6}-\d{4}$');
    return pattern.hasMatch(invoice);
  }

  /// Extract date from invoice
  static DateTime? extractDate(String invoice) {
    try {
      final parts = invoice.split('-');
      if (parts.length != 3) return null;

      final dateStr = parts[1];
      final year = 2000 + int.parse(dateStr.substring(0, 2));
      final month = int.parse(dateStr.substring(2, 4));
      final day = int.parse(dateStr.substring(4, 6));

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  /// Extract sequence number from invoice
  static int? extractSequence(String invoice) {
    try {
      final parts = invoice.split('-');
      if (parts.length != 3) return null;
      return int.parse(parts[2]);
    } catch (e) {
      return null;
    }
  }
}
