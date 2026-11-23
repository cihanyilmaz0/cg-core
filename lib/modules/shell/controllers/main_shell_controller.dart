import 'package:get/get.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../reports/controllers/reports_controller.dart';

class MainShellController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 0 && Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboardData();
    } else if (index == 4 && Get.isRegistered<ReportsController>()) {
      Get.find<ReportsController>().loadReport();
    }
  }
}
