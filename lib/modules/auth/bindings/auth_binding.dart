import 'package:get/get.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/business_repository.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<IAuthRepository>()) {
      Get.lazyPut<IAuthRepository>(() => AuthRepository(), fenix: true);
    }
    if (!Get.isRegistered<IBusinessRepository>()) {
      Get.lazyPut<IBusinessRepository>(() => BusinessRepository(), fenix: true);
    }
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
