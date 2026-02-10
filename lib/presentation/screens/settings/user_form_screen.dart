import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/data/models/user.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/user/user_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/user/user_state.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.kasir;
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _usernameController.text = widget.user!.username;
      _nameController.text = widget.user!.name;
      _selectedRole = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      if (isEditing) {
        context.read<UserCubit>().updateUser(
              id: widget.user!.id!,
              name: _nameController.text,
              role: _selectedRole,
            );
      } else {
        context.read<UserCubit>().createUser(
              username: _usernameController.text,
              password: _passwordController.text,
              name: _nameController.text,
              role: _selectedRole,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state is UserLoading) {
          setState(() => _isLoading = true);
        } else {
          setState(() => _isLoading = false);
        }

        if (state is UserOperationSuccess) {
          Navigator.pop(context);
        } else if (state is UserError) {
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
                      // User Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: _selectedRole == UserRole.owner
                                ? AppThemeColors.primaryGradient
                                : const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF9575CD), // Light purple
                                      Color(0xFF7E57C2), // Purple
                                    ],
                                  ),
                            borderRadius: AppRadius.lgRadius,
                            boxShadow: [
                              BoxShadow(
                                color: (_selectedRole == UserRole.owner
                                        ? AppThemeColors.primary
                                        : const Color(0xFF7E57C2))
                                    .withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _selectedRole == UserRole.owner
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Form Card
                      Container(
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
                                  'Informasi User',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            // Username Field
                            _buildInputLabel('Username'),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _usernameController,
                              style: AppTypography.bodyMedium,
                              enabled: !isEditing,
                              textInputAction: TextInputAction.next,
                              decoration: _buildInputDecoration(
                                hintText: 'Masukkan username',
                                prefixIcon: Icons.person_outline,
                                enabled: !isEditing,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Username tidak boleh kosong';
                                }
                                if (value.length < 3) {
                                  return 'Username minimal 3 karakter';
                                }
                                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                                  return 'Username hanya boleh huruf, angka, dan underscore';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            // Name Field
                            _buildInputLabel('Nama Lengkap'),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _nameController,
                              style: AppTypography.bodyMedium,
                              textInputAction: TextInputAction.next,
                              decoration: _buildInputDecoration(
                                hintText: 'Masukkan nama lengkap',
                                prefixIcon: Icons.badge_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nama tidak boleh kosong';
                                }
                                return null;
                              },
                            ),

                            // Password Field (only for new user)
                            if (!isEditing) ...[
                              const SizedBox(height: AppSpacing.lg),
                              _buildInputLabel('Password'),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: AppTypography.bodyMedium,
                                textInputAction: TextInputAction.done,
                                decoration: _buildInputDecoration(
                                  hintText: 'Masukkan password',
                                  prefixIcon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: AppThemeColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password tidak boleh kosong';
                                  }
                                  if (value.length < 6) {
                                    return 'Password minimal 6 karakter';
                                  }
                                  return null;
                                },
                              ),
                            ],

                            const SizedBox(height: AppSpacing.lg),

                            // Role Selection
                            _buildInputLabel('Role'),
                            const SizedBox(height: AppSpacing.sm),
                            _buildRoleSelector(),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Permissions Card
                      _buildPermissionsCard(),

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
                      isEditing ? 'Edit User' : 'Tambah User',
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isEditing
                          ? 'Perbarui informasi user'
                          : 'Buat akun user baru',
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

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: AppTypography.labelMedium.copyWith(
        color: AppThemeColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppThemeColors.textHint,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: enabled ? AppThemeColors.primary : AppThemeColors.textHint,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: enabled ? AppThemeColors.inputFill : AppThemeColors.background,
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
      disabledBorder: OutlineInputBorder(
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

  // Secondary purple color for Kasir role
  static const Color _kasirColor = Color(0xFF7E57C2);

  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildRoleOption(
            role: UserRole.kasir,
            icon: Icons.person,
            color: _kasirColor,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildRoleOption(
            role: UserRole.owner,
            icon: Icons.admin_panel_settings,
            color: AppThemeColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required UserRole role,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(
            color: isSelected ? color : AppThemeColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
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
                gradient: isSelected
                    ? (role == UserRole.owner
                        ? AppThemeColors.primaryGradient
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF9575CD),
                              Color(0xFF7E57C2),
                            ],
                          ))
                    : null,
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

            // Role Name
            Text(
              role.displayName,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? color : AppThemeColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),

            // Check icon
            if (isSelected) ...[
              const SizedBox(height: AppSpacing.xs),
              Icon(
                Icons.check_circle,
                color: color,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard() {
    final isOwner = _selectedRole == UserRole.owner;
    final permissions = isOwner
        ? [
            _PermissionItem('Dashboard', 'Full access', true),
            _PermissionItem('Orders', 'Full CRUD', true),
            _PermissionItem('Services', 'Full CRUD', true),
            _PermissionItem('Customers', 'Full + Export', true),
            _PermissionItem('Reports', 'Full + Export', true),
            _PermissionItem('Settings', 'Full access', true),
            _PermissionItem('User Management', 'Full CRUD', true),
          ]
        : [
            _PermissionItem('Dashboard', 'View only', true),
            _PermissionItem('Orders', 'Create, View, Update', true),
            _PermissionItem('Services', 'View only', true),
            _PermissionItem('Customers', 'View only', true),
            _PermissionItem('Reports', 'Tidak bisa akses', false),
            _PermissionItem('Settings', 'Tidak bisa akses', false),
            _PermissionItem('User Management', 'Tidak bisa akses', false),
          ];

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
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppThemeColors.primarySurface,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: const Icon(
                  Icons.security,
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
                      'Hak Akses ${_selectedRole.displayName}',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isOwner
                          ? 'Akses penuh ke semua fitur'
                          : 'Akses terbatas untuk operasional',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppThemeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Permissions List
          ...permissions.map((permission) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: (permission.allowed
                                ? AppThemeColors.success
                                : AppThemeColors.error)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        permission.allowed ? Icons.check : Icons.close,
                        size: 14,
                        color: permission.allowed
                            ? AppThemeColors.success
                            : AppThemeColors.error,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        permission.feature,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      permission.access,
                      style: AppTypography.bodySmall.copyWith(
                        color: permission.allowed
                            ? AppThemeColors.textSecondary
                            : AppThemeColors.error,
                      ),
                    ),
                  ],
                ),
              )),
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
                    isEditing ? Icons.save : Icons.person_add,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isEditing ? 'Simpan Perubahan' : 'Tambah User',
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

class _PermissionItem {
  final String feature;
  final String access;
  final bool allowed;

  _PermissionItem(this.feature, this.access, this.allowed);
}
