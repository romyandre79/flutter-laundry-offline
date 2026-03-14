import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/core/utils/date_formatter.dart';
import 'package:kreatif_laundry_offline_app/data/database/database_helper.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/auth/auth_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/auth/auth_state.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/auth/login_screen.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/main_screen.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for Windows
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize all at once
  final results = await Future.wait([
    SharedPreferences.getInstance(),
    DateFormatter.initialize(),
    DatabaseHelper.instance.database,
  ]);

  final prefs = results[0] as SharedPreferences;
  final showOnboarding = !(prefs.getBool('onboarding_complete') ?? false);

  runApp(MyApp(showOnboarding: showOnboarding));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;

  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => AuthCubit()..checkAuthStatus())],
      child: MaterialApp(
        title: 'Kreatif Laundry (Offline)',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: AuthWrapper(showOnboarding: showOnboarding),
      ),
    );
  }
}

/// Wrapper widget that handles auth state changes
class AuthWrapper extends StatefulWidget {
  final bool showOnboarding;

  const AuthWrapper({super.key, required this.showOnboarding});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  void _onOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        // Show loading indicator while checking auth status
        if (state is AuthInitial || state is AuthLoading) {
          return Scaffold(
            backgroundColor: AppThemeColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.xlRadius,
                      boxShadow: AppShadows.medium,
                    ),
                    child: Image.asset(
                      'assets/icons/logolaundry.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const CircularProgressIndicator(
                    color: AppThemeColors.primary,
                  ),
                ],
              ),
            ),
          );
        }

        // Show main screen if authenticated
        if (state is AuthAuthenticated) {
          return const MainScreen();
        }

        // Show login screen if not authenticated
        return const LoginScreen();
      },
    );
  }
}
