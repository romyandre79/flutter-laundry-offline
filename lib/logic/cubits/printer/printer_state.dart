import 'package:equatable/equatable.dart';
import 'package:kreatif_laundry_offline_app/core/services/printer_service.dart';

abstract class PrinterState extends Equatable {
  const PrinterState();

  @override
  List<Object?> get props => [];
}

class PrinterInitial extends PrinterState {
  const PrinterInitial();
}

class PrinterLoading extends PrinterState {
  const PrinterLoading();
}

class PrinterBluetoothOff extends PrinterState {
  const PrinterBluetoothOff();
}

class PrinterDevicesLoaded extends PrinterState {
  final List<BluetoothDevice> devices;
  final BluetoothDevice? connectedDevice;
  final String paperSize;
  final bool bluetoothEnabled;
  final String? savedPrinterMac;

  const PrinterDevicesLoaded({
    required this.devices,
    this.connectedDevice,
    this.paperSize = '58',
    this.bluetoothEnabled = true,
    this.savedPrinterMac,
  });

  @override
  List<Object?> get props => [devices, connectedDevice, paperSize, bluetoothEnabled, savedPrinterMac];
}

class PrinterConnecting extends PrinterState {
  final String deviceName;

  const PrinterConnecting(this.deviceName);

  @override
  List<Object?> get props => [deviceName];
}

class PrinterConnected extends PrinterState {
  final String deviceName;

  const PrinterConnected(this.deviceName);

  @override
  List<Object?> get props => [deviceName];
}

class PrinterDisconnected extends PrinterState {
  const PrinterDisconnected();
}

class PrinterPrinting extends PrinterState {
  const PrinterPrinting();
}

class PrinterPrintSuccess extends PrinterState {
  final String message;

  const PrinterPrintSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PrinterError extends PrinterState {
  final String message;

  const PrinterError(this.message);

  @override
  List<Object?> get props => [message];
}
