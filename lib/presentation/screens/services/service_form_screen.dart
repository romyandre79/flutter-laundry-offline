import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/core/utils/thousand_separator_formatter.dart';
import 'package:kreatif_laundry_offline_app/data/models/service.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/service/service_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/service/service_state.dart';

class ServiceFormScreen extends StatefulWidget {
  final Service? service;

  const ServiceFormScreen({super.key, this.service});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  ServiceUnit _selectedUnit = ServiceUnit.kg;
  bool _isLoading = false;

  bool get isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _priceController.text = ThousandSeparatorFormatter.format(widget.service!.price);
      _durationController.text = widget.service!.durationDays.toString();
      _selectedUnit = widget.service!.unit;
    } else {
      _durationController.text = '3'; // Default 3 days
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final service = Service(
        id: widget.service?.id,
        name: _nameController.text.trim(),
        unit: _selectedUnit,
        price: ThousandSeparatorFormatter.parseToInt(_priceController.text),
        durationDays: int.parse(_durationController.text),
        isActive: true,
      );

      if (isEditing) {
        context.read<ServiceCubit>().updateService(service);
      } else {
        context.read<ServiceCubit>().addService(service);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServiceCubit, ServiceState>(
      listener: (context, state) {
        if (state is ServiceLoading) {
          setState(() => _isLoading = true);
        } else {
          setState(() => _isLoading = false);
        }

        if (state is ServiceOperationSuccess) {
          Navigator.pop(context);
        } else if (state is ServiceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppThemeColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdRadius,
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppThemeColors.background,
        body: Column(
          children: [
            // Header
            _buildHeader(),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Service Icon
                      _buildServiceIcon(),

                      const SizedBox(height: AppSpacing.xl),

                      // Form Card
                      _buildFormCard(),

                      const SizedBox(height: AppSpacing.lg),

                      // Info Card
                      _buildInfoCard(),

                      const SizedBox(height: AppSpacing.xl),

                      // Save Button
                      _buildSaveButton(),

                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppThemeColors.headerGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit Layanan' : 'Tambah Layanan',
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isEditing
                          ? 'Perbarui detail layanan'
                          : 'Buat layanan baru',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceIcon() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: AppThemeColors.primaryGradient,
          borderRadius: AppRadius.lgRadius,
          boxShadow: [
            BoxShadow(
              color: AppThemeColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.local_laundry_service,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppThemeColors.primaryGradient,
                  borderRadius: AppRadius.fullRadius,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Detail Layanan',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Name Field
          _buildInputLabel('Nama Layanan', isRequired: true),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _nameController,
            style: AppTypography.bodyMedium,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _buildInputDecoration(
              hintText: 'Contoh: Cuci Setrika',
              prefixIcon: Icons.local_laundry_service,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama layanan tidak boleh kosong';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Unit Selection
          _buildInputLabel('Satuan', isRequired: true),
          const SizedBox(height: AppSpacing.sm),
          _buildUnitSelector(),

          const SizedBox(height: AppSpacing.lg),

          // Price Field
          _buildInputLabel('Harga', isRequired: true),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _priceController,
            style: AppTypography.bodyMedium,
            keyboardType: TextInputType.number,
            inputFormatters: [
              ThousandSeparatorFormatter(),
            ],
            textInputAction: TextInputAction.next,
            decoration: _buildInputDecoration(
              hintText: 'Contoh: 10.000',
              prefixIcon: Icons.payments_outlined,
              prefixText: 'Rp ',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Harga tidak boleh kosong';
              }
              final price = ThousandSeparatorFormatter.parseToInt(value);
              if (price <= 0) {
                return 'Harga harus lebih dari 0';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Duration Field
          _buildInputLabel('Durasi Pengerjaan', isRequired: true),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _durationController,
            style: AppTypography.bodyMedium,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            textInputAction: TextInputAction.done,
            decoration: _buildInputDecoration(
              hintText: 'Contoh: 3',
              prefixIcon: Icons.schedule,
              suffixText: 'hari',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Durasi tidak boleh kosong';
              }
              final duration = int.tryParse(value);
              if (duration == null || duration <= 0) {
                return 'Durasi harus lebih dari 0';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppThemeColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: AppTypography.labelMedium.copyWith(
              color: AppThemeColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppThemeColors.textHint,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: AppThemeColors.primary,
      ),
      prefixText: prefixText,
      prefixStyle: AppTypography.bodyMedium.copyWith(
        color: AppThemeColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      suffixText: suffixText,
      suffixStyle: AppTypography.bodyMedium.copyWith(
        color: AppThemeColors.textSecondary,
      ),
      filled: true,
      fillColor: AppThemeColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: const BorderSide(
          color: AppThemeColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: const BorderSide(
          color: AppThemeColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: const BorderSide(
          color: AppThemeColors.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: const BorderSide(
          color: AppThemeColors.error,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
    );
  }

  Widget _buildUnitSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildUnitOption(
            unit: ServiceUnit.kg,
            label: 'Kilogram',
            sublabel: 'per kg',
            icon: Icons.scale,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildUnitOption(
            unit: ServiceUnit.pcs,
            label: 'Per Item',
            sublabel: 'per pcs',
            icon: Icons.checkroom,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitOption({
    required ServiceUnit unit,
    required String label,
    required String sublabel,
    required IconData icon,
  }) {
    final isSelected = _selectedUnit == unit;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUnit = unit;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppThemeColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(
            color: isSelected ? AppThemeColors.primary : AppThemeColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppThemeColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isSelected ? AppThemeColors.primaryGradient : null,
                color: isSelected ? null : AppThemeColors.background,
                borderRadius: AppRadius.mdRadius,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppThemeColors.textHint,
                size: 24,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Label
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? AppThemeColors.primary
                    : AppThemeColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),

            // Sublabel
            Text(
              sublabel,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? AppThemeColors.primary.withValues(alpha: 0.7)
                    : AppThemeColors.textHint,
              ),
            ),

            // Check icon
            if (isSelected) ...[
              const SizedBox(height: AppSpacing.xs),
              const Icon(
                Icons.check_circle,
                color: AppThemeColors.primary,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppThemeColors.primarySurface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: AppThemeColors.primary.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppThemeColors.primary.withValues(alpha: 0.15),
              borderRadius: AppRadius.mdRadius,
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppThemeColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Durasi Pengerjaan',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppThemeColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Durasi akan digunakan untuk menghitung tanggal ambil default pada order.',
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

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppThemeColors.primaryGradient,
        borderRadius: AppRadius.mdRadius,
        boxShadow: AppShadows.purple,
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdRadius,
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEditing ? Icons.save : Icons.add,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isEditing ? 'Simpan Perubahan' : 'Tambah Layanan',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
