import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/core/constants/app_constants.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/auth/auth_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/auth/auth_state.dart';
import 'package:kreatif_laundry_offline_app/presentation/widgets/custom_text_field.dart';
import 'package:kreatif_laundry_offline_app/presentation/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
        _usernameController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() => _isLoading = true);
        } else {
          setState(() => _isLoading = false);
        }

        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppThemeColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
            ),
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background gradient header
            Container(
              height: size.height * 0.45,
              decoration: const BoxDecoration(
                gradient: AppThemeColors.headerGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl),

                      // Header Animation
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // Logo
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: AppRadius.xlRadius,
                                boxShadow: AppShadows.large,
                              ),
                              child: const Icon(
                                Icons.local_laundry_service,
                                size: 48,
                                color: AppThemeColors.primary,
                              ),
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // Title
                            Text(
                              'Selamat Datang',
                              style: AppTypography.displaySmall.copyWith(
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            Text(
                              'Login ke ${AppConstants.appName}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Login Form Card
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppRadius.xlRadius,
                              boxShadow: AppShadows.large,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Login',
                                    style: AppTypography.headlineMedium,
                                  ),

                                  const SizedBox(height: AppSpacing.sm),

                                  Text(
                                    'Masukkan username dan password Anda',
                                    style: AppTypography.bodySmall,
                                  ),

                                  const SizedBox(height: AppSpacing.xxl),

                                  // Username Field
                                  CustomTextField(
                                    label: 'Username',
                                    hint: 'Masukkan username',
                                    controller: _usernameController,
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      color: AppThemeColors.textSecondary,
                                    ),
                                    textCapitalization: TextCapitalization.none,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Username tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: AppSpacing.lg),

                                  // Password Field
                                  CustomTextField(
                                    label: 'Password',
                                    hint: 'Masukkan password',
                                    controller: _passwordController,
                                    obscureText: true,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: AppThemeColors.textSecondary,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: AppSpacing.xxl),

                                  // Login Button
                                  CustomButton(
                                    text: 'Login',
                                    onPressed: _isLoading ? null : _handleLogin,
                                    isLoading: _isLoading,
                                    size: ButtonSize.large,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Info Card
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppThemeColors.primarySurface,
                              borderRadius: AppRadius.mdRadius,
                              border: Border.all(
                                color: AppThemeColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppThemeColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: AppRadius.smRadius,
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: AppThemeColors.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Default Login',
                                        style: AppTypography.titleSmall
                                            .copyWith(
                                              color: AppThemeColors.primary,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Username: ${AppConstants.defaultOwnerUsername} | Password: ${AppConstants.defaultOwnerPassword}',
                                        style: AppTypography.labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Version
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Versi ${AppConstants.appVersion}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppThemeColors.textHint,
                          ),
                        ),
                      ),
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
}
