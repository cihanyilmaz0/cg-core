import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/tenant_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../employees/models/employee_model.dart';
import '../../employees/repositories/employee_repository.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../../vehicles/repositories/vehicle_repository.dart';
import '../models/expense_category_model.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';

class ExpensesController extends GetxController {
  final IExpenseRepository _expenseRepository = Get.find<IExpenseRepository>();
  final TenantService _tenantService = TenantService.to;
  final AuthService _authService = AuthService.to;
  final StorageService _storageService = StorageService.to;
  final ImagePicker _imagePicker = ImagePicker();

  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final RxList<ExpenseCategoryModel> categories = <ExpenseCategoryModel>[].obs;
  final RxList<VehicleModel> vehicles = <VehicleModel>[].obs;
  final RxList<EmployeeModel> employees = <EmployeeModel>[].obs;

  final Rx<DateTime> selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final RxnString selectedCategoryFilterId = RxnString();
  final RxString searchQuery = ''.obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  // Form Controllers
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  final Rxn<ExpenseCategoryModel> selectedCategory = Rxn<ExpenseCategoryModel>();
  final Rx<PaymentMethod> selectedPaymentMethod = PaymentMethod.cash.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rxn<VehicleModel> selectedVehicle = Rxn<VehicleModel>();
  final Rxn<EmployeeModel> selectedEmployee = Rxn<EmployeeModel>();
  final Rxn<XFile> pickedReceiptFile = Rxn<XFile>();

  List<ExpenseModel> get filteredExpenses {
    final query = searchQuery.value.trim().toLowerCase();
    final catId = selectedCategoryFilterId.value;

    return expenses.where((e) {
      if (catId != null && e.categoryId != catId) return false;
      if (query.isNotEmpty) {
        final titleMatch = (e.title ?? '').toLowerCase().contains(query);
        final descMatch = (e.description ?? '').toLowerCase().contains(query);
        final catMatch = (e.categoryName ?? '').toLowerCase().contains(query);
        return titleMatch || descMatch || catMatch;
      }
      return true;
    }).toList();
  }

  int get filteredTotalCents {
    return filteredExpenses.fold(0, (sum, item) => sum + item.amountCents);
  }

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    if (!_tenantService.hasActiveBusiness) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final results = await Future.wait([
        _expenseRepository.getCategories(),
        _expenseRepository.getExpenses(
          year: selectedMonth.value.year,
          month: selectedMonth.value.month,
        ),
      ]);

