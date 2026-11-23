import 'package:get/get.dart';
import '../../employees/repositories/employee_repository.dart';
import '../controllers/vehicle_detail_controller.dart';
import '../controllers/vehicles_controller.dart';
import '../repositories/vehicle_repository.dart';

class VehiclesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<IVehicleRepository>()) {
      Get.lazyPut<IVehicleRepository>(() => VehicleRepository(), fenix: true);
    }
    if (!Get.isRegistered<IEmployeeRepository>()) {
      Get.lazyPut<IEmployeeRepository>(() => EmployeeRepository(), fenix: true);
    }
    Get.lazyPut<VehiclesController>(() => VehiclesController(), fenix: true);
  }
}

class VehicleDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<IVehicleRepository>()) {
      Get.lazyPut<IVehicleRepository>(() => VehicleRepository(), fenix: true);
    }
    Get.lazyPut<VehicleDetailController>(() => VehicleDetailController());
  }
}
