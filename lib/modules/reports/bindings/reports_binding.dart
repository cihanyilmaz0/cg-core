import 'package:get/get.dart';
import '../controllers/reports_controller.dart';
import '../repositories/report_repository.dart';

class ReportsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<IReportRepository>()) {
      Get.lazyPut<IReportRepository>(() => ReportRepository(), fenix: true);
    }
    Get.lazyPut<ReportsController>(() => ReportsController(), fenix: true);
  }
}
