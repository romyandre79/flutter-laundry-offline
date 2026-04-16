import 'package:equatable/equatable.dart';
import 'package:kreatif_laundry_offline_app/data/models/order_item.dart';
import 'package:kreatif_laundry_offline_app/data/models/payment.dart';

enum OrderStatus { pending, process, ready, done }

extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.process:
        return 'process';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.done:
        return 'done';
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.process:
        return 'Proses';
      case OrderStatus.ready:
        return 'Siap Ambil';
      case OrderStatus.done:
        return 'Selesai';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.pending:
        return 'Order baru masuk';
      case OrderStatus.process:
        return 'Sedang dikerjakan';
      case OrderStatus.ready:
        return 'Selesai, siap diambil';
      case OrderStatus.done:
        return 'Sudah diambil';
    }
  }

  static OrderStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'process':
        return OrderStatus.process;
      case 'ready':
        return OrderStatus.ready;
      case 'done':
        return OrderStatus.done;
      default:
        return OrderStatus.pending;
    }
  }
}

class Order extends Equatable {
  final int? id;
  final String invoiceNo;
  final int? customerId;
  final String customerName;
  final String? customerPhone;
  final DateTime orderDate;
  final DateTime? dueDate;
  final OrderStatus status;
  final int totalItems;
  final int totalWeight;
  final int totalPrice;
  final int totalDiscount;
  final int paid;
  final String? notes;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> images;

  // Relations (loaded separately)
  final List<OrderItem>? items;
  final List<Payment>? payments;

  const Order({
    this.id,
    required this.invoiceNo,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.orderDate,
    this.dueDate,
    this.status = OrderStatus.pending,
    this.totalItems = 0,
    this.totalWeight = 0,
    required this.totalPrice,
    this.totalDiscount = 0,
    this.paid = 0,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.items,
    this.payments,
    this.images = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_no': invoiceNo,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'order_date': orderDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'status': status.value,
      'total_items': totalItems,
      'total_weight': totalWeight,
      'total_price': totalPrice,
      'total_discount': totalDiscount,
      'paid': paid,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int?,
      invoiceNo: map['invoice_no'] as String,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String?,
      orderDate: DateTime.parse(map['order_date'] as String),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      status: OrderStatusExtension.fromString(map['status'] as String),
      totalItems: (map['total_items'] as int?) ?? 0,
      totalWeight: (map['total_weight'] as num?)?.toDouble() ?? 0,
      totalPrice: map['total_price'] as int,
      totalDiscount: (map['total_discount'] as int?) ?? 0,
      paid: (map['paid'] as int?) ?? 0,
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      images: const [], // Images loaded separately
    );
  }

  Order copyWith({
    int? id,
    String? invoiceNo,
    int? customerId,
    String? customerName,
    String? customerPhone,
    DateTime? orderDate,
    DateTime? dueDate,
    OrderStatus? status,
    int? totalItems,
    double? totalWeight,
    int? totalPrice,
    int? totalDiscount,
    int? paid,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
    List<Payment>? payments,
    List<String>? images,
  }) {
    return Order(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      orderDate: orderDate ?? this.orderDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      totalItems: totalItems ?? this.totalItems,
      totalWeight: totalWeight ?? this.totalWeight,
      totalPrice: totalPrice ?? this.totalPrice,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      paid: paid ?? this.paid,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      payments: payments ?? this.payments,
      images: images ?? this.images,
    );
  }

  // Helper methods
  int get remainingPayment => totalPrice - paid;
  bool get isPaid => paid >= totalPrice;
  bool get hasDeposit => paid > 0 && paid < totalPrice;

  // Aliases for printer service
  String get invoiceNumber => invoiceNo;
  int get subtotal => totalPrice + totalDiscount;
  int get discount => totalDiscount;
  int get totalAmount => totalPrice;
  int get paidAmount => paid;

  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == OrderStatus.done) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // Get available next status transitions (flexible workflow)
  List<OrderStatus> getNextStatusOptions() {
    switch (status) {
      case OrderStatus.pending:
        return [OrderStatus.process];
      case OrderStatus.process:
        // Flexible: bisa langsung Done atau lewat Ready dulu
        return [OrderStatus.ready, OrderStatus.done];
      case OrderStatus.ready:
        return [OrderStatus.done];
      case OrderStatus.done:
        return []; // Final state
    }
  }

  String get whatsappNumber {
    if (customerPhone == null || customerPhone!.isEmpty) return '';
    String cleaned = customerPhone!.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    }
    return cleaned;
  }

  @override
  List<Object?> get props => [
        id,
        invoiceNo,
        customerId,
        customerName,
        customerPhone,
        orderDate,
        dueDate,
        status,
        totalItems,
        totalWeight,
        totalPrice,
        totalDiscount,
        paid,
        notes,
        createdBy,
        createdAt,
        updatedAt,
        images,
      ];
}
