import 'package:equatable/equatable.dart';
import 'package:kreatif_laundry_offline_app/data/models/customer.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {
  const CustomerInitial();
}

class CustomerLoading extends CustomerState {
  const CustomerLoading();
}

class CustomerLoaded extends CustomerState {
  final List<Customer> customers;

  const CustomerLoaded(this.customers);

  @override
  List<Object?> get props => [customers];
}

class CustomerOperationSuccess extends CustomerState {
  final String message;
  final Customer? customer;

  const CustomerOperationSuccess(this.message, {this.customer});

  @override
  List<Object?> get props => [message, customer];
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError(this.message);

  @override
  List<Object?> get props => [message];
}
