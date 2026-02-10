import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/data/models/user.dart';
import 'package:kreatif_laundry_offline_app/data/repositories/auth_repository.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/auth/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  User? _currentUser;

  AuthCubit({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(const AuthInitial());

  /// Get current user
  User? get currentUser => _currentUser;

  /// Check auth status on app start
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        _currentUser = user;
        emit(AuthAuthenticated(user));
      } else {
        _currentUser = null;
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      _currentUser = null;
      emit(const AuthUnauthenticated());
    }
  }

  /// Login with username and password
  Future<void> login(String username, String password) async {
    emit(const AuthLoading());

    try {
      if (username.trim().isEmpty) {
        emit(const AuthError('Username tidak boleh kosong'));
        return;
      }

      if (password.isEmpty) {
        emit(const AuthError('Password tidak boleh kosong'));
        return;
      }

      final user = await _authRepository.login(username, password);
      _currentUser = user;
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Logout
  Future<void> logout() async {
    emit(const AuthLoading());

    try {
      await _authRepository.logout();
      _currentUser = null;
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_currentUser == null) {
      emit(const AuthError('User tidak ditemukan'));
      return;
    }

    if (newPassword != confirmPassword) {
      emit(const AuthError('Konfirmasi password tidak cocok'));
      return;
    }

    emit(const AuthLoading());

    try {
      await _authRepository.changePassword(
        userId: _currentUser!.id!,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      emit(const AuthPasswordChanged());
      // Re-emit authenticated state
      emit(AuthAuthenticated(_currentUser!));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      // Re-emit authenticated state to recover
      emit(AuthAuthenticated(_currentUser!));
    }
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        emit(AuthAuthenticated(user));
      }
    } catch (_) {}
  }
}
