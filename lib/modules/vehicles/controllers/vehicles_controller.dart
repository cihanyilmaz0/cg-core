import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/services/tenant_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../employees/models/employee_model.dart';
import '../../employees/repositories/employee_repository.dart';
import '../models/vehicle_model.dart';
import '../repositories/vehicle_repository.dart';

enum VehicleStatusFilter { active, passive, all }

class VehiclesController extends GetxController {
  final IVehicleRepository _vehicleRepository = Get.find<IVehicleRepository>();
  final TenantService _tenantService = TenantService.to;

  final RxList<VehicleModel> vehicles = <VehicleModel>[].obs;
  final RxList<EmployeeModel> availableEmployees = <EmployeeModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  final RxString searchQuery = ''.obs;
  final Rx<VehicleStatusFilter> statusFilter = VehicleStatusFilter.active.obs;

  // Form Controllers
  final formKey = GlobalKey<FormState>();
  final plateController = TextEditingController();
  final brandController = TextEditingController();
  final modelController = TextEditingController();
  final yearController = TextEditingController();
  final vehicleTypeController = TextEditingController();
  final currentKmController = TextEditingController();

  final Rx<FuelType> selectedFuelType = FuelType.diesel.obs;
  final Rxn<EmployeeModel> selectedEmployee = Rxn<EmployeeModel>();
  final Rxn<DateTime> insuranceExpiryDate = Rxn<DateTime>();
  final Rxn<DateTime> cascoExpiryDate = Rxn<DateTime>();
  final Rxn<DateTime> inspectionExpiryDate = Rxn<DateTime>();
  final RxBool isActive = true.obs;

  VehicleModel? editingVehicle;

  List<VehicleModel> get filteredVehicles {
    final query = searchQuery.value.trim().toLowerCase();
    return vehicles.where((v) {
      if (statusFilter.value == VehicleStatusFilter.active && !v.isActive) {
        return false;
      }
      if (statusFilter.value == VehicleStatusFilter.passive && v.isActive) {
        return false;
      }
      if (query.isNotEmpty) {
        final plateMatch = v.plate.toLowerCase().contains(query);
        final brandMatch = v.brand.toLowerCase().contains(query);
        final modelMatch = (v.model ?? '').toLowerCase().contains(query);
        return plateMatch || brandMatch || modelMatch;
      }
      return true;
    }).toList();
  }

  int get activeVehicleCount => vehicles.where((v) => v.isActive).length;

  @override
  void onInit() {
    super.onInit();
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    if (!_tenantService.hasActiveBusiness) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';
      final list = await _vehicleRepository.getVehicles();
      vehicles.assignAll(list);
    } catch (e) {
      errorMessage.value = 'Araçlar yüklenirken hata oluştu: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAvailableEmployees() async {
    if (!Get.isRegistered<IEmployeeRepository>()) return;
    try {
      final list = await Get.find<IEmployeeRepository>().getEmployees();
      availableEmployees.assignAll(list.where((e) => e.isActive).toList());
    } catch (_) {}
  }

  void setSearchQuery(String value) => searchQuery.value = value;
  void setStatusFilter(VehicleStatusFilter filter) => statusFilter.value = filter;

  void initFormForCreate() {
    editingVehicle = null;
    plateController.clear();
    brandController.clear();
    modelController.clear();
    yearController.clear();
    vehicleTypeController.clear();
    currentKmController.text = '0';
    selectedFuelType.value = FuelType.diesel;
    selectedEmployee.value = null;
    insuranceExpiryDate.value = null;
    cascoExpiryDate.value = null;
    inspectionExpiryDate.value = null;
    isActive.value = true;
    loadAvailableEmployees();
  }

