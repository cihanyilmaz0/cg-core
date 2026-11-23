import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/tenant_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../models/report_summary_model.dart';
import '../repositories/report_repository.dart';
import '../services/report_export_service.dart';

class ReportsController extends GetxController {
  final IReportRepository _reportRepository = Get.find<IReportRepository>();
  final TenantService _tenantService = TenantService.to;

  final Rx<DateTime> selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final Rxn<ReportSummaryModel> report = Rxn<ReportSummaryModel>();

  final RxBool isLoading = false.obs;
  final RxBool isExporting = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadReport();
  }

  Future<void> loadReport() async {
    if (!_tenantService.hasActiveBusiness) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';
      final summary = await _reportRepository.generateReport(
        year: selectedMonth.value.year,
        month: selectedMonth.value.month,
      );
      report.value = summary;
    } catch (e) {
      errorMessage.value = 'Rapor verileri hesaplanırken hata oluştu: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void previousMonth() {
    final c = selectedMonth.value;
    selectedMonth.value = DateTime(c.year, c.month - 1);
    loadReport();
  }

  void nextMonth() {
    final c = selectedMonth.value;
    selectedMonth.value = DateTime(c.year, c.month + 1);
    loadReport();
  }

  Future<void> exportPdf() async {
    final currentReport = report.value;
    if (currentReport == null) return;

    try {
      isExporting.value = true;
      final businessName = _tenantService.currentBusiness.value?.name ?? AppConstants.appName;
      await ReportExportService.exportToPdf(
        report: currentReport,
        businessName: businessName,
      );
    } catch (e) {
      AppSnackbar.showError('PDF Hatası', 'PDF raporu oluşturulamadı: $e');
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> exportExcel() async {
    final currentReport = report.value;
    if (currentReport == null) return;

    try {
      isExporting.value = true;
      final businessName = _tenantService.currentBusiness.value?.name ?? AppConstants.appName;
      await ReportExportService.exportToExcel(
        report: currentReport,
        businessName: businessName,
      );
    } catch (e) {
      AppSnackbar.showError('Excel Hatası', 'Excel raporu oluşturulamadı: $e');
    } finally {
      isExporting.value = false;
    }
  }
}
