class AppConstants {
  AppConstants._();

  // Demo Mode
  static const bool isDemo = true;

  // App Info
  static const String appName = 'Kreatif Laundry';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Aplikasi Kasir Kreatif Laundry UMKM Indonesia - Full Offline, Jalan Tanpa Internet!';

  // Database
  static const String databaseName = 'laundryfull.db';
  static const int databaseVersion = 3;

  // Invoice
  static const String defaultInvoicePrefix = 'LNDR';
  static const int invoiceNumberLength = 4;

  // Default Values
  static const int defaultServiceDuration = 3; // days
  static const String defaultPaymentMethod = 'cash';

  // Pagination
  static const int defaultPageSize = 20;
  static const int recentOrdersLimit = 5;

  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy HH:mm';
  static const String dateFormatShort = 'dd/MM/yy';
  static const String timeFormat = 'HH:mm';
  static const String invoiceDateFormat = 'yyMMdd';

  // Printer
  static const int printerPaperWidth = 58; // mm
  static const int printerCharPerLine = 32;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 20;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;

  // Default Admin Credentials
  static const String defaultOwnerUsername = 'owner';
  static const String defaultOwnerPassword = 'admin123';
  static const String defaultOwnerName = 'Owner Laundry';

  // Settings Keys
  static const String keyLaundryName = 'laundry_name';
  static const String keyLaundryAddress = 'laundry_address';
  static const String keyLaundryPhone = 'laundry_phone';
  static const String keyInvoicePrefix = 'invoice_prefix';
  static const String keyPrinterAddress = 'printer_address';
  static const String keyLastInvoiceDate = 'last_invoice_date';
  static const String keyLastInvoiceNumber = 'last_invoice_number';
  static const String keyFonnteToken = 'fonnte_token';

  // Default Laundry Info
  static const String defaultLaundryName = 'Kreatif Laundry';
  static const String defaultLaundryAddress = 'Jalan Mrutu Kalianyar 1C Surabaya';
  static const String defaultLaundryPhone = '6281932701147';
  static const String defaultFonnteToken = '000';
}