      categories.assignAll(results[0] as List<ExpenseCategoryModel>);
      expenses.assignAll(results[1] as List<ExpenseModel>);
    } catch (e) {
      errorMessage.value = 'Giderler yüklenirken hata oluştu: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadExpensesForMonth() async {
    if (!_tenantService.hasActiveBusiness) return;

    try {
      isLoading.value = true;
      final list = await _expenseRepository.getExpenses(
        year: selectedMonth.value.year,
        month: selectedMonth.value.month,
      );
      expenses.assignAll(list);
    } catch (e) {
      AppSnackbar.showError('Hata', 'Giderler yüklenemedi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void previousMonth() {
    final c = selectedMonth.value;
    selectedMonth.value = DateTime(c.year, c.month - 1);
    loadExpensesForMonth();
  }

  void nextMonth() {
    final c = selectedMonth.value;
    selectedMonth.value = DateTime(c.year, c.month + 1);
    loadExpensesForMonth();
  }

  void setCategoryFilter(String? categoryId) {
    selectedCategoryFilterId.value = categoryId;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  Future<void> initForm() async {
    titleController.clear();
    amountController.clear();
    descriptionController.clear();
    selectedPaymentMethod.value = PaymentMethod.cash;
    selectedDate.value = DateTime.now();
    selectedVehicle.value = null;
    selectedEmployee.value = null;
    pickedReceiptFile.value = null;

    if (categories.isEmpty) {
      await loadInitialData();
    }
    selectedCategory.value = categories.isNotEmpty ? categories.first : null;

    // İlişkili araç ve personelleri arka planda yükle
    if (Get.isRegistered<IVehicleRepository>()) {
      Get.find<IVehicleRepository>().getVehicles().then((list) {
        vehicles.assignAll(list.where((v) => v.isActive).toList());
      }).catchError((_) {});
    }
    if (Get.isRegistered<IEmployeeRepository>()) {
      Get.find<IEmployeeRepository>().getEmployees().then((list) {
        employees.assignAll(list.where((e) => e.isActive).toList());
      }).catchError((_) {});
    }
  }

  Future<void> pickReceiptImage(ImageSource source) async {
    try {
      if (!kIsWeb) {
        if (source == ImageSource.camera) {
          final status = await Permission.camera.request();
          if (!status.isGranted) {
            if (status.isPermanentlyDenied) {
              _showPermissionSettingsDialog('Kamera İzni Gerekli',
                  'Fiş fotoğrafı çekebilmek için ayarlardan kamera iznini açmanız gerekiyor.');
            } else {
              AppSnackbar.showError(
                'İzin Gerekli',
                'Fiş fotoğrafı çekmek için kamera izni vermeniz gerekiyor.',
              );
            }
            return;
          }
        } else if (source == ImageSource.gallery) {
          var status = await Permission.photos.request();
          if (!status.isGranted && !status.isLimited) {
            // Android 12 ve altı cihazlar için depolama iznini dene
            final storageStatus = await Permission.storage.request();
            if (!storageStatus.isGranted) {
              if (status.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
                _showPermissionSettingsDialog('Galeri İzni Gerekli',
                    'Galeriden fiş seçebilmek için ayarlardan fotoğraf/medya iznini açmanız gerekiyor.');
              } else {
                AppSnackbar.showError(
                  'İzin Gerekli',
                  'Galeriden fiş seçmek için fotoğraf erişim izni vermeniz gerekiyor.',
                );
              }
              return;
            }
          }
        }
      }

      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 65,
      );
      if (file != null) {
        pickedReceiptFile.value = file;
      }
    } catch (e) {
      AppSnackbar.showError('Hata', 'Fotoğraf seçilemedi: $e');
    }
  }

  void _showPermissionSettingsDialog(String title, String message) {
    final context = Get.context;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              openAppSettings();
            },
            child: const Text('Ayarlara Git'),
          ),
        ],
      ),
    );
  }

  Future<bool> saveExpense() async {
    if (!formKey.currentState!.validate()) return false;
    final cat = selectedCategory.value;
    if (cat == null) {
      AppSnackbar.showError('Uyarı', 'Lütfen bir gider kategorisi seçiniz.');
      return false;
    }

    try {
      isSaving.value = true;
      final cents = CurrencyFormatter.parseToCents(amountController.text);

      String? receiptUrl;
      if (pickedReceiptFile.value != null) {
        receiptUrl = await _storageService.uploadReceiptImage(pickedReceiptFile.value!);
      }

      final expense = ExpenseModel(
        id: '',
        categoryId: cat.id,
        categoryName: cat.name,
        amountCents: cents,
        title: titleController.text.trim().isEmpty ? cat.name : titleController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        paymentMethod: selectedPaymentMethod.value,
        relatedVehicleId: selectedVehicle.value?.id,
        relatedEmployeeId: selectedEmployee.value?.id,
        date: selectedDate.value,
        receiptUrl: receiptUrl,
        createdBy: _authService.currentUserProfile.value?.uid,
        createdAt: DateTime.now(),
      );

      final created = await _expenseRepository.createExpense(expense);

      if (created.date.year == selectedMonth.value.year &&
          created.date.month == selectedMonth.value.month) {
        expenses.insert(0, created);
        expenses.sort((a, b) => b.date.compareTo(a.date));
      }

      Get.back(result: true);
      AppSnackbar.showSuccess(
        'Gider Kaydedildi',
        '${created.title} (${CurrencyFormatter.formatCents(cents)}) eklendi.',
      );
      return true;
    } catch (e) {
      AppSnackbar.showError('Hata', 'Gider kaydedilemedi: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      final target = expenses.firstWhereOrNull((e) => e.id == expenseId);
      await _expenseRepository.deleteExpense(expenseId);
      if (target?.receiptUrl != null) {
        await _storageService.deleteByUrl(target!.receiptUrl);
      }
      expenses.removeWhere((e) => e.id == expenseId);
      AppSnackbar.showInfo('Silindi', 'Gider kaydı silindi.');
    } catch (e) {
      AppSnackbar.showError('Hata', 'Gider silinemedi: $e');
    }
  }

  Future<bool> addCategory(String name, String iconCode, String colorHex) async {
    if (name.trim().isEmpty) return false;
    try {
      isSaving.value = true;
      final cat = ExpenseCategoryModel(
        id: '',
        name: name.trim(),
        iconCode: iconCode,
        colorHex: colorHex,
        isDefault: false,
        createdAt: DateTime.now(),
      );
      final created = await _expenseRepository.createCategory(cat);
      categories.add(created);
      categories.sort((a, b) => a.name.compareTo(b.name));
      return true;
    } catch (e) {
      AppSnackbar.showError('Hata', 'Kategori eklenemedi: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _expenseRepository.deleteCategory(categoryId);
      categories.removeWhere((c) => c.id == categoryId);
      if (selectedCategoryFilterId.value == categoryId) {
        selectedCategoryFilterId.value = null;
      }
      AppSnackbar.showInfo('Silindi', 'Kategori silindi.');
    } catch (e) {
      AppSnackbar.showError('Hata', 'Kategori silinemedi: $e');
    }
  }

  ExpenseCategoryModel? findCategory(String categoryId) {
    return categories.firstWhereOrNull((c) => c.id == categoryId);
  }

  @override
  void onClose() {
    titleController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
