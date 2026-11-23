import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../controllers/reports_controller.dart';
import '../models/report_summary_model.dart';

class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Raporlar ve Analiz',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: controller.loadReport,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.report.value == null) {
          return const LoadingView(message: 'Raporlar hazırlanıyor...');
        }

        if (controller.errorMessage.value.isNotEmpty && controller.report.value == null) {
          return ErrorStateView(
            message: controller.errorMessage.value,
            onRetry: controller.loadReport,
          );
        }

        final report = controller.report.value;
        if (report == null) {
          return const EmptyStateView(title: 'Rapor verisi bulunamadı');
        }

        return RefreshIndicator(
          onRefresh: controller.loadReport,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthSelector(),
                const SizedBox(height: 12),

                // Eşit boyutlu Dışa Aktarma Butonları (PDF & Excel)
                _buildExportButtons(),
                const SizedBox(height: 16),

                // Aylık & Yıllık Toplam Kartları
                _buildTotalsRow(report),
                const SizedBox(height: 20),

                // Aylık Trend Grafiği
                const Text(
                  'Aylık Gider Karşılaştırması',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _buildMonthlyTrendChart(report),
                const SizedBox(height: 20),

                // Kategori Bazlı Pasta Grafik
                const Text(
                  'Kategori Bazlı Dağılım',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _buildCategoryBreakdownCard(report),
                const SizedBox(height: 20),

                // Personel Bazlı Maliyet
                const Text(
                  'Personel Bazlı Maliyetler',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _buildEntityCostCard(
                  items: report.personnelCosts,
                  emptyText: 'Seçili ayda personel ödemesi bulunmuyor.',
                  icon: Icons.person_outline_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 20),

                // Araç Bazlı Maliyet
                const Text(
                  'Araç Bazlı Maliyetler',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _buildEntityCostCard(
                  items: report.vehicleCosts,
                  emptyText: 'Seçili ayda araç gideri bulunmuyor.',
                  icon: Icons.directions_car_outlined,
                  color: Colors.amber.shade800,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: controller.previousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Obx(
            () => Text(
              DateFormatter.formatMonthYear(controller.selectedMonth.value).toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            onPressed: controller.nextMonth,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButtons() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: controller.isExporting.value ? null : controller.exportPdf,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.error),
                  foregroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 19),
                label: const Text('PDF İndir / Paylaş', style: TextStyle(fontSize: 13)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: controller.isExporting.value ? null : controller.exportExcel,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.success),
                  foregroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.table_chart_rounded, size: 19),
                label: const Text('Excel (.xlsx)', style: TextStyle(fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsRow(ReportSummaryModel report) {
    return Row(
      children: [
        Expanded(
          child: _totalCard(
            title: 'Seçili Ay Toplamı',
            amountCents: report.monthlyTotalCents,
            color: AppColors.primary,
            icon: Icons.calendar_month_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _totalCard(
            title: '${report.year} Yılı Toplamı',
            amountCents: report.yearlyTotalCents,
            color: AppColors.secondary,
            icon: Icons.assessment_rounded,
          ),
        ),
      ],
    );
  }

  Widget _totalCard({
    required String title,
    required int amountCents,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatCents(amountCents),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart(ReportSummaryModel report) {
    final trends = report.monthlyTrends;
    final hasAnyData = trends.any((t) => t.totalCents > 0);

    if (!hasAnyData) {
      return _emptyBox('Grafik için henüz gider verisi oluşmadı.');
    }

    final maxLira = trends
        .map((t) => CurrencyFormatter.centsToLira(t.totalCents))
        .fold<double>(0, (prev, el) => el > prev ? el : prev);

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxLira <= 0 ? 100 : maxLira * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.dividerLight, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (val, _) {
                  if (val == 0) return const SizedBox.shrink();
                  final text = val >= 1000
                      ? '${(val / 1000).toStringAsFixed(0)}B'
                      : val.toStringAsFixed(0);
                  return Text(
                    text,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= trends.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      trends[idx].label,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: trends.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: CurrencyFormatter.centsToLira(item.totalCents),
                  color: item.month == report.month ? AppColors.primary : AppColors.primaryLight.withValues(alpha: 0.45),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(ReportSummaryModel report) {
    final items = report.categoryBreakdown;
    if (items.isEmpty || report.monthlyTotalCents == 0) {
      return _emptyBox('Seçili ayda gider dağılımı bulunmuyor.');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: items.map((cat) {
                  final pct = (cat.amountCents / report.monthlyTotalCents) * 100;
                  return PieChartSectionData(
                    color: cat.color,
                    value: cat.amountCents.toDouble(),
                    title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                    radius: 44,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...items.map((cat) {
            final pct = (cat.amountCents / report.monthlyTotalCents) * 100;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(cat.name, style: const TextStyle(fontSize: 13)),
                  ),
                  Text(
                    '%${pct.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    CurrencyFormatter.formatCents(cat.amountCents),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEntityCostCard({
    required List<EntityCostItem> items,
    required String emptyText,
    required IconData icon,
    required Color color,
  }) {
    if (items.isEmpty) {
      return _emptyBox(emptyText);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              item.subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
            trailing: Text(
              CurrencyFormatter.formatCents(item.amountCents),
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: color),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
      ),
    );
  }
}
