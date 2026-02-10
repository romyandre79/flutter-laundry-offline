import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';
import 'package:kreatif_laundry_offline_app/core/utils/currency_formatter.dart';
import 'package:kreatif_laundry_offline_app/core/utils/date_formatter.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/report/report_state.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Export orders to Excel
  Future<String> exportOrdersToExcel(
    List<Order> orders,
    ReportData reportData,
  ) async {
    final excel = Excel.createExcel();

    // Sheet 1: Summary
    _createSummarySheet(excel, reportData);

    // Sheet 2: Orders
    _createOrdersSheet(excel, orders);

    // Sheet 3: Service Summary
    _createServiceSummarySheet(excel, reportData);

    // Remove default sheet
    excel.delete('Sheet1');

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'Laporan_${DateFormatter.formatDateCompact(reportData.startDate)}_${DateFormatter.formatDateCompact(reportData.endDate)}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      return filePath;
    }

    throw Exception('Gagal membuat file Excel');
  }

  void _createSummarySheet(Excel excel, ReportData reportData) {
    final sheet = excel['Ringkasan'];

    // Title
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('LAPORAN LAUNDRY');
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        'Periode: ${DateFormatter.formatDate(reportData.startDate)} - ${DateFormatter.formatDate(reportData.endDate)}');

    // Summary data
    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Ringkasan');

    sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('Total Order');
    sheet.cell(CellIndex.indexByString('B6')).value = IntCellValue(reportData.totalOrders);

    sheet.cell(CellIndex.indexByString('A7')).value = TextCellValue('Order Selesai');
    sheet.cell(CellIndex.indexByString('B7')).value = IntCellValue(reportData.completedOrders);

    sheet.cell(CellIndex.indexByString('A8')).value = TextCellValue('Order Pending');
    sheet.cell(CellIndex.indexByString('B8')).value = IntCellValue(reportData.pendingOrders);

    sheet.cell(CellIndex.indexByString('A10')).value = TextCellValue('Total Omzet');
    sheet.cell(CellIndex.indexByString('B10')).value =
        TextCellValue(CurrencyFormatter.format(reportData.totalRevenue));

    sheet.cell(CellIndex.indexByString('A11')).value = TextCellValue('Total Dibayar');
    sheet.cell(CellIndex.indexByString('B11')).value =
        TextCellValue(CurrencyFormatter.format(reportData.totalPaid));

    sheet.cell(CellIndex.indexByString('A12')).value = TextCellValue('Total Belum Dibayar');
    sheet.cell(CellIndex.indexByString('B12')).value =
        TextCellValue(CurrencyFormatter.format(reportData.totalUnpaid));

    // Daily revenue
    sheet.cell(CellIndex.indexByString('A14')).value = TextCellValue('Pendapatan Harian');

    sheet.cell(CellIndex.indexByString('A15')).value = TextCellValue('Tanggal');
    sheet.cell(CellIndex.indexByString('B15')).value = TextCellValue('Jumlah Order');
    sheet.cell(CellIndex.indexByString('C15')).value = TextCellValue('Omzet');
    sheet.cell(CellIndex.indexByString('D15')).value = TextCellValue('Dibayar');

    int row = 16;
    for (final daily in reportData.dailyRevenue) {
      sheet.cell(CellIndex.indexByString('A$row')).value =
          TextCellValue(DateFormatter.formatDate(daily.date));
      sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(daily.orderCount);
      sheet.cell(CellIndex.indexByString('C$row')).value =
          TextCellValue(CurrencyFormatter.format(daily.revenue));
      sheet.cell(CellIndex.indexByString('D$row')).value =
          TextCellValue(CurrencyFormatter.format(daily.paid));
      row++;
    }
  }

  void _createOrdersSheet(Excel excel, List<Order> orders) {
    final sheet = excel['Daftar Order'];

    // Headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('No Invoice');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Tanggal');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Pelanggan');
    sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('No HP');
    sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Status');
    sheet.cell(CellIndex.indexByString('F1')).value = TextCellValue('Total');
    sheet.cell(CellIndex.indexByString('G1')).value = TextCellValue('Dibayar');
    sheet.cell(CellIndex.indexByString('H1')).value = TextCellValue('Kurang');

    int row = 2;
    for (final order in orders) {
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(order.invoiceNo);
      sheet.cell(CellIndex.indexByString('B$row')).value =
          TextCellValue(DateFormatter.formatDateTime(order.orderDate));
      sheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue(order.customerName);
      sheet.cell(CellIndex.indexByString('D$row')).value =
          TextCellValue(order.customerPhone ?? '-');
      sheet.cell(CellIndex.indexByString('E$row')).value =
          TextCellValue(order.status.displayName);
      sheet.cell(CellIndex.indexByString('F$row')).value =
          TextCellValue(CurrencyFormatter.format(order.totalPrice));
      sheet.cell(CellIndex.indexByString('G$row')).value =
          TextCellValue(CurrencyFormatter.format(order.paid));
      sheet.cell(CellIndex.indexByString('H$row')).value =
          TextCellValue(CurrencyFormatter.format(order.remainingPayment));
      row++;
    }
  }

  void _createServiceSummarySheet(Excel excel, ReportData reportData) {
    final sheet = excel['Layanan Populer'];

    // Headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Nama Layanan');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Jumlah Order');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Total Qty');
    sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Total Pendapatan');

    int row = 2;
    for (final service in reportData.topServices) {
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(service.serviceName);
      sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(service.orderCount);
      sheet.cell(CellIndex.indexByString('C$row')).value = IntCellValue(service.totalQuantity);
      sheet.cell(CellIndex.indexByString('D$row')).value =
          TextCellValue(CurrencyFormatter.format(service.totalRevenue));
      row++;
    }
  }

  /// Share exported file
  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Laporan Laundry',
    );
  }
}
