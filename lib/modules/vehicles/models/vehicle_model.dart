import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_enums.dart';

class VehicleModel {
  final String id;
  final String plate;
  final String brand;
  final String? model;
  final int? year;
  final String? vehicleType;
  final FuelType fuelType;
  final int currentKm;
  final String? assignedEmployeeId;
  final String? assignedEmployeeName;
  final String? branchId;
  final DateTime? insuranceExpiryDate;
  final DateTime? cascoExpiryDate;
  final DateTime? inspectionExpiryDate;
  final bool isActive;
  final DateTime createdAt;

  VehicleModel({
    required this.id,
    required this.plate,
    required this.brand,
    this.model,
    this.year,
    this.vehicleType,
    this.fuelType = FuelType.diesel,
    this.currentKm = 0,
    this.assignedEmployeeId,
    this.assignedEmployeeName,
    this.branchId,
    this.insuranceExpiryDate,
    this.cascoExpiryDate,
    this.inspectionExpiryDate,
    this.isActive = true,
    required this.createdAt,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VehicleModel.fromMap(data, doc.id);
  }

  factory VehicleModel.fromMap(Map<String, dynamic> data, String id) {
    return VehicleModel(
      id: id,
      plate: data['plate'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      model: data['model'] as String?,
      year: (data['year'] as num?)?.toInt(),
      vehicleType: data['vehicleType'] as String?,
      fuelType: FuelType.fromString(data['fuelType'] as String?),
      currentKm: (data['currentKm'] as num?)?.toInt() ?? 0,
      assignedEmployeeId: data['assignedEmployeeId'] as String?,
      assignedEmployeeName: data['assignedEmployeeName'] as String?,
      branchId: data['branchId'] as String?,
      insuranceExpiryDate: (data['insuranceExpiryDate'] as Timestamp?)?.toDate(),
      cascoExpiryDate: (data['cascoExpiryDate'] as Timestamp?)?.toDate(),
      inspectionExpiryDate: (data['inspectionExpiryDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plate': plate,
      'brand': brand,
      if (model != null && model!.isNotEmpty) 'model': model,
      if (year != null) 'year': year,
      if (vehicleType != null && vehicleType!.isNotEmpty) 'vehicleType': vehicleType,
      'fuelType': fuelType.firestoreKey,
      'currentKm': currentKm,
      if (assignedEmployeeId != null && assignedEmployeeId!.isNotEmpty)
        'assignedEmployeeId': assignedEmployeeId,
      if (assignedEmployeeName != null && assignedEmployeeName!.isNotEmpty)
        'assignedEmployeeName': assignedEmployeeName,
      if (branchId != null && branchId!.isNotEmpty) 'branchId': branchId,
      if (insuranceExpiryDate != null)
        'insuranceExpiryDate': Timestamp.fromDate(insuranceExpiryDate!),
      if (cascoExpiryDate != null)
        'cascoExpiryDate': Timestamp.fromDate(cascoExpiryDate!),
      if (inspectionExpiryDate != null)
        'inspectionExpiryDate': Timestamp.fromDate(inspectionExpiryDate!),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  VehicleModel copyWith({
    String? id,
    String? plate,
    String? brand,
    String? model,
    int? year,
    String? vehicleType,
    FuelType? fuelType,
    int? currentKm,
    String? assignedEmployeeId,
    String? assignedEmployeeName,
    bool clearAssignedEmployee = false,
    String? branchId,
    DateTime? insuranceExpiryDate,
    bool clearInsuranceDate = false,
    DateTime? cascoExpiryDate,
    bool clearCascoDate = false,
    DateTime? inspectionExpiryDate,
    bool clearInspectionDate = false,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      vehicleType: vehicleType ?? this.vehicleType,
      fuelType: fuelType ?? this.fuelType,
      currentKm: currentKm ?? this.currentKm,
      assignedEmployeeId: clearAssignedEmployee
          ? null
          : (assignedEmployeeId ?? this.assignedEmployeeId),
      assignedEmployeeName: clearAssignedEmployee
          ? null
          : (assignedEmployeeName ?? this.assignedEmployeeName),
      branchId: branchId ?? this.branchId,
      insuranceExpiryDate: clearInsuranceDate
          ? null
          : (insuranceExpiryDate ?? this.insuranceExpiryDate),
      cascoExpiryDate: clearCascoDate
          ? null
          : (cascoExpiryDate ?? this.cascoExpiryDate),
      inspectionExpiryDate: clearInspectionDate
          ? null
          : (inspectionExpiryDate ?? this.inspectionExpiryDate),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
