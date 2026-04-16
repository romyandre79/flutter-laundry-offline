import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final int totalOrders;
  final int totalSpent;
  final DateTime? lastOrderDate;
  final double defaultDiscount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Customer({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    this.totalOrders = 0,
    this.totalSpent = 0,
    this.lastOrderDate,
    this.defaultDiscount = 0,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'total_orders': totalOrders,
      'total_spent': totalSpent,
      'last_order_date': lastOrderDate?.toIso8601String(),
      'default_discount': defaultDiscount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      totalOrders: (map['total_orders'] as int?) ?? 0,
      totalSpent: (map['total_spent'] as int?) ?? 0,
      lastOrderDate: map['last_order_date'] != null
          ? DateTime.parse(map['last_order_date'] as String)
          : null,
      defaultDiscount: (map['default_discount'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? notes,
    int? totalOrders,
    int? totalSpent,
    DateTime? lastOrderDate,
    double? defaultDiscount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
      defaultDiscount: defaultDiscount ?? this.defaultDiscount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isLoyalCustomer => totalOrders >= 10;

  int get averageSpentPerOrder =>
      totalOrders > 0 ? (totalSpent / totalOrders).round() : 0;

  String get formattedPhone {
    if (phone == null || phone!.isEmpty) return '-';
    return phone!;
  }

  String get whatsappNumber {
    if (phone == null || phone!.isEmpty) return '';
    String cleaned = phone!.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    }
    return cleaned;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        address,
        notes,
        totalOrders,
        totalSpent,
        lastOrderDate,
        defaultDiscount,
        createdAt,
        updatedAt,
      ];
}
