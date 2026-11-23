import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_enums.dart';

class ExpenseModel {
  final String id;
  final String categoryId;
  final String? categoryName;
  final int amountCents;
  final String? title;
  final String? description;
  final PaymentMethod paymentMethod;
  final String? branchId;
  final String? relatedVehicleId;
  final String? relatedEmployeeId;
  final DateTime date;
  final String? receiptUrl;
  final String? createdBy;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.categoryId,
    this.categoryName,
    required this.amountCents,
    this.title,
    this.description,
    this.paymentMethod = PaymentMethod.cash,
    this.branchId,
    this.relatedVehicleId,
    this.relatedEmployeeId,
    required this.date,
    this.receiptUrl,
    this.createdBy,
    required this.createdAt,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExpenseModel.fromMap(data, doc.id);
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> data, String id) {
    return ExpenseModel(
      id: id,
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String?,
      amountCents: (data['amountCents'] as num?)?.toInt() ?? 0,
      title: data['title'] as String?,
      description: data['description'] as String?,
      paymentMethod: PaymentMethod.fromString(data['paymentMethod'] as String?),
      branchId: data['branchId'] as String?,
      relatedVehicleId: data['relatedVehicleId'] as String?,
      relatedEmployeeId: data['relatedEmployeeId'] as String?,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      receiptUrl: data['receiptUrl'] as String?,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      if (categoryName != null && categoryName!.isNotEmpty) 'categoryName': categoryName,
      'amountCents': amountCents,
      if (title != null && title!.isNotEmpty) 'title': title,
      if (description != null && description!.isNotEmpty) 'description': description,
      'paymentMethod': paymentMethod.firestoreKey,
      if (branchId != null && branchId!.isNotEmpty) 'branchId': branchId,
      if (relatedVehicleId != null && relatedVehicleId!.isNotEmpty)
        'relatedVehicleId': relatedVehicleId,
      if (relatedEmployeeId != null && relatedEmployeeId!.isNotEmpty)
        'relatedEmployeeId': relatedEmployeeId,
      'date': Timestamp.fromDate(date),
      if (receiptUrl != null && receiptUrl!.isNotEmpty) 'receiptUrl': receiptUrl,
      if (createdBy != null && createdBy!.isNotEmpty) 'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
