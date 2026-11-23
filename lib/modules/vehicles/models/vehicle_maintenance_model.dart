import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_enums.dart';

class VehicleMaintenanceModel {
  final String id;
  final String vehicleId;
  final VehicleExpenseType expenseType;
  final int amountCents;
  final DateTime date;
  final int? odometerKm;
  final String? note;
  final String? receiptUrl;
  final DateTime createdAt;

  VehicleMaintenanceModel({
    required this.id,
    required this.vehicleId,
    required this.expenseType,
    required this.amountCents,
    required this.date,
    this.odometerKm,
    this.note,
    this.receiptUrl,
    required this.createdAt,
  });

  factory VehicleMaintenanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VehicleMaintenanceModel.fromMap(data, doc.id);
  }

  factory VehicleMaintenanceModel.fromMap(Map<String, dynamic> data, String id) {
    return VehicleMaintenanceModel(
      id: id,
      vehicleId: data['vehicleId'] as String? ?? '',
      expenseType: VehicleExpenseType.fromString(data['expenseType'] as String?),
      amountCents: (data['amountCents'] as num?)?.toInt() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      odometerKm: (data['odometerKm'] as num?)?.toInt(),
      note: data['note'] as String?,
      receiptUrl: data['receiptUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'expenseType': expenseType.firestoreKey,
      'amountCents': amountCents,
      'date': Timestamp.fromDate(date),
      if (odometerKm != null) 'odometerKm': odometerKm,
      if (note != null && note!.isNotEmpty) 'note': note,
      if (receiptUrl != null && receiptUrl!.isNotEmpty) 'receiptUrl': receiptUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
