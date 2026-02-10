import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/core/services/printer_service.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/printer/printer_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/printer/printer_state.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissionsAndLoad();
  }

  Future<void> _requestPermissionsAndLoad() async {
    // Request Bluetooth permissions
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    if (mounted) {
      context.read<PrinterCubit>().loadDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: BlocConsumer<PrinterCubit, PrinterState>(
              listener: (context, state) {
                if (state is PrinterConnected) {
                  _showSnackBar('Berhasil terhubung ke ${state.deviceName}', isSuccess: true);
                } else if (state is PrinterDisconnected) {
                  _showSnackBar('Printer terputus', isSuccess: true);
                } else if (state is PrinterPrintSuccess) {
                  _showSnackBar(state.message, isSuccess: true);
                } else if (state is PrinterError) {
                  _showSnackBar(state.message, isSuccess: false);
                }
              },
              builder: (context, state) {
                if (state is PrinterLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppThemeColors.primary),
                        SizedBox(height: AppSpacing.md),
                        Text('Mencari printer...'),
                      ],
                    ),
                  );
                }

                if (state is PrinterDevicesLoaded) {
                  return _buildContent(context, state);
                }

                if (state is PrinterConnecting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppThemeColors.primary),
                        const SizedBox(height: AppSpacing.md),
                        Text('Menghubungkan ke ${state.deviceName}...'),
                      ],
                    ),
                  );
                }

                if (state is PrinterPrinting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppThemeColors.primary),
                        SizedBox(height: AppSpacing.md),
                        Text('Mencetak...'),
                      ],
                    ),
                  );
                }

                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppThemeColors.success : AppThemeColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppThemeColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelola Printer',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hubungkan printer Bluetooth',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              GestureDetector(
                onTap: () => context.read<PrinterCubit>().loadDevices(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PrinterDevicesLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bluetooth Status
          _buildBluetoothStatus(state.bluetoothEnabled),
          const SizedBox(height: AppSpacing.lg),

          // Paper Size Setting
          _buildPaperSizeSection(context, state.paperSize),
          const SizedBox(height: AppSpacing.lg),

          // Connected Printer
          if (state.connectedDevice != null) ...[
            _buildConnectedPrinter(context, state.connectedDevice!),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Available Devices
          _buildDevicesList(context, state),
        ],
      ),
    );
  }

  Widget _buildBluetoothStatus(bool isEnabled) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isEnabled
            ? AppThemeColors.success.withValues(alpha: 0.1)
            : AppThemeColors.error.withValues(alpha: 0.1),
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: isEnabled
              ? AppThemeColors.success.withValues(alpha: 0.3)
              : AppThemeColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: isEnabled ? AppThemeColors.success : AppThemeColors.error,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnabled ? 'Bluetooth Aktif' : 'Bluetooth Nonaktif',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? AppThemeColors.success : AppThemeColors.error,
                  ),
                ),
                Text(
                  isEnabled
                      ? 'Siap mencari printer'
                      : 'Aktifkan Bluetooth untuk mencari printer',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppThemeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperSizeSection(BuildContext context, String currentSize) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten, color: AppThemeColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Ukuran Kertas',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _buildPaperSizeOption(context, '58', '58mm', currentSize)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildPaperSizeOption(context, '80', '80mm', currentSize)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaperSizeOption(
    BuildContext context,
    String size,
    String label,
    String currentSize,
  ) {
    final isSelected = currentSize == size;
    return GestureDetector(
      onTap: () => context.read<PrinterCubit>().setPaperSize(size),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: isSelected ? AppThemeColors.primaryGradient : null,
          color: isSelected ? null : AppThemeColors.background,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(
            color: isSelected ? AppThemeColors.primary : AppThemeColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              color: isSelected ? Colors.white : AppThemeColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppThemeColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedPrinter(BuildContext context, BluetoothDevice device) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppThemeColors.success, width: 2),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppThemeColors.success,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: const Icon(Icons.print, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppThemeColors.success,
                      ),
                    ),
                    Text(
                      device.address,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppThemeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppThemeColors.success.withValues(alpha: 0.1),
                  borderRadius: AppRadius.fullRadius,
                ),
                child: Text(
                  'Terhubung',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppThemeColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.read<PrinterCubit>().disconnectDevice(),
                  icon: const Icon(Icons.link_off, size: 18),
                  label: const Text('Putuskan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppThemeColors.error,
                    side: const BorderSide(color: AppThemeColors.error),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.read<PrinterCubit>().printTest(),
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Test Print'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesList(BuildContext context, PrinterDevicesLoaded state) {
    final availableDevices = state.devices
        .where((d) => state.connectedDevice == null || d.address != state.connectedDevice!.address)
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.devices, color: AppThemeColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Perangkat Tersedia',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${availableDevices.length} ditemukan',
                style: AppTypography.bodySmall.copyWith(
                  color: AppThemeColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (availableDevices.isEmpty)
            _buildNoDevicesFound()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availableDevices.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final device = availableDevices[index];
                return _buildDeviceItem(context, device);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(BuildContext context, BluetoothDevice device) {
    return InkWell(
      onTap: () => context.read<PrinterCubit>().connectDevice(device),
      borderRadius: AppRadius.mdRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppThemeColors.background,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: AppThemeColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppThemeColors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.smRadius,
              ),
              child: Icon(Icons.print, color: AppThemeColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    device.address,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppThemeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppThemeColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDevicesFound() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.print_disabled,
            size: 48,
            color: AppThemeColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tidak ada printer ditemukan',
            style: AppTypography.bodyMedium.copyWith(
              color: AppThemeColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pastikan printer sudah di-pair di Bluetooth',
            style: AppTypography.bodySmall.copyWith(
              color: AppThemeColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.print_disabled,
              size: 80,
              color: AppThemeColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Belum ada printer',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap tombol refresh untuk mencari printer',
              style: AppTypography.bodyMedium.copyWith(
                color: AppThemeColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
