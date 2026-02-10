import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kreatif_laundry_offline_app/core/utils/currency_formatter.dart';
import 'package:kreatif_laundry_offline_app/core/utils/date_formatter.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';
import 'package:kreatif_laundry_offline_app/data/repositories/settings_repository.dart';
import 'package:kreatif_laundry_offline_app/core/constants/app_constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  static PdfService get instance => _instance;
  factory PdfService() => _instance;
  PdfService._internal();

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

  /// Print order receipt (thermal printer format)
  Future<void> printOrderReceipt(Order order) async {
    final pdf = pw.Document();
    final laundryInfo = await _getLaundryInfo();
    
    // Thermal printer roll width (58mm or 80mm) -> approx 164 points for 58mm
    // varying page format to fit content
    final pageFormat = PdfPageFormat.roll57;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(child: pw.Text(laundryInfo['name']!, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
              pw.Center(child: pw.Text(laundryInfo['address']!, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
              pw.Center(child: pw.Text('Tel: ${laundryInfo['phone']!}', style: const pw.TextStyle(fontSize: 8))),
              pw.Divider(thickness: 0.5),

              // Order Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No: ${order.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                  pw.Text(DateFormat('dd/MM/yy HH:mm').format(order.createdAt!), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Text('Pelanggan: ${order.customerName}', style: const pw.TextStyle(fontSize: 8)),
              if (order.customerPhone != null)
                pw.Text('HP: ${order.customerPhone}', style: const pw.TextStyle(fontSize: 8)),
              pw.Divider(thickness: 0.5),

              // Items
              ...(order.items ?? []).map((item) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.serviceName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('${item.quantity} ${item.unit} x ${CurrencyFormatter.formatNoSymbol(item.pricePerUnit)}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(CurrencyFormatter.formatNoSymbol(item.subtotal), style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                  ],
                );
              }),
              pw.Divider(thickness: 0.5),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(CurrencyFormatter.format(order.totalAmount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
              if (order.paidAmount > 0) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Bayar', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(CurrencyFormatter.format(order.paidAmount), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(order.remainingPayment > 0 ? 'Kurang' : 'Kembali', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(CurrencyFormatter.format(order.remainingPayment > 0 ? order.remainingPayment : (order.paidAmount - order.totalAmount)), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
              
              pw.Divider(thickness: 0.5),
              
              // Barcode
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: order.invoiceNumber,
                  width: 100,
                  height: 30,
                  drawText: false,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(child: pw.Text(order.invoiceNumber, style: const pw.TextStyle(fontSize: 6))),

              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('Terima Kasih', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${order.invoiceNumber}',
    );
  }

  /// Print item labels (sticker format)
  /// One page per item unit/quantity? Or just one generic tag per item line?
  /// Assuming one label per physical package (based on quantity if piece, or just 1 if bulk?)
  /// For now: 1 label per Order Item type usually, or ask user?
  /// Let's generate 1 label per order for the main bag, or loop items.
  /// Let's implement: "Print All Labels" -> generates labels for number of items.
  Future<void> printItemLabels(Order order) async {
    final pdf = pw.Document();
    final laundryInfo = await _getLaundryInfo();
    
    // Label size: e.g., 50mm x 30mm standard address label
    // or standard thermal sticker format
    final pageFormat = PdfPageFormat(50 * PdfPageFormat.mm, 30 * PdfPageFormat.mm);

    for (var item in (order.items ?? [])) {
      // Loop quantity if "pcs"? Or just 1 label per line item?
      // Usually laundry tags are per piece if "pcs".
      // Let's generate 1 label per line item for now to avoid spam, 
      // or maybe loop if unit is "pcs".
      // Safety: just 1 label per line item for now.
      
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(laundryInfo['name']!, style: const pw.TextStyle(fontSize: 6)),
                  pw.Text('${order.customerName} (${order.invoiceNumber})', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                  pw.Text(item.serviceName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Spacer(),
                   pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                       pw.Text('${item.quantity} ${item.unit}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                       pw.Text(DateFormat('dd/MM').format(order.createdAt!), style: const pw.TextStyle(fontSize: 6)),
                    ]
                  ),
                  pw.Divider(thickness: 0.5, height: 2),
                  pw.Center(
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data: order.invoiceNumber,
                      height: 15,
                      width: 80,
                      drawText: false,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Labels_${order.invoiceNumber}',
    );
  }
}
