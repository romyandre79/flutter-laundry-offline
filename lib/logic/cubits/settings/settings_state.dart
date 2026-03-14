import 'package:equatable/equatable.dart';

class LaundryInfo {
  final String name;
  final String address;
  final String phone;
  final String invoicePrefix;
  final String? fonnteToken;

  const LaundryInfo({
    required this.name,
    required this.address,
    required this.phone,
    required this.invoicePrefix,
    required this.fonnteToken,
  });

  LaundryInfo copyWith({
    String? name,
    String? address,
    String? phone,
    String? invoicePrefix,
    String? fonnteToken,
  }) {
    return LaundryInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      fonnteToken: fonnteToken ?? this.fonnteToken,
    );
  }
}

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final LaundryInfo laundryInfo;

  const SettingsLoaded({required this.laundryInfo});

  @override
  List<Object?> get props => [laundryInfo];
}

class SettingsUpdating extends SettingsState {}

class SettingsUpdated extends SettingsState {
  final String message;
  final LaundryInfo laundryInfo;

  const SettingsUpdated({
    required this.message,
    required this.laundryInfo,
  });

  @override
  List<Object?> get props => [message, laundryInfo];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError({required this.message});

  @override
  List<Object?> get props => [message];
}
