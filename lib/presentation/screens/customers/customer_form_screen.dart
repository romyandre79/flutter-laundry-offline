import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/data/models/customer.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/customer/customer_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/customer/customer_state.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _defaultDiscountController = TextEditingController();

  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone ?? '';
      _addressController.text = widget.customer!.address ?? '';
      _notesController.text = widget.customer!.notes ?? '';
      _defaultDiscountController.text = widget.customer!.defaultDiscount.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _defaultDiscountController.dispose();
    super.dispose();
  }

  void _saveCustomer() {
    if (!_formKey.currentState!.validate()) return;

    final customer = Customer(
      id: widget.customer?.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      defaultDiscount: double.tryParse(_defaultDiscountController.text) ?? 0,
      totalOrders: widget.customer?.totalOrders ?? 0,
      totalSpent: widget.customer?.totalSpent ?? 0,
      createdAt: widget.customer?.createdAt,
      updatedAt: widget.customer?.updatedAt,
    );

    if (isEditing) {
      context.read<CustomerCubit>().updateCustomer(customer);
    } else {
      context.read<CustomerCubit>().createCustomer(customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerCubit, CustomerState>(
      listener: (context, state) {
        if (state is CustomerOperationSuccess) {
          Navigator.pop(context);
        } else if (state is CustomerError) {
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
                      // Customer Avatar
                      _buildCustomerAvatar(),

                      const SizedBox(height: AppSpacing.xl),

                      // Form Card
                      _buildFormCard(),

                      const SizedBox(height: AppSpacing.lg),

                      // Discount Card
                      _buildDiscountCard(),

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
                      isEditing ? 'Edit Pelanggan' : 'Tambah Pelanggan',
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isEditing
                          ? 'Perbarui data pelanggan'
                          : 'Daftarkan pelanggan baru',
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

  Widget _buildCustomerAvatar() {
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
          Icons.person,
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
                'Informasi Pelanggan',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Name Field
          _buildInputLabel('Nama Pelanggan', isRequired: true),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _nameController,
            style: AppTypography.bodyMedium,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _buildInputDecoration(
              hintText: 'Masukkan nama pelanggan',
              prefixIcon: Icons.person_outline,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama pelanggan wajib diisi';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Phone Field
          _buildInputLabel('Nomor HP'),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _phoneController,
            style: AppTypography.bodyMedium,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: _buildInputDecoration(
              hintText: 'Contoh: 08123456789',
              prefixIcon: Icons.phone_outlined,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Address Field
          _buildInputLabel('Alamat'),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _addressController,
            style: AppTypography.bodyMedium,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: _buildInputDecoration(
              hintText: 'Masukkan alamat pelanggan',
              prefixIcon: Icons.location_on_outlined,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Notes Field
          _buildInputLabel('Catatan'),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _notesController,
            style: AppTypography.bodyMedium,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: _buildInputDecoration(
              hintText: 'Catatan tambahan (opsional)',
              prefixIcon: Icons.note_outlined,
            ),
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
                  'Pelanggan Loyal',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppThemeColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pelanggan dengan 5+ order akan ditandai sebagai pelanggan loyal',
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
    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, state) {
        final isLoading = state is CustomerLoading;

        return Container(
          decoration: BoxDecoration(
            gradient: AppThemeColors.primaryGradient,
            borderRadius: AppRadius.mdRadius,
            boxShadow: AppShadows.purple,
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : _saveCustomer,
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
            child: isLoading
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
                        isEditing ? Icons.save : Icons.person_add,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        isEditing ? 'Simpan Perubahan' : 'Tambah Pelanggan',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
