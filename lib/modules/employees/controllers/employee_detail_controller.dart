import 'package:get/get.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/employee_leave_record_model.dart';
import '../models/employee_model.dart';
import '../models/employee_monthly_summary_model.dart';
import '../models/employee_salary_history_model.dart';
import '../models/employee_transaction_model.dart';
import '../repositories/employee_repository.dart';
import '../utils/employee_salary_calculator.dart';
import 'employees_controller.dart';

class EmployeeDetailController extends GetxController {
  final IEmployeeRepository _employeeRepository = Get.find<IEmployeeRepository>();
  final AuthService _authService = AuthService.to;

  final Rxn<EmployeeModel> employee = Rxn<EmployeeModel>();
  final RxList<EmployeeSalaryHistoryModel> salaryHistory = <EmployeeSalaryHistoryModel>[].obs;
  final RxList<EmployeeTransactionModel> transactions = <EmployeeTransactionModel>[].obs;
  final RxList<EmployeeLeaveRecordModel> leaveRecords = <EmployeeLeaveRecordModel>[].obs;

  final Rx<DateTime> selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final Rxn<EmployeeMonthlySummaryModel> monthlySummary = Rxn<EmployeeMonthlySummaryModel>();

  final RxBool isLoading = false.obs;
  final RxBool isActionLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Varsayılan 30 günlük hesaplama kuralı
  final RxInt monthBasisDays = 30.obs;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is EmployeeModel) {
      employee.value = arg;
      loadAllDetails(arg.id);
    } else if (arg is String) {
      loadByEmployeeId(arg);
    }
  }

  Future<void> loadByEmployeeId(String id) async {
    try {
      isLoading.value = true;
      final emp = await _employeeRepository.getEmployeeById(id);
      if (emp != null) {
        employee.value = emp;
        await loadAllDetails(id);
      } else {
        errorMessage.value = 'Personel kaydı bulunamadı.';
      }
    } catch (e) {
      errorMessage.value = 'Personel yüklenemedi: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAllDetails(String employeeId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final results = await Future.wait([
        _employeeRepository.getEmployeeById(employeeId),
        _employeeRepository.getSalaryHistory(employeeId),
        _employeeRepository.getTransactions(employeeId),
        _employeeRepository.getLeaveRecords(employeeId),
      ]);

      final freshEmp = results[0] as EmployeeModel?;
      if (freshEmp != null) {
        employee.value = freshEmp;
      }

      salaryHistory.assignAll(results[1] as List<EmployeeSalaryHistoryModel>);
      transactions.assignAll(results[2] as List<EmployeeTransactionModel>);
      leaveRecords.assignAll(results[3] as List<EmployeeLeaveRecordModel>);

      recalculateMonthlySummary();
    } catch (e) {
      errorMessage.value = 'Personel detayları yüklenirken hata oluştu: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void recalculateMonthlySummary() {
    final emp = employee.value;
    if (emp == null) return;

    monthlySummary.value = EmployeeSalaryCalculator.calculateMonthlySummary(
      employee: emp,
      salaryHistory: salaryHistory,
      transactions: transactions,
      leaveRecords: leaveRecords,
      year: selectedMonth.value.year,
      month: selectedMonth.value.month,
      monthBasisDays: monthBasisDays.value,
    );
  }

  void previousMonth() {
    final current = selectedMonth.value;
    selectedMonth.value = DateTime(current.year, current.month - 1);
    recalculateMonthlySummary();
  }

  void nextMonth() {
    final current = selectedMonth.value;
    selectedMonth.value = DateTime(current.year, current.month + 1);
    recalculateMonthlySummary();
  }

  List<EmployeeTransactionModel> get currentMonthTransactions {
    return transactions
        .where((tx) =>
            tx.date.year == selectedMonth.value.year &&
            tx.date.month == selectedMonth.value.month)
        .toList();
  }

  List<EmployeeLeaveRecordModel> get currentMonthLeaves {
    final monthStart = DateTime(selectedMonth.value.year, selectedMonth.value.month, 1);
    final monthEnd = DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0, 23, 59, 59);
    return leaveRecords.where((leave) {
      return !leave.endDate.isBefore(monthStart) && !leave.startDate.isAfter(monthEnd);
    }).toList();
  }

  Future<bool> updateSalary({
    required String newSalaryText,
    required DateTime changeDate,
    String? note,
  }) async {
    final emp = employee.value;
    if (emp == null) return false;

    final newSalaryCents = CurrencyFormatter.parseToCents(newSalaryText);
    if (newSalaryCents < 0) return false;

    try {
      isActionLoading.value = true;
      await _employeeRepository.updateEmployeeSalary(
        employee: emp,
        newSalaryCents: newSalaryCents,
        changeDate: changeDate,
        note: note,
        changedBy: _authService.currentUserProfile.value?.uid,
      );

      await loadAllDetails(emp.id);
      _syncListController();
      return true;
    } catch (e) {
      AppSnackbar.showError('Hata', 'Maaş güncellenemedi: $e');
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> addTransaction({
    required EmployeeTransactionType type,
    required int amountCents,
    required DateTime date,
    String? description,
  }) async {
    final emp = employee.value;
    if (emp == null) return false;

    try {
      isActionLoading.value = true;
      final tx = EmployeeTransactionModel(
        id: '',
        employeeId: emp.id,
        type: type,
        amountCents: amountCents,
        date: date,
        description: description,
        createdBy: _authService.currentUserProfile.value?.uid,
        createdAt: DateTime.now(),
      );

      final created = await _employeeRepository.addTransaction(tx);
      transactions.insert(0, created);
      transactions.sort((a, b) => b.date.compareTo(a.date));
      recalculateMonthlySummary();
      return true;
    } catch (e) {
      AppSnackbar.showError('Hata', 'İşlem kaydedilemedi: $e');
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> deleteTransaction(String txId) async {
    try {
      await _employeeRepository.deleteTransaction(txId);
      transactions.removeWhere((t) => t.id == txId);
      recalculateMonthlySummary();
      AppSnackbar.showInfo('Silindi', 'Finansal hareket silindi.');
    } catch (e) {
      AppSnackbar.showError('Hata', 'Kayıt silinemedi: $e');
    }
  }

  Future<bool> addLeaveRecord({
    required LeaveType leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? note,
  }) async {
    final emp = employee.value;
    if (emp == null) return false;

    final normStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normEnd = DateTime(endDate.year, endDate.month, endDate.day);
    final totalDays = normEnd.difference(normStart).inDays + 1;

    if (totalDays <= 0) {
      AppSnackbar.showError('Uyarı', 'Bitiş tarihi başlangıç tarihinden önce olamaz.');
      return false;
    }

    try {
      isActionLoading.value = true;
      final leave = EmployeeLeaveRecordModel(
        id: '',
        employeeId: emp.id,
        leaveType: leaveType,
        startDate: normStart,
        endDate: normEnd,
        totalDays: totalDays,
        note: note,
        createdAt: DateTime.now(),
      );

      final created = await _employeeRepository.addLeaveRecord(leave);
      leaveRecords.insert(0, created);
      leaveRecords.sort((a, b) => b.startDate.compareTo(a.startDate));
      recalculateMonthlySummary();
      return true;
    } catch (e) {
      AppSnackbar.showError('Hata', 'İzin kaydedilemedi: $e');
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> deleteLeaveRecord(String leaveId) async {
    try {
      await _employeeRepository.deleteLeaveRecord(leaveId);
      leaveRecords.removeWhere((l) => l.id == leaveId);
      recalculateMonthlySummary();
      AppSnackbar.showInfo('Silindi', 'İzin kaydı silindi.');
    } catch (e) {
      AppSnackbar.showError('Hata', 'İzin kaydı silinemedi: $e');
    }
  }

  void _syncListController() {
    if (Get.isRegistered<EmployeesController>()) {
      Get.find<EmployeesController>().loadEmployees();
    }
  }
}
