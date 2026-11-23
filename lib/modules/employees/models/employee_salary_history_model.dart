import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeSalaryHistoryModel {
  final String id;
  final String employeeId;
  final int previousSalaryCents;
  final int newSalaryCents;
  final DateTime changeDate;
  final String? note;
  final String? changedBy;
  final DateTime createdAt;

  EmployeeSalaryHistoryModel({
    required this.id,
    required this.employeeId,
    required this.previousSalaryCents,
    required this.newSalaryCents,
    required this.changeDate,
    this.note,
    this.changedBy,
    required this.createdAt,
  });

  factory EmployeeSalaryHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EmployeeSalaryHistoryModel.fromMap(data, doc.id);
  }

  factory EmployeeSalaryHistoryModel.fromMap(Map<String, dynamic> data, String id) {
    return EmployeeSalaryHistoryModel(
      id: id,
      employeeId: data['employeeId'] as String? ?? '',
      previousSalaryCents: (data['previousSalaryCents'] as num?)?.toInt() ?? 0,
      newSalaryCents: (data['newSalaryCents'] as num?)?.toInt() ?? 0,
      changeDate: (data['changeDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String?,
      changedBy: data['changedBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'previousSalaryCents': previousSalaryCents,
      'newSalaryCents': newSalaryCents,
      'changeDate': Timestamp.fromDate(changeDate),
      if (note != null && note!.isNotEmpty) 'note': note,
      if (changedBy != null && changedBy!.isNotEmpty) 'changedBy': changedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
