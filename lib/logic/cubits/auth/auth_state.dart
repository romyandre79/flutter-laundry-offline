import 'package:equatable/equatable.dart';
import 'package:kreatif_laundry_offline_app/data/models/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - checking auth status
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state - during login/logout
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state - user is logged in
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state - user is not logged in
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error state - auth operation failed
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Password changed successfully
class AuthPasswordChanged extends AuthState {
  const AuthPasswordChanged();
}
