import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/data/models/user.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/user/user_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/user/user_state.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/settings/user_form_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserCubit>().loadUsers();
  }

  void _showResetPasswordDialog(User user) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lgRadius,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppThemeColors.primaryGradient,
                          borderRadius: AppRadius.mdRadius,
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reset Password',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.name,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppThemeColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Password Field
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      labelStyle: AppTypography.bodyMedium.copyWith(
                        color: AppThemeColors.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppThemeColors.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppThemeColors.textSecondary,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
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

                  const SizedBox(height: AppSpacing.xl),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            side: const BorderSide(
                              color: AppThemeColors.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.mdRadius,
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppThemeColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppThemeColors.primaryGradient,
                            borderRadius: AppRadius.mdRadius,
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                context.read<UserCubit>().resetPassword(
                                      userId: user.id!,
                                      newPassword: passwordController.text,
                                    );
                                Navigator.pop(dialogContext);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.mdRadius,
                              ),
                            ),
                            child: Text(
                              'Reset',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showToggleStatusDialog(User user) {
    final isActive = user.isActive;
    final action = isActive ? 'nonaktifkan' : 'aktifkan';
    final actionTitle = isActive ? 'Nonaktifkan' : 'Aktifkan';

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgRadius,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (isActive ? AppThemeColors.error : AppThemeColors.success)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? Icons.block : Icons.check_circle,
                  color: isActive ? AppThemeColors.error : AppThemeColors.success,
                  size: 32,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                '$actionTitle User',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Message
              Text(
                'Apakah Anda yakin ingin $action ${user.name}?',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppThemeColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        side: const BorderSide(
                          color: AppThemeColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdRadius,
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppThemeColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<UserCubit>().toggleUserStatus(user.id!);
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isActive ? AppThemeColors.error : AppThemeColors.success,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdRadius,
                        ),
                      ),
                      child: Text(
                        actionTitle,
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserActionsBottomSheet(User user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppThemeColors.border,
                borderRadius: AppRadius.fullRadius,
              ),
            ),

            // User Info Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  _buildUserAvatar(user, size: 56),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!user.isActive) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppThemeColors.error.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: Text(
                                  'Nonaktif',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppThemeColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user.username}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppThemeColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildRoleBadge(user.role),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Actions
            _buildActionTile(
              icon: Icons.edit_outlined,
              iconColor: AppThemeColors.primary,
              title: 'Edit User',
              subtitle: 'Ubah nama dan role',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<UserCubit>(),
                      child: UserFormScreen(user: user),
                    ),
                  ),
                );
              },
            ),

            _buildActionTile(
              icon: Icons.lock_reset,
              iconColor: AppThemeColors.warning,
              title: 'Reset Password',
              subtitle: 'Ganti password user',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showResetPasswordDialog(user);
              },
            ),

            _buildActionTile(
              icon: user.isActive ? Icons.block : Icons.check_circle_outline,
              iconColor: user.isActive ? AppThemeColors.error : AppThemeColors.success,
              title: user.isActive ? 'Nonaktifkan User' : 'Aktifkan User',
              subtitle: user.isActive
                  ? 'User tidak bisa login'
                  : 'User bisa login kembali',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showToggleStatusDialog(user);
              },
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppThemeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppThemeColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // User List
          Expanded(
            child: BlocConsumer<UserCubit, UserState>(
              listener: (context, state) {
                if (state is UserOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppThemeColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mdRadius,
                      ),
                    ),
                  );
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
              builder: (context, state) {
                if (state is UserLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppThemeColors.primary,
                    ),
                  );
                }

                final users = context.read<UserCubit>().users;

                if (users.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<UserCubit>().loadUsers(),
                  color: AppThemeColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _buildUserCard(user),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
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
                      'Kelola User',
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Atur pengguna dan hak akses',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Add Button
              GestureDetector(
                onTap: () => _navigateToAddUser(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppThemeColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 40,
                color: AppThemeColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Belum ada user',
              style: AppTypography.titleMedium.copyWith(
                color: AppThemeColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap tombol + untuk menambah user baru',
              style: AppTypography.bodySmall.copyWith(
                color: AppThemeColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.lgRadius,
        child: InkWell(
          onTap: () => _showUserActionsBottomSheet(user),
          borderRadius: AppRadius.lgRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                // Avatar
                _buildUserAvatar(user),

                const SizedBox(width: AppSpacing.md),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Row
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!user.isActive) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppThemeColors.error.withValues(alpha: 0.1),
                                borderRadius: AppRadius.smRadius,
                              ),
                              child: Text(
                                'Nonaktif',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppThemeColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Username
                      Text(
                        '@${user.username}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppThemeColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Role Badge
                      _buildRoleBadge(user.role),
                    ],
                  ),
                ),

                // More Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppThemeColors.background,
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: AppThemeColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Secondary purple color for Kasir role
  static const Color _kasirColor = Color(0xFF7E57C2);

  Widget _buildUserAvatar(User user, {double size = 48}) {
    final isOwner = user.role == UserRole.owner;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: isOwner
            ? AppThemeColors.primaryGradient
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF9575CD),
                  Color(0xFF7E57C2),
                ],
              ),
        borderRadius: AppRadius.mdRadius,
        boxShadow: [
          BoxShadow(
            color: (isOwner ? AppThemeColors.primary : _kasirColor)
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isOwner ? Icons.admin_panel_settings : Icons.person,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    final isOwner = role == UserRole.owner;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: (isOwner ? AppThemeColors.primary : _kasirColor)
            .withValues(alpha: 0.1),
        borderRadius: AppRadius.smRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOwner ? Icons.verified : Icons.badge_outlined,
            size: 12,
            color: isOwner ? AppThemeColors.primary : _kasirColor,
          ),
          const SizedBox(width: 4),
          Text(
            role.displayName,
            style: AppTypography.labelSmall.copyWith(
              color: isOwner ? AppThemeColors.primary : _kasirColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppThemeColors.primaryGradient,
        borderRadius: AppRadius.fullRadius,
        boxShadow: AppShadows.purple,
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _navigateToAddUser(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          'Tambah User',
          style: AppTypography.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _navigateToAddUser() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<UserCubit>(),
          child: const UserFormScreen(),
        ),
      ),
    );
  }
}
