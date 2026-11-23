import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_enums.dart';

class EmployeeLeaveRecordModel {
  final String id;
  final String employeeId;
  final LeaveType leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String? note;
  final DateTime createdAt;

  EmployeeLeaveRecordModel({
    required this.id,
    required this.employeeId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    this.note,
    required this.createdAt,
  });

  factory EmployeeLeaveRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EmployeeLeaveRecordModel.fromMap(data, doc.id);
  }

  factory EmployeeLeaveRecordModel.fromMap(Map<String, dynamic> data, String id) {
    return EmployeeLeaveRecordModel(
      id: id,
      employeeId: data['employeeId'] as String? ?? '',
      leaveType: LeaveType.fromString(data['leaveType'] as String?),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalDays: (data['totalDays'] as num?)?.toInt() ?? 1,
      note: data['note'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'leaveType': leaveType.firestoreKey,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalDays': totalDays,
      if (note != null && note!.isNotEmpty) 'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
