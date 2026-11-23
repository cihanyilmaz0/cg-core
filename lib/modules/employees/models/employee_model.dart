import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_enums.dart';

class EmployeeModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? position;
  final String? department;
  final String? branchId;
  final DateTime startDate;
  final DateTime? endDate;
  final SalaryType salaryType;
  final int baseSalaryCents;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  EmployeeModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.position,
    this.department,
    this.branchId,
    required this.startDate,
    this.endDate,
    this.salaryType = SalaryType.monthly,
    required this.baseSalaryCents,
    this.isActive = true,
    this.notes,
    required this.createdAt,
  });

  factory EmployeeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EmployeeModel.fromMap(data, doc.id);
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> data, String id) {
    return EmployeeModel(
      id: id,
      fullName: data['fullName'] as String? ?? '',
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      position: data['position'] as String?,
      department: data['department'] as String?,
      branchId: data['branchId'] as String?,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      salaryType: SalaryType.fromString(data['salaryType'] as String?),
      baseSalaryCents: (data['baseSalaryCents'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (position != null && position!.isNotEmpty) 'position': position,
      if (department != null && department!.isNotEmpty) 'department': department,
      if (branchId != null && branchId!.isNotEmpty) 'branchId': branchId,
      'startDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      'salaryType': salaryType.name,
      'baseSalaryCents': baseSalaryCents,
      'isActive': isActive,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  EmployeeModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? position,
    String? department,
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    SalaryType? salaryType,
    int? baseSalaryCents,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      position: position ?? this.position,
      department: department ?? this.department,
      branchId: branchId ?? this.branchId,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      salaryType: salaryType ?? this.salaryType,
      baseSalaryCents: baseSalaryCents ?? this.baseSalaryCents,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
