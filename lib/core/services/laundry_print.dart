import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';
import 'package:kreatif_laundry_offline_app/data/repositories/settings_repository.dart';
import 'package:kreatif_laundry_offline_app/core/utils/currency_formatter.dart';
import 'package:kreatif_laundry_offline_app/core/utils/date_formatter.dart';
import 'package:kreatif_laundry_offline_app/core/constants/app_constants.dart';

class LaundryPrint {
  LaundryPrint._init();

  static final LaundryPrint instance = LaundryPrint._init();

  final SettingsRepository _settingsRepository = SettingsRepository();

  Future<Map<String, String>> _getLaundryInfo() async {
    final settings = await _settingsRepository.getAllSettings();
    return {
      'name': settings[AppConstants.keyLaundryName] ??
          AppConstants.defaultLaundryName,
      'address': settings[AppConstants.keyLaundryAddress] ??
          AppConstants.defaultLaundryAddress,
      'phone': settings[AppConstants.keyLaundryPhone] ??
          AppConstants.defaultLaundryPhone,
    };
  }

  /// Print order receipt
  /// [order] - Order data to print
  /// [paperSize] - Paper size (PaperSize.mm58 or PaperSize.mm80)
  /// [paperSizeMm] - Paper size in mm ('58' or '80') for separator calculation
  Future<List<int>> printOrderReceipt(
    Order order, {
    PaperSize paperSize = PaperSize.mm58,
    String paperSizeMm = '58',
  }) async {
    List<int> bytes = [];

    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);

    // Get laundry info from settings
    final laundryInfo = await _getLaundryInfo();

    // Define separator based on paper size
    final String separator = paperSizeMm == '80'
        ? '------------------------------------------------'
        : '--------------------------------';

    bytes += generator.reset();

    // ========== HEADER ==========
    bytes += generator.text(
      laundryInfo['name'] ?? 'Laundry',
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );

    bytes += generator.text(
      laundryInfo['address'] ?? '',
      styles: const PosStyles(
        bold: false,
        align: PosAlign.center,
      ),
    );

    bytes += generator.text(
      'Telp: ${laundryInfo['phone'] ?? '-'}',
      styles: const PosStyles(
        bold: false,
        align: PosAlign.center,
      ),
    );

    bytes += generator.text(
      separator,
      styles: const PosStyles(bold: false, align: PosAlign.center),
    );

    // ========== ORDER INFO ==========
    bytes += generator.text(
      'STRUK ORDER',
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );

    bytes += generator.text(
      separator,
      styles: const PosStyles(bold: false, align: PosAlign.center),
    );

