import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExpenseCategoryModel {
  final String id;
  final String name;
  final String iconCode;
  final String colorHex;
  final bool isDefault;
  final DateTime createdAt;

  ExpenseCategoryModel({
    required this.id,
    required this.name,
    this.iconCode = 'receipt_long',
    this.colorHex = '#1E3A8A',
    this.isDefault = false,
    required this.createdAt,
  });

  factory ExpenseCategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExpenseCategoryModel.fromMap(data, doc.id);
  }

  factory ExpenseCategoryModel.fromMap(Map<String, dynamic> data, String id) {
    return ExpenseCategoryModel(
      id: id,
      name: data['name'] as String? ?? '',
      iconCode: data['iconCode'] as String? ?? 'receipt_long',
      colorHex: data['colorHex'] as String? ?? '#1E3A8A',
      isDefault: data['isDefault'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconCode': iconCode,
      'colorHex': colorHex,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF1E3A8A);
    }
  }

  IconData get icon {
    switch (iconCode) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'lunch_dining':
        return Icons.lunch_dining_rounded;
      case 'home_work':
        return Icons.home_work_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'wifi':
        return Icons.wifi_rounded;
      case 'description':
        return Icons.description_rounded;
      case 'inventory_2':
        return Icons.inventory_2_rounded;
      case 'local_shipping':
        return Icons.local_shipping_rounded;
      case 'business_center':
        return Icons.business_center_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}
