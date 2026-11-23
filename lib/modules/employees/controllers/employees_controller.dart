import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/services/tenant_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/employee_model.dart';
import '../repositories/employee_repository.dart';

enum EmployeeStatusFilter { all, active, passive }

class EmployeesController extends GetxController {
  final IEmployeeRepository _employeeRepository = Get.find<IEmployeeRepository>();
  final TenantService _tenantService = TenantService.to;

  final RxList<EmployeeModel> employees = <EmployeeModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  final RxString searchQuery = ''.obs;
  final Rx<EmployeeStatusFilter> statusFilter = EmployeeStatusFilter.active.obs;

  // Form controllers
  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final positionController = TextEditingController();
  final departmentController = TextEditingController();
  final salaryController = TextEditingController();
  final notesController = TextEditingController();

  final Rx<SalaryType> selectedSalaryType = SalaryType.monthly.obs;
  final Rx<DateTime> selectedStartDate = DateTime.now().obs;
  final Rxn<DateTime> selectedEndDate = Rxn<DateTime>();
  final RxBool isActive = true.obs;

  EmployeeModel? editingEmployee;

  List<EmployeeModel> get filteredEmployees {
    final query = searchQuery.value.trim().toLowerCase();
    return employees.where((emp) {
      if (statusFilter.value == EmployeeStatusFilter.active && !emp.isActive) {
        return false;
      }
      if (statusFilter.value == EmployeeStatusFilter.passive && emp.isActive) {
        return false;
      }
      if (query.isNotEmpty) {
        final nameMatch = emp.fullName.toLowerCase().contains(query);
        final posMatch = (emp.position ?? '').toLowerCase().contains(query);
        final deptMatch = (emp.department ?? '').toLowerCase().contains(query);
        return nameMatch || posMatch || deptMatch;
      }
      return true;
    }).toList();
  }

  int get activeEmployeeCount => employees.where((e) => e.isActive).length;

  @override
  void onInit() {
    super.onInit();
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    if (!_tenantService.hasActiveBusiness) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';
      final list = await _employeeRepository.getEmployees();
      employees.assignAll(list);
    } catch (e) {
      errorMessage.value = 'Personeller yüklenirken hata oluştu: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void setSearchQuery(String value) {
    searchQuery.value = value;
  }

  void setStatusFilter(EmployeeStatusFilter filter) {
    statusFilter.value = filter;
  }

  void initFormForCreate() {
    editingEmployee = null;
    fullNameController.clear();
    phoneController.clear();
    emailController.clear();
    positionController.clear();
    departmentController.clear();
    salaryController.clear();
    notesController.clear();
    selectedSalaryType.value = SalaryType.monthly;
    selectedStartDate.value = DateTime.now();
    selectedEndDate.value = null;
    isActive.value = true;
  }

  void initFormForEdit(EmployeeModel employee) {
    editingEmployee = employee;
    fullNameController.text = employee.fullName;
    phoneController.text = employee.phone ?? '';
    emailController.text = employee.email ?? '';
    positionController.text = employee.position ?? '';
    departmentController.text = employee.department ?? '';
    salaryController.text = CurrencyFormatter.formatCents(
      employee.baseSalaryCents,
      includeSymbol: false,
    );
    notesController.text = employee.notes ?? '';
    selectedSalaryType.value = employee.salaryType;
    selectedStartDate.value = employee.startDate;
    selectedEndDate.value = employee.endDate;
    isActive.value = employee.isActive;
  }

  Future<bool> saveEmployee() async {
    if (!formKey.currentState!.validate()) return false;

    try {
      isSaving.value = true;
      final salaryCents = CurrencyFormatter.parseToCents(salaryController.text);

      if (editingEmployee == null) {
        final newEmployee = EmployeeModel(
          id: '',
          fullName: fullNameController.text.trim(),
          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
          position: positionController.text.trim().isEmpty ? null : positionController.text.trim(),
          department: departmentController.text.trim().isEmpty ? null : departmentController.text.trim(),
          startDate: selectedStartDate.value,
          endDate: selectedEndDate.value,
          salaryType: selectedSalaryType.value,
          baseSalaryCents: salaryCents,
          isActive: isActive.value,
          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
          createdAt: DateTime.now(),
        );

        final created = await _employeeRepository.createEmployee(newEmployee);
        employees.add(created);
        employees.sort((a, b) => a.fullName.compareTo(b.fullName));
      } else {
        final updated = editingEmployee!.copyWith(
          fullName: fullNameController.text.trim(),
          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
          position: positionController.text.trim().isEmpty ? null : positionController.text.trim(),
          department: departmentController.text.trim().isEmpty ? null : departmentController.text.trim(),
          startDate: selectedStartDate.value,
          endDate: selectedEndDate.value,
          clearEndDate: selectedEndDate.value == null,
          salaryType: selectedSalaryType.value,
          baseSalaryCents: salaryCents,
          isActive: isActive.value,
          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        );

        await _employeeRepository.updateEmployee(updated);
        final idx = employees.indexWhere((e) => e.id == updated.id);
        if (idx != -1) {
          employees[idx] = updated;
        }
      }

      Get.back(result: true);
      AppSnackbar.showSuccess(
        'Başarılı',
        editingEmployee == null ? 'Personel kaydı oluşturuldu.' : 'Personel bilgileri güncellendi.',
      );
      return true;
    } catch (e) {
      AppSnackbar.showError('Hata', 'Personel kaydedilemedi: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    positionController.dispose();
    departmentController.dispose();
    salaryController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