    // Invoice Number
    bytes += generator.row([
      PosColumn(
        text: 'No Invoice:',
        width: 4,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: order.invoiceNumber,
        width: 8,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    // Date
    bytes += generator.row([
      PosColumn(
        text: 'Tanggal:',
        width: 4,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: DateFormatter.formatDateTime(order.createdAt ?? DateTime.now()),
        width: 8,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    // Customer
    bytes += generator.row([
      PosColumn(
        text: 'Pelanggan:',
        width: 4,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: order.customerName,
        width: 8,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    // Phone (if available)
    if (order.customerPhone != null && order.customerPhone!.isNotEmpty) {
      bytes += generator.row([
        PosColumn(
          text: 'HP:',
          width: 4,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: order.customerPhone!,
          width: 8,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    // Status
    bytes += generator.row([
      PosColumn(
        text: 'Status:',
        width: 4,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: order.status.displayName,
        width: 8,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    // Due Date
    if (order.dueDate != null) {
      bytes += generator.row([
        PosColumn(
          text: 'Ambil:',
          width: 4,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: DateFormatter.formatDate(order.dueDate!),
          width: 8,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.text(
      separator,
      styles: const PosStyles(bold: false, align: PosAlign.center),
    );

    // ========== ITEMS ==========
    bytes += generator.text(
      'DETAIL LAYANAN',
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
      ),
    );

    bytes += generator.text(
      separator,
      styles: const PosStyles(bold: false, align: PosAlign.center),
    );

    for (final item in order.items ?? []) {
      // Service name
      bytes += generator.text(
        item.serviceName,
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );

      // Quantity x Price = Subtotal
      bytes += generator.row([
        PosColumn(
          text: '${item.quantity.toStringAsFixed(0)} ${item.unit} x ${CurrencyFormatter.formatNoSymbol(item.pricePerUnit)}',
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: CurrencyFormatter.formatNoSymbol(item.subtotal),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.text(
      separator,
      styles: const PosStyles(bold: false, align: PosAlign.center),
    );

    // ========== TOTAL ==========
    bytes += generator.row([
      PosColumn(
        text: 'TOTAL',
        width: 6,
        styles: const PosStyles(align: PosAlign.left, bold: true),
      ),
      PosColumn(
        text: CurrencyFormatter.format(order.totalAmount),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    // ========== PAYMENT INFO ==========
    if (order.paidAmount > 0) {
      bytes += generator.row([
        PosColumn(
          text: 'Dibayar',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: CurrencyFormatter.format(order.paidAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      final remaining = order.remainingPayment;
      if (remaining > 0) {
        // Belum lunas - tampilkan kurang
        bytes += generator.row([
          PosColumn(
            text: 'Kurang',
            width: 6,
            styles: const PosStyles(align: PosAlign.left, bold: true),
          ),
          PosColumn(
            text: CurrencyFormatter.format(remaining),
            width: 6,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]);
      } else {
        // Lunas - cek apakah ada kembalian
        final change = order.paidAmount - order.totalAmount;
        if (change > 0) {
          bytes += generator.row([
            PosColumn(
              text: 'Kembalian',
              width: 6,
              styles: const PosStyles(align: PosAlign.left, bold: true),
            ),
            PosColumn(
              text: CurrencyFormatter.format(change),
              width: 6,
              styles: const PosStyles(align: PosAlign.right, bold: true),
            ),
          ]);
        }
        bytes += generator.text(
          '*** LUNAS ***',
          styles: const PosStyles(
            bold: true,
            align: PosAlign.center,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          ),
        );
      }
    } else {
      bytes += generator.text(
        'Belum ada pembayaran',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.text(
      separator,
      styles: const PosStyles(bold: false, align: PosAlign.center),
    );

    // ========== NOTES ==========
    if (order.notes != null && order.notes!.isNotEmpty) {
      bytes += generator.text(
        'Catatan:',
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );
      bytes += generator.text(
        order.notes!,
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        separator,
        styles: const PosStyles(bold: false, align: PosAlign.center),
      );
    }

    // ========== FOOTER ==========
    bytes += generator.text(
      'Terima kasih atas kepercayaan Anda',
      styles: const PosStyles(bold: false, align: PosAlign.center),
    );
    bytes += generator.text(
      'Simpan struk ini sebagai bukti',
      styles: const PosStyles(bold: false, align: PosAlign.center),
    );

    bytes += generator.feed(3);

    // Auto cut for 80mm paper
    if (paperSizeMm == '80') {
      bytes += generator.cut();
    }

    return bytes;
  }

  /// Print test receipt to verify printer connection
  Future<List<int>> printTest({
    PaperSize paperSize = PaperSize.mm58,
    String paperSizeMm = '58',
  }) async {
    List<int> bytes = [];

    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);

    // Get laundry info from settings
    final laundryInfo = await _getLaundryInfo();

    final String separator = paperSizeMm == '80'
        ? '------------------------------------------------'
        : '--------------------------------';

    bytes += generator.reset();

    // Header
    bytes += generator.text(
      laundryInfo['name'] ?? 'Laundry',
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );

    bytes += generator.text(
      separator,
      styles: const PosStyles(bold: false, align: PosAlign.center),
    );

    bytes += generator.text(
      'TEST PRINT',
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.text(
      separator,
      styles: const PosStyles(bold: false, align: PosAlign.center),
    );

    bytes += generator.text(
      'Printer terhubung dengan baik!',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.text(
      'Ukuran kertas: ${paperSizeMm}mm',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.text(
      separator,
      styles: const PosStyles(bold: false, align: PosAlign.center),
    );

    bytes += generator.text(
      DateFormatter.formatDateTime(DateTime.now()),
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(3);

    if (paperSizeMm == '80') {
      bytes += generator.cut();
    }

    return bytes;
  }
}