  Future<void> initFormForEdit(VehicleModel vehicle) async {
    editingVehicle = vehicle;
    plateController.text = vehicle.plate;
    brandController.text = vehicle.brand;
    modelController.text = vehicle.model ?? '';
    yearController.text = vehicle.year?.toString() ?? '';
    vehicleTypeController.text = vehicle.vehicleType ?? '';
    currentKmController.text = vehicle.currentKm.toString();
    selectedFuelType.value = vehicle.fuelType;
    insuranceExpiryDate.value = vehicle.insuranceExpiryDate;
    cascoExpiryDate.value = vehicle.cascoExpiryDate;
    inspectionExpiryDate.value = vehicle.inspectionExpiryDate;
    isActive.value = vehicle.isActive;
    selectedEmployee.value = null;

    await loadAvailableEmployees();
    if (vehicle.assignedEmployeeId != null) {
      selectedEmployee.value = availableEmployees.firstWhereOrNull(
        (e) => e.id == vehicle.assignedEmployeeId,
      );
    }
  }

  Future<bool> saveVehicle() async {
    if (!formKey.currentState!.validate()) return false;

    try {
      isSaving.value = true;
      final parsedYear = int.tryParse(yearController.text.trim());
      final parsedKm = int.tryParse(currentKmController.text.replaceAll('.', '').trim()) ?? 0;

      if (editingVehicle == null) {
        final newVehicle = VehicleModel(
          id: '',
          plate: plateController.text.trim().toUpperCase(),
          brand: brandController.text.trim(),
          model: modelController.text.trim().isEmpty ? null : modelController.text.trim(),
          year: parsedYear,
          vehicleType: vehicleTypeController.text.trim().isEmpty
              ? null
              : vehicleTypeController.text.trim(),
          fuelType: selectedFuelType.value,
          currentKm: parsedKm,
          assignedEmployeeId: selectedEmployee.value?.id,
          assignedEmployeeName: selectedEmployee.value?.fullName,
          insuranceExpiryDate: insuranceExpiryDate.value,
          cascoExpiryDate: cascoExpiryDate.value,
          inspectionExpiryDate: inspectionExpiryDate.value,
          isActive: isActive.value,
          createdAt: DateTime.now(),
        );

        final created = await _vehicleRepository.createVehicle(newVehicle);
        vehicles.add(created);
        vehicles.sort((a, b) => a.plate.compareTo(b.plate));
      } else {
        final updated = editingVehicle!.copyWith(
          plate: plateController.text.trim().toUpperCase(),
          brand: brandController.text.trim(),
          model: modelController.text.trim().isEmpty ? null : modelController.text.trim(),
          year: parsedYear,
          vehicleType: vehicleTypeController.text.trim().isEmpty
              ? null
              : vehicleTypeController.text.trim(),
          fuelType: selectedFuelType.value,
          currentKm: parsedKm,
          assignedEmployeeId: selectedEmployee.value?.id,
          assignedEmployeeName: selectedEmployee.value?.fullName,
          clearAssignedEmployee: selectedEmployee.value == null,
          insuranceExpiryDate: insuranceExpiryDate.value,
          clearInsuranceDate: insuranceExpiryDate.value == null,
          cascoExpiryDate: cascoExpiryDate.value,
          clearCascoDate: cascoExpiryDate.value == null,
          inspectionExpiryDate: inspectionExpiryDate.value,
          clearInspectionDate: inspectionExpiryDate.value == null,
          isActive: isActive.value,
        );

        await _vehicleRepository.updateVehicle(updated);
        final idx = vehicles.indexWhere((v) => v.id == updated.id);
        if (idx != -1) {
          vehicles[idx] = updated;
        }
      }

      Get.back(result: true);
      AppSnackbar.showSuccess(
        'Başarılı',
        editingVehicle == null ? 'Araç kaydı oluşturuldu.' : 'Araç bilgileri güncellendi.',
      );
      return true;
    } catch (e) {
      AppSnackbar.showError('Hata', 'Araç kaydedilemedi: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    plateController.dispose();
    brandController.dispose();
    modelController.dispose();
    yearController.dispose();
    vehicleTypeController.dispose();
    currentKmController.dispose();
    super.onClose();
  }
}
