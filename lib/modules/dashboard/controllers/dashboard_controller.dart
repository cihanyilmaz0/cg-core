import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/tenant_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../employees/controllers/employees_controller.dart';
import '../../employees/models/employee_transaction_model.dart';
import '../../employees/repositories/employee_repository.dart';
import '../../expenses/controllers/expenses_controller.dart';
import '../../shell/controllers/main_shell_controller.dart';
import '../../vehicles/controllers/vehicles_controller.dart';
import '../../vehicles/models/vehicle_maintenance_model.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../../vehicles/repositories/vehicle_repository.dart';
import '../../vehicles/utils/vehicle_cost_calculator.dart';

class DashboardController extends GetxController {
  final TenantService tenantService = TenantService.to;
  final AuthService authService = AuthService.to;

  final RxBool isLoading = false.obs;

  // Finansal özet değerleri (Kuruş cinsinden)
  final RxInt monthlyTotalExpenseCents = 0.obs;
  final RxInt monthlyPersonnelCostCents = 0.obs;
  final RxInt monthlyVehicleExpenseCents = 0.obs;
  final RxInt monthlyGeneralExpenseCents = 0.obs;

  // Sayısal sayaçlar
  final RxInt employeeCount = 0.obs;
  final RxInt vehicleCount = 0.obs;
  final RxInt upcomingAlertCount = 0.obs;

  // Son hareketler ve yaklaşan hatırlatmalar
  final RxList<Map<String, dynamic>> recentExpenses = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> upcomingMaintenance = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    if (!tenantService.hasActiveBusiness) return;

    try {
      isLoading.value = true;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // 1. Aktif personel & araç sayıları
      List<VehicleModel> allVehicles = [];
      if (Get.isRegistered<IEmployeeRepository>()) {
        final employees = await Get.find<IEmployeeRepository>().getEmployees();
        employeeCount.value = employees.where((e) => e.isActive).length;
      }
      if (Get.isRegistered<IVehicleRepository>()) {
        allVehicles = await Get.find<IVehicleRepository>().getVehicles();
        vehicleCount.value = allVehicles.where((v) => v.isActive).length;
      }

      // 2. Yaklaşan araç sigorta/kasko/muayene tarihleri (30 gün içinde veya geçmiş)
      final alerts = <Map<String, dynamic>>[];
      for (final v in allVehicles.where((v) => v.isActive)) {
        final checks = [
          ('Trafik Sigortası', v.insuranceExpiryDate),
          ('Kasko', v.cascoExpiryDate),
          ('Muayene', v.inspectionExpiryDate),
        ];
        for (final (label, date) in checks) {
          if (date == null) continue;
          final days = VehicleCostCalculator.daysRemaining(date, now: now);
          if (days <= 30) {
            alerts.add({
              'plate': v.plate,
              'type': label,
              'date': date,
              'days': days,
            });
          }
        }
      }
      alerts.sort((a, b) => (a['days'] as int).compareTo(b['days'] as int));
      upcomingMaintenance.assignAll(alerts);
      upcomingAlertCount.value = alerts.length;

      // 3. Bu ayki giderleri paralel çek
      final results = await Future.wait([
        tenantService
            .subCollection(AppConstants.subCollectionEmployeeTransactions)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
            .get(),
        tenantService
            .subCollection(AppConstants.subCollectionVehicleMaintenance)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
            .get(),
        tenantService
            .subCollection(AppConstants.subCollectionExpenses)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
            .get(),
      ]);

      final recentList = <Map<String, dynamic>>[];

      // Personel giderleri (Avans, Maaş Ödemesi, Prim, Diğer Ödeme)
      int personnelTotal = 0;
      for (final doc in results[0].docs) {
        final tx = EmployeeTransactionModel.fromFirestore(doc);
        if (tx.type != EmployeeTransactionType.deduction) {
          personnelTotal += tx.amountCents;
          recentList.add({
            'title': tx.type.displayName,
            'subtitle': tx.description ?? 'Personel ödemesi',
            'amountCents': tx.amountCents,
            'date': tx.date,
            'category': 'personnel',
          });
        }
      }

      // Araç giderleri
      int vehicleTotal = 0;
      final vehiclePlateMap = {for (final v in allVehicles) v.id: v.plate};
      for (final doc in results[1].docs) {
        final rec = VehicleMaintenanceModel.fromFirestore(doc);
        vehicleTotal += rec.amountCents;
        final plate = vehiclePlateMap[rec.vehicleId] ?? 'Araç';
        recentList.add({
          'title': '$plate • ${rec.expenseType.displayName}',
          'subtitle': rec.note ?? 'Araç gideri',
          'amountCents': rec.amountCents,
          'date': rec.date,
          'category': 'vehicle',
        });
      }

      // Genel işletme giderleri
      int generalTotal = 0;
      for (final doc in results[2].docs) {
        final data = doc.data();
        final amountCents = (data['amountCents'] as num?)?.toInt() ?? 0;
        final date = (data['date'] as Timestamp?)?.toDate() ?? now;
        generalTotal += amountCents;
        recentList.add({
          'title': data['title'] as String? ?? 'İşletme Gideri',
          'subtitle': data['description'] as String? ?? 'Genel gider',
          'amountCents': amountCents,
          'date': date,
          'category': 'general',
        });
      }

      monthlyPersonnelCostCents.value = personnelTotal;
      monthlyVehicleExpenseCents.value = vehicleTotal;
      monthlyGeneralExpenseCents.value = generalTotal;
      monthlyTotalExpenseCents.value = personnelTotal + vehicleTotal + generalTotal;

      recentList.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      recentExpenses.assignAll(recentList.take(5).toList());
    } catch (e) {
      AppSnackbar.showError('Hata', 'Dashboard verileri yüklenemedi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void onQuickAction(String action) {
    switch (action) {
      case 'add_employee':
        if (Get.isRegistered<EmployeesController>()) {
          Get.find<EmployeesController>().initFormForCreate();
        }
        Get.toNamed(AppRoutes.employeeForm);
        break;
      case 'give_advance':
        if (Get.isRegistered<MainShellController>()) {
          Get.find<MainShellController>().changeTab(1);
          AppSnackbar.showInfo(
            'Personel Seçin',
            'Avans vermek istediğiniz personeli listeden seçebilirsiniz.',
          );
        }
        break;
      case 'add_vehicle':
        if (Get.isRegistered<VehiclesController>()) {
          Get.find<VehiclesController>().initFormForCreate();
        }
        Get.toNamed(AppRoutes.vehicleForm);
        break;
      case 'add_fuel':
        if (Get.isRegistered<MainShellController>()) {
          Get.find<MainShellController>().changeTab(2);
          AppSnackbar.showInfo(
            'Araç Seçin',
            'Yakıt gideri eklemek istediğiniz aracı listeden seçebilirsiniz.',
          );
        }
        break;
      case 'add_expense':
        if (Get.isRegistered<ExpensesController>()) {
          Get.find<ExpensesController>().initForm();
        }
        Get.toNamed(AppRoutes.expenseForm);
        break;
      default:
        AppSnackbar.showInfo('Bilgi', 'Bu modül yakında aktif olacaktır.');
    }
  }

  void logout() async {
    final context = Get.context;
    if (context == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Çıkış'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authService.signOut();
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
