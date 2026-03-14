import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kreatif_laundry_offline_app/core/constants/app_constants.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/data/models/user.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/auth/auth_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/auth/auth_state.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/settings/settings_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/settings/settings_state.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/user/user_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/service/service_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/customer/customer_cubit.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/settings/user_management_screen.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/services/service_list_screen.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/customers/customer_list_screen.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/settings/printer_settings_screen.dart';
import 'package:kreatif_laundry_offline_app/data/services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsCubit _settingsCubit;

  @override
  void initState() {
    super.initState();
    _settingsCubit = SettingsCubit()..loadSettings();
  }

  @override
  void dispose() {
    _settingsCubit.close();
    super.dispose();
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.kasir:
        return 'Kasir';
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final authCubit = context.read<AuthCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        title: Text('Logout', style: AppTypography.titleLarge),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: AppTypography.labelMedium.copyWith(
                color: AppThemeColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              authCubit.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeColors.error,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
            ),
            child: Text(
              'Logout',
              style: AppTypography.labelMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        title: Text('Ubah Password', style: AppTypography.titleLarge),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                decoration: InputDecoration(
                  labelText: 'Password Lama',
                  labelStyle: AppTypography.bodyMedium,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppThemeColors.textSecondary,
                  ),
                  border: OutlineInputBorder(borderRadius: AppRadius.mdRadius),
                ),
                obscureText: true,
                validator: (v) =>
                    v?.isEmpty == true ? 'Password tidak boleh kosong' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: newController,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  labelStyle: AppTypography.bodyMedium,
                  prefixIcon: const Icon(
                    Icons.lock,
                    color: AppThemeColors.textSecondary,
                  ),
                  border: OutlineInputBorder(borderRadius: AppRadius.mdRadius),
                ),
                obscureText: true,
                validator: (v) {
                  if (v?.isEmpty == true) return 'Password tidak boleh kosong';
                  if (v!.length < 6) return 'Minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: confirmController,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  labelStyle: AppTypography.bodyMedium,
                  prefixIcon: const Icon(
                    Icons.lock,
                    color: AppThemeColors.textSecondary,
                  ),
                  border: OutlineInputBorder(borderRadius: AppRadius.mdRadius),
                ),
                obscureText: true,
                validator: (v) {
                  if (v != newController.text) return 'Password tidak cocok';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: AppTypography.labelMedium.copyWith(
                color: AppThemeColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<AuthCubit>().changePassword(
                  currentPassword: currentController.text,
                  newPassword: newController.text,
                  confirmPassword: confirmController.text,
                );
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeColors.primary,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
            ),
            child: Text(
              'Simpan',
              style: AppTypography.labelMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppThemeColors.primarySurface,
                borderRadius: AppRadius.smRadius,
              ),
              child: const Icon(Icons.info, color: AppThemeColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('About', style: AppTypography.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAboutRow('Creator', 'Kreatif'),
            const SizedBox(height: AppSpacing.md),
            _buildAboutRow('PhoneNo', '081932701147'),
            const SizedBox(height: AppSpacing.md),
            _buildAboutRow('Address', 'Jl Serut Jaya No 74, Bekasi'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: AppTypography.labelMedium.copyWith(color: AppThemeColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppThemeColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }

  void _showEditDialog({
    required String title,
    required String currentValue,
    required String hint,
    required IconData icon,
    required Function(String) onSave,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    final controller = TextEditingController(text: currentValue);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppThemeColors.primarySurface,
                borderRadius: AppRadius.smRadius,
              ),
              child: Icon(icon, color: AppThemeColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(title, style: AppTypography.titleLarge)),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            textCapitalization: maxLines > 1
                ? TextCapitalization.sentences
                : TextCapitalization.words,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppThemeColors.textHint,
              ),
              border: OutlineInputBorder(borderRadius: AppRadius.mdRadius),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdRadius,
                borderSide: const BorderSide(
                  color: AppThemeColors.primary,
                  width: 2,
                ),
              ),
            ),
            style: AppTypography.bodyMedium,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Field ini tidak boleh kosong';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: AppTypography.labelMedium.copyWith(
                color: AppThemeColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                onSave(controller.text.trim());
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeColors.primary,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
            ),
            child: Text(
              'Simpan',
              style: AppTypography.labelMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthPasswordChanged) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password berhasil diubah'),
                  backgroundColor: AppThemeColors.success,
                ),
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppThemeColors.error,
                ),
              );
            }
          },
        ),
        BlocListener<SettingsCubit, SettingsState>(
          bloc: _settingsCubit,
          listener: (context, state) {
            if (state is SettingsUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppThemeColors.success,
                ),
              );
            } else if (state is SettingsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppThemeColors.error,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppThemeColors.background,
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final user = authState is AuthAuthenticated ? authState.user : null;

            return Column(
              children: [
                // Header with gradient
                _buildHeader(user),

                // Settings content
                Expanded(
                  child: BlocBuilder<SettingsCubit, SettingsState>(
                    bloc: _settingsCubit,
                    builder: (context, settingsState) {
                      // Get laundry info from state
                      LaundryInfo? laundryInfo;
                      if (settingsState is SettingsLoaded) {
                        laundryInfo = settingsState.laundryInfo;
                      } else if (settingsState is SettingsUpdated) {
                        laundryInfo = settingsState.laundryInfo;
                      } else {
                        laundryInfo = _settingsCubit.currentInfo;
                      }

                      return ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          const SizedBox(height: AppSpacing.lg),

                          // Laundry Info Section
                          if (user != null && user.role == UserRole.owner)
                          _buildSection(
                            title: 'Informasi Laundry',
                            children: [
                              _buildSettingTile(
                                context: context,
                                icon: Icons.store,
                                title: 'Nama Laundry',
                                subtitle:
                                    laundryInfo?.name ??
                                    AppConstants.defaultLaundryName,
                                onTap: () => _showEditDialog(
                                  title: 'Edit Nama Laundry',
                                  currentValue:
                                      laundryInfo?.name ??
                                      AppConstants.defaultLaundryName,
                                  hint: 'Masukkan nama laundry',
                                  icon: Icons.store,
                                  onSave: (value) =>
                                      _settingsCubit.updateLaundryName(value),
                                ),
                              ),
                              _buildDivider(),
                              _buildSettingTile(
                                context: context,
                                icon: Icons.location_on,
                                title: 'Alamat',
                                subtitle:
                                    laundryInfo?.address ??
                                    AppConstants.defaultLaundryAddress,
                                onTap: () => _showEditDialog(
                                  title: 'Edit Alamat',
                                  currentValue:
                                      laundryInfo?.address ??
                                      AppConstants.defaultLaundryAddress,
                                  hint: 'Masukkan alamat laundry',
                                  icon: Icons.location_on,
                                  maxLines: 2,
                                  onSave: (value) => _settingsCubit
                                      .updateLaundryAddress(value),
                                ),
                              ),
                              _buildDivider(),
                              _buildSettingTile(
                                context: context,
                                icon: Icons.phone,
                                title: 'Nomor HP',
                                subtitle:
                                    laundryInfo?.phone ??
                                    AppConstants.defaultLaundryPhone,
                                onTap: () => _showEditDialog(
                                  title: 'Edit Nomor HP',
                                  currentValue:
                                      laundryInfo?.phone ??
                                      AppConstants.defaultLaundryPhone,
                                  hint: 'Masukkan nomor HP',
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                  onSave: (value) =>
                                      _settingsCubit.updateLaundryPhone(value),
                                ),
                              ),
                            ],
                          ),

                          // Service Management Section
                          if (user != null && user.role == UserRole.owner)
                          _buildSection(
                            title: 'Master Data',
                            children: [
                              _buildSettingTile(
                                context: context,
                                icon: Icons.local_laundry_service,
                                title: 'Paket Layanan',
                                subtitle: 'Kelola paket layanan laundry',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (_) => ServiceCubit(),
                                        child: const ServiceListScreen(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildSettingTile(
                                context: context,
                                icon: Icons.people_alt,
                                title: 'Kelola Pelanggan',
                                subtitle: 'Lihat dan kelola data pelanggan',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (_) => CustomerCubit(),
                                        child: const CustomerListScreen(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          // App Settings Section
                          if (user != null && user.role == UserRole.owner)
                          _buildSection(
                            title: 'Pengaturan Aplikasi',
                            children: [
                              _buildSettingTile(
                                context: context,
                                icon: Icons.receipt,
                                title: 'Prefix Invoice',
                                subtitle:
                                    laundryInfo?.invoicePrefix ??
                                    AppConstants.defaultInvoicePrefix,
                                onTap: () => _showEditDialog(
                                  title: 'Edit Prefix Invoice',
                                  currentValue:
                                      laundryInfo?.invoicePrefix ??
                                      AppConstants.defaultInvoicePrefix,
                                  hint: 'Masukkan prefix (maks 10 karakter)',
                                  icon: Icons.receipt,
                                  maxLength: 10,
                                  onSave: (value) =>
                                      _settingsCubit.updateInvoicePrefix(value),
                                ),
                              ),
                              _buildDivider(),
                              _buildSettingTile(
                                context: context,
                                icon: Icons.print,
                                title: 'Pengaturan Printer',
                                subtitle: 'Coming Soon',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PrinterSettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          // User Management Section
                          if (user != null && user.role == UserRole.owner)
                            _buildSection(
                              title: 'Manajemen User',
                              children: [
                                _buildSettingTile(
                                  context: context,
                                  icon: Icons.people,
                                  title: 'Kelola User',
                                  subtitle: 'Tambah, edit, atau hapus user',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider(
                                          create: (_) => UserCubit(),
                                          child: const UserManagementScreen(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _buildDivider(),
                                _buildSettingTile(
                                  context: context,
                                  icon: Icons.lock,
                                  title: 'Ubah Password',
                                  subtitle: 'Ganti password akun Anda',
                                  onTap: () => _showChangePasswordDialog(context),
                                ),
                              ],
                            ),

                          if (user != null && user.role == UserRole.owner)
                            _buildSection(
                              title: 'Manajemen Data',
                              children: [
                                _buildSettingTile(
                                  context: context,
                                  icon: Icons.save,
                                  title: 'Backup Database',
                                  subtitle: 'Simpan data ke penyimpanan lokal',
                                  onTap: () async {
                                    try {
                                      await DatabaseService().backupDatabase();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Backup berhasil'), backgroundColor: Colors.green),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Backup gagal: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                                ),
                                _buildDivider(),
                                _buildSettingTile(
                                  context: context,
                                  icon: Icons.restore,
                                  title: 'Restore Database',
                                  subtitle: 'Pulihkan data dari file backup',
                                  onTap: () async {
                                    try {
                                        // Confirm first
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Konfirmasi Restore'),
                                            content: const Text('Restore akan menimpa data yang ada. Lanjutkan?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await DatabaseService().restoreDatabase();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Restore berhasil. Silakan restart aplikasi.'), backgroundColor: Colors.green),
                                            );
                                          }
                                        }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Restore gagal: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                                ),
                                _buildDivider(),
                                _buildSettingTile(
                                  context: context,
                                  icon: Icons.delete_forever,
                                  title: 'Reset Database',
                                  subtitle: 'Hapus semua data (Hati-hati!)',
                                  onTap: () async {
                                     final confirm = await showDialog<bool>(
                                       context: context,
                                       builder: (ctx) => AlertDialog(
                                         title: const Text('Reset Database?'),
                                         content: const Text('Semua data akan dihapus permanen. Tindakan ini tidak dapat dibatalkan!'),
                                         actions: [
                                           TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                           ElevatedButton(
                                             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                             onPressed: () => Navigator.pop(ctx, true),
                                             child: const Text('Reset', style: TextStyle(color: Colors.white)),
                                           ),
                                         ],
                                       ),
                                     );

                                     if (confirm == true) {
                                        try {
                                          await DatabaseService().resetDatabase();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Database berhasil di-reset'), backgroundColor: Colors.green),
                                            );
                                            // Optionally logout or restart
                                            context.read<AuthCubit>().logout();
                                          }
                                        } catch (e) {
                                           if (mounted) {
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               SnackBar(content: Text('Reset gagal: $e'), backgroundColor: Colors.red),
                                             );
                                           }
                                        }
                                     }
                                  },
                                ),
                              ],
                            ),                        

                          // About Section
                          _buildSection(
                            title: 'Tentang Aplikasi',
                            children: [
                              _buildSettingTile(
                                context: context,
                                icon: Icons.info_outline,
                                title: AppConstants.appName,
                                subtitle: 'Versi ${AppConstants.appVersion}',
                                showArrow: false,
                                onTap: null,
                              ),
                              _buildDivider(),
                              _buildSettingTile(
                                context: context,
                                icon: Icons.info,
                                title: 'About',
                                subtitle: 'Informasi Pembuat',
                                onTap: () => _showAboutDialog(context),
                              ),
                            ],
                          ),

                          // Logout Button
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: GestureDetector(
                              onTap: () => _showLogoutDialog(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppThemeColors.error,
                                  ),
                                  borderRadius: AppRadius.mdRadius,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.logout,
                                      color: AppThemeColors.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'Logout',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: AppThemeColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Container(
      decoration: const BoxDecoration(gradient: AppThemeColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Title row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Settings',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              if (user != null) ...[
                const SizedBox(height: AppSpacing.xl),

                // User info card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadius.fullRadius,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppThemeColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // User details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '@${user.username}',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppRadius.fullRadius,
                        ),
                        child: Text(
                          _getRoleDisplayName(user.role),
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: AppThemeColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.lgRadius,
              boxShadow: AppShadows.small,
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      height: 1,
      color: AppThemeColors.divider,
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppThemeColors.primarySurface,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Icon(icon, color: AppThemeColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppThemeColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow or edit icon
              if (showArrow && onTap != null)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppThemeColors.primarySurface,
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: AppThemeColors.primary,
                    size: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceItem(String year, String role, String company) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppThemeColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$role - $company',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppThemeColors.textPrimary,
                  ),
                ),
                Text(
                  year,
                  style: AppTypography.labelSmall.copyWith(
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


}
