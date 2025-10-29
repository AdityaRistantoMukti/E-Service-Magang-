import 'package:flutter/material.dart';

enum OrderStatus {
  assigned('Ditugaskan', Icons.assignment, Colors.grey),
  accepted('Menerima Pesanan', Icons.assignment_turned_in, Colors.blueGrey),
  enRoute('Dalam Perjalanan', Icons.directions_car, Colors.orange),
  arrived('Tiba', Icons.location_on, Colors.blue),
  waitingApproval('Menunggu Persetujuan', Icons.hourglass_empty, Colors.yellow),
  pickingParts('Mengambil Suku Cadang', Icons.build, Colors.purple),
  repairing('Memperbaiki', Icons.settings, Colors.red),
  completed('Selesai', Icons.check_circle, Colors.green),
  delivering('Mengantar', Icons.local_shipping, Colors.teal);

  const OrderStatus(this.displayName, this.icon, this.color);
  final String displayName;
  final IconData icon;
  final Color color;
}

class TechnicianOrder {
  final String orderId;
  final String customerName;
  final String customerAddress;
  final String deviceType;
  final String deviceBrand;
  final String deviceSerial;
  final String serviceType;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? scheduledTime;
  final double? visitCost;
  final String? customerPhone;
  final String? notes;
  final List<String>? damagePhotos;
  final String? damageDescription;
  final double? estimatedPrice;

  TechnicianOrder({
    required this.orderId,
    required this.customerName,
    required this.customerAddress,
    required this.deviceType,
    required this.deviceBrand,
    required this.deviceSerial,
    required this.serviceType,
    required this.status,
    required this.createdAt,
    this.scheduledTime,
    this.visitCost,
    this.customerPhone,
    this.notes,
    this.damagePhotos,
    this.damageDescription,
    this.estimatedPrice,
  });

  // Convert to Map for SharedPreferences/API
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerName': customerName,
      'customerAddress': customerAddress,
      'deviceType': deviceType,
      'deviceBrand': deviceBrand,
      'deviceSerial': deviceSerial,
      'serviceType': serviceType,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'scheduledTime': scheduledTime?.toIso8601String(),
      'visitCost': visitCost,
      'customerPhone': customerPhone,
      'notes': notes,
      'damagePhotos': damagePhotos,
      'damageDescription': damageDescription,
      'estimatedPrice': estimatedPrice,
    };
  }

  // Create from Map
  factory TechnicianOrder.fromMap(Map<String, dynamic> map) {
    return TechnicianOrder(
      orderId: map['orderId'],
      customerName: map['customerName'],
      customerAddress: map['customerAddress'],
      deviceType: map['deviceType'],
      deviceBrand: map['deviceBrand'],
      deviceSerial: map['deviceSerial'],
      serviceType: map['serviceType'],
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.assigned,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      scheduledTime:
          map['scheduledTime'] != null
              ? DateTime.parse(map['scheduledTime'])
              : null,
      visitCost: map['visitCost'],
      customerPhone: map['customerPhone'],
      notes: map['notes'],
      damagePhotos:
          map['damagePhotos'] != null
              ? List<String>.from(map['damagePhotos'])
              : null,
      damageDescription: map['damageDescription'],
      estimatedPrice: map['estimatedPrice'],
    );
  }

  // Create copy with updated status
  TechnicianOrder copyWith({
    OrderStatus? status,
    String? damageDescription,
    double? estimatedPrice,
    List<String>? damagePhotos,
  }) {
    return TechnicianOrder(
      orderId: orderId,
      customerName: customerName,
      customerAddress: customerAddress,
      deviceType: deviceType,
      deviceBrand: deviceBrand,
      deviceSerial: deviceSerial,
      serviceType: serviceType,
      status: status ?? this.status,
      createdAt: createdAt,
      scheduledTime: scheduledTime,
      visitCost: visitCost,
      customerPhone: customerPhone,
      notes: notes,
      damagePhotos: damagePhotos ?? this.damagePhotos,
      damageDescription: damageDescription ?? this.damageDescription,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
    );
  }
}
