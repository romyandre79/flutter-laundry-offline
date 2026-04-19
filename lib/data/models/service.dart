import 'package:equatable/equatable.dart';

enum ServiceUnit { kg, pcs }

extension ServiceUnitExtension on ServiceUnit {
  String get value {
    switch (this) {
      case ServiceUnit.kg:
        return 'kg';
      case ServiceUnit.pcs:
        return 'pcs';
    }
  }

  String get displayName {
    switch (this) {
      case ServiceUnit.kg:
        return 'Kilogram';
      case ServiceUnit.pcs:
        return 'Pieces';
    }
  }

  static ServiceUnit fromString(String value) {
    switch (value.toLowerCase()) {
      case 'kg':
        return ServiceUnit.kg;
      case 'pcs':
        return ServiceUnit.pcs;
      default:
        return ServiceUnit.kg;
    }
  }
}

class Service extends Equatable {
  final int? id;
  final String name;
  final ServiceUnit unit;
  final int price;
  final int durationDays;
  final bool isActive;
  final String? barcode;
  final DateTime? createdAt;

  const Service({
    this.id,
    required this.name,
    required this.unit,
    required this.price,
    this.durationDays = 3,
    this.isActive = true,
    this.barcode,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit.value,
      'price': price,
      'duration_days': durationDays,
      'is_active': isActive ? 1 : 0,
      'barcode': barcode,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] as int?,
      name: map['name'] as String,
      unit: ServiceUnitExtension.fromString(map['unit'] as String),
      price: map['price'] as int,
      durationDays: (map['duration_days'] as int?) ?? 3,
      isActive: (map['is_active'] as int?) == 1,
      barcode: map['barcode'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Service copyWith({
    int? id,
    String? name,
    ServiceUnit? unit,
    int? price,
    int? durationDays,
    bool? isActive,
    String? barcode,
    DateTime? createdAt,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      durationDays: durationDays ?? this.durationDays,
      isActive: isActive ?? this.isActive,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        unit,
        price,
        durationDays,
        isActive,
        barcode,
        createdAt,
      ];
}
