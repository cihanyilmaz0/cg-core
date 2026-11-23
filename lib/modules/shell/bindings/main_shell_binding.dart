import 'package:get/get.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../employees/bindings/employees_binding.dart';
import '../../expenses/bindings/expenses_binding.dart';
import '../../reports/bindings/reports_binding.dart';
import '../../vehicles/bindings/vehicles_binding.dart';
import '../controllers/main_shell_controller.dart';

class MainShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainShellController>(() => MainShellController());
    Get.lazyPut<DashboardController>(() => DashboardController());
    EmployeesBinding().dependencies();
    VehiclesBinding().dependencies();
    ExpensesBinding().dependencies();
    ReportsBinding().dependencies();
  }
}
