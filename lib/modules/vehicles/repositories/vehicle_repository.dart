import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/tenant_service.dart';
import '../models/vehicle_maintenance_model.dart';
import '../models/vehicle_model.dart';

abstract class IVehicleRepository {
  Future<List<VehicleModel>> getVehicles();
  Future<VehicleModel?> getVehicleById(String vehicleId);
  Future<VehicleModel> createVehicle(VehicleModel vehicle);
  Future<void> updateVehicle(VehicleModel vehicle);
  Future<List<VehicleMaintenanceModel>> getMaintenanceRecords(String vehicleId);
  Future<VehicleMaintenanceModel> addMaintenanceRecord({
    required VehicleModel vehicle,
    required VehicleMaintenanceModel record,
  });
  Future<void> deleteMaintenanceRecord(String recordId);
}

class VehicleRepository implements IVehicleRepository {
  final TenantService _tenantService = TenantService.to;
  final FirebaseService _firebaseService = FirebaseService.to;

  CollectionReference<Map<String, dynamic>> get _vehiclesRef =>
      _tenantService.subCollection(AppConstants.subCollectionVehicles);

  CollectionReference<Map<String, dynamic>> get _maintenanceRef =>
      _tenantService.subCollection(AppConstants.subCollectionVehicleMaintenance);

  @override
  Future<List<VehicleModel>> getVehicles() async {
    final snapshot = await _vehiclesRef.orderBy('plate').get();
    return snapshot.docs.map((doc) => VehicleModel.fromFirestore(doc)).toList();
  }

  @override
  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    final doc = await _vehiclesRef.doc(vehicleId).get();
    if (!doc.exists) return null;
    return VehicleModel.fromFirestore(doc);
  }

  @override
  Future<VehicleModel> createVehicle(VehicleModel vehicle) async {
    final docRef = _vehiclesRef.doc();
    final newVehicle = vehicle.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
    );
    await docRef.set(newVehicle.toMap());
    return newVehicle;
  }

  @override
  Future<void> updateVehicle(VehicleModel vehicle) async {
    final map = vehicle.toMap();
    if (vehicle.insuranceExpiryDate == null) {
      map['insuranceExpiryDate'] = FieldValue.delete();
    }
    if (vehicle.cascoExpiryDate == null) {
      map['cascoExpiryDate'] = FieldValue.delete();
    }
    if (vehicle.inspectionExpiryDate == null) {
      map['inspectionExpiryDate'] = FieldValue.delete();
    }
    if (vehicle.assignedEmployeeId == null) {
      map['assignedEmployeeId'] = FieldValue.delete();
      map['assignedEmployeeName'] = FieldValue.delete();
    }
    await _vehiclesRef.doc(vehicle.id).update(map);
  }

  @override
  Future<List<VehicleMaintenanceModel>> getMaintenanceRecords(String vehicleId) async {
    final snapshot = await _maintenanceRef
        .where('vehicleId', isEqualTo: vehicleId)
        .get();
    final list = snapshot.docs
        .map((doc) => VehicleMaintenanceModel.fromFirestore(doc))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<VehicleMaintenanceModel> addMaintenanceRecord({
    required VehicleModel vehicle,
    required VehicleMaintenanceModel record,
  }) async {
    final batch = _firebaseService.firestore.batch();

    final recordRef = _maintenanceRef.doc();
    final newRecord = VehicleMaintenanceModel(
      id: recordRef.id,
      vehicleId: vehicle.id,
      expenseType: record.expenseType,
      amountCents: record.amountCents,
      date: record.date,
      odometerKm: record.odometerKm,
      note: record.note,
      receiptUrl: record.receiptUrl,
      createdAt: DateTime.now(),
    );
    batch.set(recordRef, newRecord.toMap());

    // Eğer yeni kayıt kilometresi aracın güncel kilometresinden büyükse aracın kilometresini otomatik güncelle
    if (record.odometerKm != null && record.odometerKm! > vehicle.currentKm) {
      batch.update(_vehiclesRef.doc(vehicle.id), {'currentKm': record.odometerKm});
    }

    await batch.commit();
    return newRecord;
  }

  @override
  Future<void> deleteMaintenanceRecord(String recordId) async {
    await _maintenanceRef.doc(recordId).delete();
  }
}
