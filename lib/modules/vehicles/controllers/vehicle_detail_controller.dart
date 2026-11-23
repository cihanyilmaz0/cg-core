import 'package:get/get.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/app_snackbar.dart';
import '../models/vehicle_cost_summary_model.dart';
import '../models/vehicle_maintenance_model.dart';
import '../models/vehicle_model.dart';
import '../repositories/vehicle_repository.dart';
import '../utils/vehicle_cost_calculator.dart';
import 'vehicles_controller.dart';

class VehicleDetailController extends GetxController {
  final IVehicleRepository _vehicleRepository = Get.find<IVehicleRepository>();

  final Rxn<VehicleModel> vehicle = Rxn<VehicleModel>();
  final RxList<VehicleMaintenanceModel> records = <VehicleMaintenanceModel>[].obs;
  final Rx<DateTime> selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final Rxn<VehicleCostSummaryModel> costSummary = Rxn<VehicleCostSummaryModel>();

  final RxBool isLoading = false.obs;
  final RxBool isActionLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is VehicleModel) {
      vehicle.value = arg;
      loadVehicleDetails(arg.id);
    } else if (arg is String) {
      loadByVehicleId(arg);
    }
  }

  Future<void> loadByVehicleId(String id) async {
    try {
      isLoading.value = true;
      final v = await _vehicleRepository.getVehicleById(id);
      if (v != null) {
        vehicle.value = v;
        await loadVehicleDetails(id);
      } else {
        errorMessage.value = 'Araç kaydı bulunamadı.';
      }
    } catch (e) {
      errorMessage.value = 'Araç yüklenemedi: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadVehicleDetails(String vehicleId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final results = await Future.wait([
        _vehicleRepository.getVehicleById(vehicleId),
        _vehicleRepository.getMaintenanceRecords(vehicleId),
      ]);

      final freshVehicle = results[0] as VehicleModel?;
      if (freshVehicle != null) {
        vehicle.value = freshVehicle;
      }

      records.assignAll(results[1] as List<VehicleMaintenanceModel>);
      recalculateSummary();
    } catch (e) {
      errorMessage.value = 'Araç detayları yüklenirken hata oluştu: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void recalculateSummary() {
    costSummary.value = VehicleCostCalculator.calculateSummary(
      records: records,
      year: selectedMonth.value.year,
      month: selectedMonth.value.month,
    );
  }

  void previousMonth() {
    final c = selectedMonth.value;
    selectedMonth.value = DateTime(c.year, c.month - 1);
    recalculateSummary();
  }

  void nextMonth() {
    final c = selectedMonth.value;
    selectedMonth.value = DateTime(c.year, c.month + 1);
    recalculateSummary();
  }

  Future<bool> addExpenseRecord({
    required VehicleExpenseType expenseType,
    required int amountCents,
    required DateTime date,
    int? odometerKm,
    String? note,
  }) async {
    final v = vehicle.value;
    if (v == null) return false;

    try {
      isActionLoading.value = true;
      final record = VehicleMaintenanceModel(
        id: '',
        vehicleId: v.id,
        expenseType: expenseType,
        amountCents: amountCents,
        date: date,
        odometerKm: odometerKm,
        note: note,
        createdAt: DateTime.now(),
      );

      final created = await _vehicleRepository.addMaintenanceRecord(
        vehicle: v,
        record: record,
      );

      records.insert(0, created);
      records.sort((a, b) => b.date.compareTo(a.date));

      if (odometerKm != null && odometerKm > v.currentKm) {
        vehicle.value = v.copyWith(currentKm: odometerKm);
        _syncListController();
      }

      recalculateSummary();
      return true;
    } catch (e) {
      AppSnackbar.showError('Hata', 'Araç gideri kaydedilemedi: $e');
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> deleteExpenseRecord(String recordId) async {
    try {
      await _vehicleRepository.deleteMaintenanceRecord(recordId);
      records.removeWhere((r) => r.id == recordId);
      recalculateSummary();
      AppSnackbar.showInfo('Silindi', 'Araç gider kaydı silindi.');
    } catch (e) {
      AppSnackbar.showError('Hata', 'Kayıt silinemedi: $e');
    }
  }

  void _syncListController() {
    if (Get.isRegistered<VehiclesController>()) {
      Get.find<VehiclesController>().loadVehicles();
    }
  }
}
