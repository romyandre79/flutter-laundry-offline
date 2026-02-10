import 'package:equatable/equatable.dart';
import 'package:kreatif_laundry_offline_app/data/models/service.dart';

abstract class ServiceState extends Equatable {
  const ServiceState();

  @override
  List<Object?> get props => [];
}

class ServiceInitial extends ServiceState {
  const ServiceInitial();
}

class ServiceLoading extends ServiceState {
  const ServiceLoading();
}

class ServiceLoaded extends ServiceState {
  final List<Service> services;

  const ServiceLoaded(this.services);

  @override
  List<Object?> get props => [services];
}

class ServiceOperationSuccess extends ServiceState {
  final String message;

  const ServiceOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ServiceError extends ServiceState {
  final String message;

  const ServiceError(this.message);

  @override
  List<Object?> get props => [message];
}
