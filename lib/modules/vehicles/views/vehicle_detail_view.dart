import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../controllers/vehicle_detail_controller.dart';
import '../controllers/vehicles_controller.dart';
import '../models/vehicle_maintenance_model.dart';
import '../models/vehicle_model.dart';
import '../utils/vehicle_cost_calculator.dart';

class VehicleDetailView extends GetView<VehicleDetailController> {
  const VehicleDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final kmFormatter = NumberFormat('#,##0', 'tr_TR');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Obx(() => Text(controller.vehicle.value?.plate ?? 'Araç Detayı')),
        actions: [
          Obx(() {
            final v = controller.vehicle.value;
            if (v == null) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Aracı Düzenle',
              onPressed: () async {
                final listCtrl = Get.find<VehiclesController>();
                await listCtrl.initFormForEdit(v);
                final updated = await Get.toNamed(AppRoutes.vehicleForm);
                if (updated == true) {
                  controller.loadVehicleDetails(v.id);
                }
              },
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.vehicle.value == null) {
          return const LoadingView(message: 'Araç detayları yükleniyor...');
        }

        if (controller.errorMessage.value.isNotEmpty && controller.vehicle.value == null) {
          return ErrorStateView(
            message: controller.errorMessage.value,
            onRetry: () {
              final id = controller.vehicle.value?.id;
              if (id != null) controller.loadVehicleDetails(id);
            },
          );
        }

        final v = controller.vehicle.value;
        if (v == null) {
          return const EmptyStateView(title: 'Araç bulunamadı');
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadVehicleDetails(v.id),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVehicleHeader(v, kmFormatter),
                const SizedBox(height: 14),
                _buildQuickActionGrid(context),
                const SizedBox(height: 16),
                _buildMonthSelector(),
                const SizedBox(height: 8),
                _buildCostSummaryGrid(),
                const SizedBox(height: 20),
                const Text(
                  'Sigorta, Kasko ve Muayene',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _buildExpiryDatesCard(v),
                const SizedBox(height: 20),
                const Text(
                  'Son Bakım ve Gider Kayıtları',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _buildRecordsList(context, kmFormatter),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVehicleHeader(VehicleModel v, NumberFormat kmFormatter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  v.plate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${v.brand} ${v.model ?? ''} ${v.year != null ? '(${v.year})' : ''}'.trim(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${v.vehicleType ?? 'Araç'} • ${v.fuelType.displayName}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _headerMetric('Güncel Km', '${kmFormatter.format(v.currentKm)} km'),
              _headerMetric('Sorumlu', v.assignedEmployeeName ?? 'Atanmamış'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildQuickActionGrid(BuildContext context) {
    final actions = [
      (
        label: 'Yakıt',
        icon: Icons.local_gas_station_rounded,
        color: Colors.amber.shade800,
        type: VehicleExpenseType.fuel,
      ),
      (
        label: 'Bakım',
        icon: Icons.build_rounded,
        color: AppColors.primary,
        type: VehicleExpenseType.maintenance,
      ),
      (
        label: 'Tamir',
        icon: Icons.car_repair_rounded,
        color: AppColors.error,
        type: VehicleExpenseType.repair,
      ),
      (
        label: 'Diğer Gider',
        icon: Icons.receipt_long_rounded,
        color: AppColors.secondary,
        type: VehicleExpenseType.other,
      ),
    ];

    return Row(
      children: actions.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < actions.length - 1 ? 8 : 0),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _showAddExpenseModal(context, item.type),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.dividerLight),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item.icon, size: 17, color: item.color),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: controller.previousMonth,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Obx(
          () => Text(
            DateFormatter.formatMonthYear(controller.selectedMonth.value).toUpperCase(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: controller.nextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Widget _buildCostSummaryGrid() {
    return Obx(() {
      final summary = controller.costSummary.value;
      if (summary == null) return const SizedBox.shrink();

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _costCard(
                  title: 'Toplam Araç Maliyeti',
                  value: CurrencyFormatter.formatCents(summary.totalCostCents),
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _costCard(
                  title: 'Km Başına Maliyet',
                  value: summary.costPerKmCents != null
                      ? '${CurrencyFormatter.formatCents(summary.costPerKmCents)}/km'
                      : '-',
                  subtitle: summary.trackedKmDelta > 0
                      ? '${summary.trackedKmDelta} km baz alındı'
                      : 'En az 2 km kaydı gerekli',
                  icon: Icons.speed_rounded,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _costCard(
                  title: 'Aylık Yakıt Gideri',
                  value: CurrencyFormatter.formatCents(summary.monthlyFuelCostCents),
                  icon: Icons.local_gas_station_rounded,
                  color: Colors.amber.shade800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _costCard(
                  title: 'Aylık Bakım / Tamir',
                  value: CurrencyFormatter.formatCents(summary.monthlyMaintenanceCostCents),
                  icon: Icons.build_rounded,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _costCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textMutedLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpiryDatesCard(VehicleModel v) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            _expiryRow('Trafik Sigortası', v.insuranceExpiryDate),
            const Divider(height: 16),
            _expiryRow('Kasko Poliçesi', v.cascoExpiryDate),
            const Divider(height: 16),
            _expiryRow('Araç Muayenesi', v.inspectionExpiryDate),
          ],
        ),
      ),
    );
  }

  Widget _expiryRow(String title, DateTime? date) {
    if (date == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13.5)),
          const Text('Girilmemiş', style: TextStyle(fontSize: 12.5, color: AppColors.textMutedLight)),
        ],
      );
    }

    final days = VehicleCostCalculator.daysRemaining(date);
    Color badgeColor = AppColors.success;
    String badgeText = '$days gün kaldı';
    if (days < 0) {
      badgeColor = AppColors.error;
      badgeText = '${days.abs()} gün geçti';
    } else if (days <= 30) {
      badgeColor = AppColors.warning;
      badgeText = days == 0 ? 'Bugün!' : '$days gün kaldı';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            Text(
              DateFormatter.formatDate(date),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badgeText,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: badgeColor),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsList(BuildContext context, NumberFormat kmFormatter) {
    return Obx(() {
      final list = controller.records;
      if (list.isEmpty) {
        return EmptyStateView(
          title: 'Henüz Gider / Bakım Kaydı Yok',
          message: 'Bu araç için yakıt, bakım veya sigorta kaydı ekleyebilirsiniz.',
          icon: Icons.build_circle_outlined,
          actionText: 'İlk Gideri Ekle',
          onAction: () => _showAddExpenseModal(context, VehicleExpenseType.fuel),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final VehicleMaintenanceModel rec = list[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(_expenseIcon(rec.expenseType), color: AppColors.primary, size: 20),
              ),
              title: Text(
                rec.expenseType.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                '${DateFormatter.formatDate(rec.date)}'
                '${rec.odometerKm != null ? ' • ${kmFormatter.format(rec.odometerKm)} km' : ''}'
                '${rec.note != null ? '\n${rec.note}' : ''}',
                style: const TextStyle(fontSize: 12),
              ),
              isThreeLine: rec.note != null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyFormatter.formatCents(rec.amountCents),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMutedLight),
                    onPressed: () => _confirmDelete(context, rec.id),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  IconData _expenseIcon(VehicleExpenseType type) {
    switch (type) {
      case VehicleExpenseType.fuel:
        return Icons.local_gas_station_rounded;
      case VehicleExpenseType.maintenance:
        return Icons.build_rounded;
      case VehicleExpenseType.repair:
        return Icons.car_repair_rounded;
      case VehicleExpenseType.tire:
        return Icons.tire_repair_rounded;
      case VehicleExpenseType.insurance:
      case VehicleExpenseType.casco:
        return Icons.security_rounded;
      case VehicleExpenseType.inspection:
        return Icons.fact_check_rounded;
      case VehicleExpenseType.parking:
        return Icons.local_parking_rounded;
      case VehicleExpenseType.hgs:
        return Icons.toll_rounded;
      case VehicleExpenseType.other:
        return Icons.receipt_long_rounded;
    }
  }

  void _confirmDelete(BuildContext context, String recordId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: const Text('Bu araç gider kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.deleteExpenseRecord(recordId);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context, VehicleExpenseType initialType) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final kmCtrl = TextEditingController(
      text: controller.vehicle.value?.currentKm.toString() ?? '',
    );
    final noteCtrl = TextEditingController();
    final selectedType = initialType.obs;
    final selectedDate = DateTime.now().obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Araç Gideri Ekle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => DropdownButtonFormField<VehicleExpenseType>(
                    initialValue: selectedType.value,
                    decoration: const InputDecoration(labelText: 'Gider Türü'),
                    items: VehicleExpenseType.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.displayName)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) selectedType.value = val;
                    },
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: amountCtrl,
                  label: 'Tutar (₺) *',
                  hint: 'Örn: 1.850,00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [TurkishCurrencyInputFormatter()],
                  validator: Validators.positiveAmount,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: kmCtrl,
                  label: 'Kilometre',
                  hint: 'Örn: 45200',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 10),
                Obx(
                  () => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('İşlem Tarihi', style: TextStyle(fontSize: 14)),
                    subtitle: Text(DateFormatter.formatDate(selectedDate.value)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: selectedDate.value,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) selectedDate.value = picked;
                    },
                  ),
                ),
                AppTextField(
                  controller: noteCtrl,
                  label: 'Açıklama (Opsiyonel)',
                  hint: 'Örn: Shell 45 lt motorin, 10.000 km bakımı...',
                ),
                const SizedBox(height: 20),
                Obx(
                  () => AppButton(
                    text: 'Gideri Kaydet',
                    isLoading: controller.isActionLoading.value,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final cents = CurrencyFormatter.parseToCents(amountCtrl.text);
                      final km = int.tryParse(kmCtrl.text.trim());
                      final ok = await controller.addExpenseRecord(
                        expenseType: selectedType.value,
                        amountCents: cents,
                        date: selectedDate.value,
                        odometerKm: km,
                        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                      );
                      if (ok) {
                        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                        AppSnackbar.showSuccess(
                          'Araç Gideri Kaydedildi',
                          '${selectedType.value.displayName} (${CurrencyFormatter.formatCents(cents)}) eklendi.',
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
