import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';
import 'package:kreatif_laundry_offline_app/core/services/laundry_print.dart';
import 'package:kreatif_laundry_offline_app/core/services/pdf_service.dart';

class BluetoothDevice {
  final String name;
  final String address;

  BluetoothDevice({required this.name, required this.address});
}

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  // SharedPreferences keys
  static const String _keyPrinterMac = 'printer_mac';
  static const String _keyPrinterName = 'printer_name';
  static const String _keyPaperSize = 'paper_size';

  String? _connectedAddress;
  String? _connectedName;
  String _paperSize = '58'; // default 58mm

  bool get isConnected => _connectedAddress != null;
  String? get connectedDeviceName => _connectedName;
  String? get connectedDeviceAddress => _connectedAddress;
  String get paperSize => _paperSize;

  /// Initialize printer service - load saved settings
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _connectedAddress = prefs.getString(_keyPrinterMac);
    _connectedName = prefs.getString(_keyPrinterName);
    _paperSize = prefs.getString(_keyPaperSize) ?? '58';

    // Try to reconnect to saved printer
    if (_connectedAddress != null && _connectedAddress!.isNotEmpty) {
      if (!Platform.isWindows) {
        await connect(BluetoothDevice(
          name: _connectedName ?? 'Unknown',
          address: _connectedAddress!,
        ));
      }
    }
  }

  /// Check if Bluetooth is available
  Future<bool> isBluetoothAvailable() async {
    if (Platform.isWindows) return false;
    final isAvailable = await PrintBluetoothThermal.bluetoothEnabled;
    return isAvailable;
  }

  /// Get paired devices
  Future<List<BluetoothDevice>> getPairedDevices() async {
    if (Platform.isWindows) return [];
    final List<BluetoothInfo> devices =
        await PrintBluetoothThermal.pairedBluetooths;
    return devices
        .map((d) => BluetoothDevice(name: d.name, address: d.macAdress))
        .toList();
  }

  /// Connect to device
  Future<bool> connect(BluetoothDevice device) async {
    if (Platform.isWindows) return false;
    try {
      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.address,
      );
      if (result) {
        _connectedAddress = device.address;
        _connectedName = device.name;

        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyPrinterMac, device.address);
        await prefs.setString(_keyPrinterName, device.name);
      }
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    if (Platform.isWindows) return;
    await PrintBluetoothThermal.disconnect;
    _connectedAddress = null;
    _connectedName = null;

    // Clear saved printer
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrinterMac);
    await prefs.remove(_keyPrinterName);
  }

  /// Check connection status
  Future<bool> checkConnection() async {
    if (Platform.isWindows) return false;
    if (_connectedAddress == null) {
      // Try to load from saved preferences
      final prefs = await SharedPreferences.getInstance();
      _connectedAddress = prefs.getString(_keyPrinterMac);
      _connectedName = prefs.getString(_keyPrinterName);
      if (_connectedAddress == null) return false;
    }

    final status = await PrintBluetoothThermal.connectionStatus;
    return status;
  }

  /// Get saved printer info
  Future<Map<String, String?>> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'mac': prefs.getString(_keyPrinterMac),
      'name': prefs.getString(_keyPrinterName),
    };
  }

  /// Try to reconnect to saved printer
  Future<bool> reconnectSavedPrinter() async {
    if (Platform.isWindows) return false;
    final prefs = await SharedPreferences.getInstance();
    final savedMac = prefs.getString(_keyPrinterMac);
    final savedName = prefs.getString(_keyPrinterName);

    if (savedMac == null || savedMac.isEmpty) return false;

    // Check if already connected
    final currentStatus = await PrintBluetoothThermal.connectionStatus;
    if (currentStatus) {
      _connectedAddress = savedMac;
      _connectedName = savedName;
      return true;
    }

    // Try to connect
    return await connect(BluetoothDevice(
      name: savedName ?? 'Printer',
      address: savedMac,
    ));
  }

  /// Set paper size ('58' or '80')
  Future<void> setPaperSize(String size) async {
    _paperSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPaperSize, size);
  }

  /// Get saved paper size
  Future<String> getSavedPaperSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPaperSize) ?? '58';
  }

  /// Get PaperSize enum from string
  PaperSize getPaperSizeEnum() {
    return _paperSize == '80' ? PaperSize.mm80 : PaperSize.mm58;
  }

  /// Ensure printer is connected, try to reconnect if needed
  Future<bool> ensureConnected() async {
    if (Platform.isWindows) return false;
    // Load saved paper size
    final prefs = await SharedPreferences.getInstance();
    _paperSize = prefs.getString(_keyPaperSize) ?? '58';

    // Check current connection
    if (await checkConnection()) {
      return true;
    }

    // Try to reconnect to saved printer
    return await reconnectSavedPrinter();
  }

  /// Print order receipt
  Future<bool> printReceipt(Order order) async {
    if (Platform.isWindows) {
      // Use PDF Printing on Windows
      await PdfService.instance.printOrderReceipt(order);
      return true;
    }
    if (!await ensureConnected()) {
      throw Exception('Printer tidak terhubung. Silakan hubungkan printer di Settings.');
    }

    try {
      final bytes = await LaundryPrint.instance.printOrderReceipt(
        order,
        paperSize: getPaperSizeEnum(),
        paperSizeMm: _paperSize,
      );
      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      throw Exception('Gagal mencetak: ${e.toString()}');
    }
  }

  /// Print test page
  Future<bool> printTest() async {
    if (Platform.isWindows) {
      throw Exception('Printing is not supported on Windows yet.');
    }
    if (!await ensureConnected()) {
      throw Exception('Printer tidak terhubung. Silakan hubungkan printer di Settings.');
    }

    try {
      final bytes = await LaundryPrint.instance.printTest(
        paperSize: getPaperSizeEnum(),
        paperSizeMm: _paperSize,
      );
      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      throw Exception('Gagal mencetak: ${e.toString()}');
    }
  }
}
