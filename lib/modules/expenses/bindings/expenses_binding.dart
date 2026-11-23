import 'package:get/get.dart';
import '../controllers/expenses_controller.dart';
import '../repositories/expense_repository.dart';

class ExpensesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<IExpenseRepository>()) {
      Get.lazyPut<IExpenseRepository>(() => ExpenseRepository(), fenix: true);
    }
    Get.lazyPut<ExpensesController>(() => ExpensesController(), fenix: true);
  }
}
