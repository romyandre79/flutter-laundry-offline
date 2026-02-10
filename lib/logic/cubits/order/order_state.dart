import 'package:equatable/equatable.dart';
import 'package:kreatif_laundry_offline_app/data/models/order.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

class OrderLoaded extends OrderState {
  final List<Order> orders;
  final OrderStatus? filterStatus;
  final bool hasMore;
  final bool isLoadingMore;

  const OrderLoaded(
    this.orders, {
    this.filterStatus,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  OrderLoaded copyWith({
    List<Order>? orders,
    OrderStatus? filterStatus,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return OrderLoaded(
      orders ?? this.orders,
      filterStatus: filterStatus ?? this.filterStatus,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [orders, filterStatus, hasMore, isLoadingMore];
}

class OrderDetailLoaded extends OrderState {
  final Order order;

  const OrderDetailLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderCreated extends OrderState {
  final Order order;

  const OrderCreated(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderOperationSuccess extends OrderState {
  final String message;

  const OrderOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
