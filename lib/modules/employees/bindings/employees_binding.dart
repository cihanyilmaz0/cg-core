import 'package:get/get.dart';
import '../controllers/employee_detail_controller.dart';
import '../controllers/employees_controller.dart';
import '../repositories/employee_repository.dart';

class EmployeesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<IEmployeeRepository>()) {
      Get.lazyPut<IEmployeeRepository>(() => EmployeeRepository(), fenix: true);
    }
    Get.lazyPut<EmployeesController>(() => EmployeesController(), fenix: true);
  }
}

class EmployeeDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<IEmployeeRepository>()) {
      Get.lazyPut<IEmployeeRepository>(() => EmployeeRepository(), fenix: true);
    }
    Get.lazyPut<EmployeeDetailController>(() => EmployeeDetailController());
  }
}
