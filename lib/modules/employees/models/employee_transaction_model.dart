import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_enums.dart';

class EmployeeTransactionModel {
  final String id;
  final String employeeId;
  final EmployeeTransactionType type;
  final int amountCents;
  final DateTime date;
  final String? description;
  final String? createdBy;
  final DateTime createdAt;

  EmployeeTransactionModel({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.amountCents,
    required this.date,
    this.description,
    this.createdBy,
    required this.createdAt,
  });

  factory EmployeeTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EmployeeTransactionModel.fromMap(data, doc.id);
  }

  factory EmployeeTransactionModel.fromMap(Map<String, dynamic> data, String id) {
    return EmployeeTransactionModel(
      id: id,
      employeeId: data['employeeId'] as String? ?? '',
      type: EmployeeTransactionType.fromString(data['type'] as String?),
      amountCents: (data['amountCents'] as num?)?.toInt() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] as String?,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'type': type.firestoreKey,
      'amountCents': amountCents,
      'date': Timestamp.fromDate(date),
      if (description != null && description!.isNotEmpty) 'description': description,
      if (createdBy != null && createdBy!.isNotEmpty) 'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
