import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import '../controllers/employee_detail_controller.dart';
import '../controllers/employees_controller.dart';
import '../models/employee_leave_record_model.dart';
import '../models/employee_model.dart';
import '../models/employee_monthly_summary_model.dart';
import '../models/employee_salary_history_model.dart';
import '../models/employee_transaction_model.dart';

class EmployeeDetailView extends GetView<EmployeeDetailController> {
  const EmployeeDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Obx(() => Text(controller.employee.value?.fullName ?? 'Personel Detayı')),
          actions: [
            Obx(() {
              final emp = controller.employee.value;
              if (emp == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Personeli Düzenle',
                onPressed: () async {
                  final listCtrl = Get.find<EmployeesController>();
                  listCtrl.initFormForEdit(emp);
                  final updated = await Get.toNamed(AppRoutes.employeeForm);
                  if (updated == true) {
                    controller.loadAllDetails(emp.id);
                  }
                },
              );
            }),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.employee.value == null) {
            return const LoadingView(message: 'Personel detayları yükleniyor...');
          }

          if (controller.errorMessage.value.isNotEmpty && controller.employee.value == null) {
            return ErrorStateView(
              message: controller.errorMessage.value,
              onRetry: () {
                final id = controller.employee.value?.id;
                if (id != null) controller.loadAllDetails(id);
              },
            );
          }

          final emp = controller.employee.value;
          if (emp == null) {
            return const EmptyStateView(title: 'Personel bulunamadı');
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildProfileHeader(context, emp),
                    _buildQuickActionRow(context),
                    _buildMonthSelector(),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  const TabBar(
                    isScrollable: false,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondaryLight,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 2.5,
                    labelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                    tabs: [
                      Tab(text: 'Özet'),
                      Tab(text: 'Hareketler'),
                      Tab(text: 'İzinler'),
                      Tab(text: 'Maaş'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _buildSummaryTab(),
                _buildTransactionsTab(context),
                _buildLeavesTab(context),
                _buildSalaryHistoryTab(),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, EmployeeModel emp) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            emp.fullName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: emp.isActive
                                ? AppColors.success.withValues(alpha: 0.12)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            emp.isActive ? 'Aktif' : 'Pasif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: emp.isActive ? AppColors.success : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (emp.position != null && emp.position!.isNotEmpty) emp.position!,
                        if (emp.department != null && emp.department!.isNotEmpty) emp.department!,
                      ].join(' • '),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                    if (emp.phone != null && emp.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        emp.phone!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Güncel ${emp.salaryType.displayName} Maaş',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.formatCents(emp.baseSalaryCents),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _showSalaryUpdateDialog(context, emp),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.trending_up_rounded, size: 18),
                label: const Text('Maaş Güncelle', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionRow(BuildContext context) {
    final actions = [
      (
        label: 'Avans',
        icon: Icons.payments_outlined,
        color: AppColors.warning,
        onTap: () => _showTransactionModal(context, EmployeeTransactionType.advance),
      ),
      (
        label: 'Maaş Öde',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.secondary,
        onTap: () => _showTransactionModal(context, EmployeeTransactionType.salaryPayment),
      ),
      (
        label: 'Prim',
        icon: Icons.add_circle_outline_rounded,
        color: AppColors.success,
        onTap: () => _showTransactionModal(context, EmployeeTransactionType.bonus),
      ),
      (
        label: 'Kesinti',
        icon: Icons.remove_circle_outline_rounded,
        color: AppColors.error,
        onTap: () => _showTransactionModal(context, EmployeeTransactionType.deduction),
      ),
      (
        label: 'İzin Ekle',
        icon: Icons.event_note_rounded,
        color: AppColors.primary,
        onTap: () => _showLeaveModal(context),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: actions.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < actions.length - 1 ? 8 : 0),
              child: _actionTile(
                label: item.label,
                icon: item.icon,
                color: item.color,
                onTap: item.onTap,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _actionTile({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                label,
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
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                letterSpacing: 0.6,
                color: AppColors.textPrimaryLight,
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

  Widget _buildSummaryTab() {
    return Obx(() {
      final EmployeeMonthlySummaryModel? summary = controller.monthlySummary.value;
      if (summary == null) {
        return const LoadingView();
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ay Sonu Kalan Ödenecek Tutar',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.formatCents(summary.remainingBalanceCents),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hakediş + Ek Ödeme - Avans - Ödeme - Kesinti',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _summaryRow(
                      'Dönem Baz Maaşı',
                      CurrencyFormatter.formatCents(summary.baseSalaryCents),
                    ),
                    _summaryRow(
                      'Ücretsiz İzin / Devamsızlık',
                      '${summary.unpaidLeaveDays} gün',
                      valueColor: summary.unpaidLeaveDays > 0 ? AppColors.error : null,
                    ),
                    _summaryRow(
                      'Ücretli / Mazeretli İzin',
                      '${summary.paidLeaveDays} gün',
                    ),
                    const Divider(),
                    _summaryRow(
                      'Hesaplanan Hakediş (${controller.monthBasisDays.value} gün bazlı)',
                      CurrencyFormatter.formatCents(summary.earnedSalaryCents),
                      isBold: true,
                    ),
                    _summaryRow(
                      '+ Ek Ödeme ve Primler',
                      CurrencyFormatter.formatCents(summary.bonusCents),
                      valueColor: AppColors.success,
                    ),
                    _summaryRow(
                      '- Verilen Avanslar',
                      CurrencyFormatter.formatCents(summary.advanceCents),
                      valueColor: AppColors.warning,
                    ),
                    _summaryRow(
                      '- Yapılan Maaş Ödemeleri',
                      CurrencyFormatter.formatCents(summary.salaryPaymentCents),
                      valueColor: AppColors.secondary,
                    ),
                    _summaryRow(
                      '- Kesintiler',
                      CurrencyFormatter.formatCents(summary.deductionCents),
                      valueColor: AppColors.error,
                    ),
                    const Divider(),
                    _summaryRow(
                      'Kalan Tutar',
                      CurrencyFormatter.formatCents(summary.remainingBalanceCents),
                      isBold: true,
                      valueColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: Colors.amber.shade900),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bilgilendirme: Bu hesap özeti işletme içi takip amaçlıdır; resmî bordro veya SGK hesaplaması yerine geçmez.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(BuildContext context) {
    return Obx(() {
      final list = controller.currentMonthTransactions;
      if (list.isEmpty) {
        return EmptyStateView(
          title: 'Bu Ay Hareket Yok',
          message: 'Seçili aya ait avans, maaş ödemesi, prim veya kesinti kaydı bulunmuyor.',
          icon: Icons.receipt_long_outlined,
          actionText: 'Avans / Ödeme Ekle',
          onAction: () => _showTransactionModal(context, EmployeeTransactionType.advance),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final EmployeeTransactionModel tx = list[index];
          final color = _txColor(tx.type);
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(_txIcon(tx.type), color: color, size: 20),
              ),
              title: Text(
                tx.type.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                '${DateFormatter.formatDate(tx.date)}${tx.description != null ? ' • ${tx.description}' : ''}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyFormatter.formatCents(tx.amountCents),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMutedLight),
                    onPressed: () => _confirmDelete(
                      context,
                      'Hareketi Sil',
                      'Bu finansal kaydı silmek istediğinize emin misiniz?',
                      () => controller.deleteTransaction(tx.id),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildLeavesTab(BuildContext context) {
    return Obx(() {
      final list = controller.currentMonthLeaves;
      if (list.isEmpty) {
        return EmptyStateView(
          title: 'Bu Ay İzin Kaydı Yok',
          message: 'Seçili aya ait ücretli veya ücretsiz izin kaydı bulunmuyor.',
          icon: Icons.event_available_outlined,
          actionText: 'İzin Kaydı Oluştur',
          onAction: () => _showLeaveModal(context),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final EmployeeLeaveRecordModel leave = list[index];
          final isUnpaid = leave.leaveType == LeaveType.unpaidLeave ||
              leave.leaveType == LeaveType.unexcusedAbsence;
          final color = isUnpaid ? AppColors.error : AppColors.secondary;

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(Icons.event_note_rounded, color: color, size: 20),
              ),
              title: Text(
                '${leave.leaveType.displayName} (${leave.totalDays} Gün)',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                '${DateFormatter.formatDate(leave.startDate)} - ${DateFormatter.formatDate(leave.endDate)}${leave.note != null ? '\n${leave.note}' : ''}',
                style: const TextStyle(fontSize: 12),
              ),
              isThreeLine: leave.note != null,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMutedLight),
                onPressed: () => _confirmDelete(
                  context,
                  'İzni Sil',
                  'Bu izin kaydını silmek istediğinize emin misiniz?',
                  () => controller.deleteLeaveRecord(leave.id),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildSalaryHistoryTab() {
    return Obx(() {
      final list = controller.salaryHistory;
      if (list.isEmpty) {
        return const EmptyStateView(
          title: 'Maaş Değişikliği Geçmişi Yok',
          message: 'Personelin maaşı güncellendiğinde eski ve yeni maaş tutarları burada arşivlenir.',
          icon: Icons.history_rounded,
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final EmployeeSalaryHistoryModel item = list[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.trending_up_rounded, color: AppColors.primary),
              ),
              title: Text(
                '${CurrencyFormatter.formatCents(item.previousSalaryCents)} → ${CurrencyFormatter.formatCents(item.newSalaryCents)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                'Geçerlilik: ${DateFormatter.formatDate(item.changeDate)}${item.note != null ? '\nNot: ${item.note}' : ''}',
                style: const TextStyle(fontSize: 12),
              ),
              isThreeLine: item.note != null,
            ),
          );
        },
      );
    });
  }

  Color _txColor(EmployeeTransactionType type) {
    switch (type) {
      case EmployeeTransactionType.advance:
        return AppColors.warning;
      case EmployeeTransactionType.salaryPayment:
        return AppColors.secondary;
      case EmployeeTransactionType.bonus:
      case EmployeeTransactionType.otherPayment:
        return AppColors.success;
      case EmployeeTransactionType.deduction:
        return AppColors.error;
    }
  }

  IconData _txIcon(EmployeeTransactionType type) {
    switch (type) {
      case EmployeeTransactionType.advance:
        return Icons.payments_outlined;
      case EmployeeTransactionType.salaryPayment:
        return Icons.account_balance_wallet_outlined;
      case EmployeeTransactionType.bonus:
      case EmployeeTransactionType.otherPayment:
        return Icons.add_circle_outline_rounded;
      case EmployeeTransactionType.deduction:
        return Icons.remove_circle_outline_rounded;
    }
  }

  void _confirmDelete(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onConfirm();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showSalaryUpdateDialog(BuildContext context, EmployeeModel emp) {
    final formKey = GlobalKey<FormState>();
    final salaryCtrl = TextEditingController(
      text: CurrencyFormatter.formatCents(emp.baseSalaryCents, includeSymbol: false),
    );
    final noteCtrl = TextEditingController();
    final selectedDate = DateTime.now().obs;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Maaş Güncelle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: salaryCtrl,
                label: 'Yeni Maaş Tutarı (₺)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [TurkishCurrencyInputFormatter()],
                validator: Validators.positiveAmount,
              ),
              const SizedBox(height: 12),
              Obx(
                () => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Geçerlilik Tarihi', style: TextStyle(fontSize: 13)),
                  subtitle: Text(DateFormatter.formatDate(selectedDate.value)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
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
                hint: 'Örn: Yıl sonu zammı',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isActionLoading.value
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final ok = await controller.updateSalary(
                        newSalaryText: salaryCtrl.text,
                        changeDate: selectedDate.value,
                        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                      );
                      if (ok) {
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                        AppSnackbar.showSuccess(
                          'Maaş Güncellendi',
                          'Yeni maaş kaydedildi ve geçmişe eklendi.',
                        );
                      }
                    },
              child: const Text('Kaydet'),
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionModal(BuildContext context, EmployeeTransactionType initialType) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
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
                  'Finansal Hareket Ekle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => DropdownButtonFormField<EmployeeTransactionType>(
                    initialValue: selectedType.value,
                    decoration: const InputDecoration(labelText: 'İşlem Türü'),
                    items: EmployeeTransactionType.values
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
                  hint: 'Örn: 2.500,00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [TurkishCurrencyInputFormatter()],
                  validator: Validators.positiveAmount,
                ),
                const SizedBox(height: 12),
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
                  controller: descCtrl,
                  label: 'Açıklama (Opsiyonel)',
                  hint: 'Örn: Haftalık avans, yemek primi...',
                ),
                const SizedBox(height: 20),
                Obx(
                  () => AppButton(
                    text: 'Hareketi Kaydet',
                    isLoading: controller.isActionLoading.value,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final cents = CurrencyFormatter.parseToCents(amountCtrl.text);
                      final ok = await controller.addTransaction(
                        type: selectedType.value,
                        amountCents: cents,
                        date: selectedDate.value,
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      );
                      if (ok) {
                        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                        AppSnackbar.showSuccess(
                          'İşlem Kaydedildi',
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

  void _showLeaveModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final noteCtrl = TextEditingController();
    final selectedType = LeaveType.unpaidLeave.obs;
    final startDate = DateTime.now().obs;
    final endDate = DateTime.now().obs;

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
                  'İzin Kaydı Oluştur',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => DropdownButtonFormField<LeaveType>(
                    initialValue: selectedType.value,
                    decoration: const InputDecoration(labelText: 'İzin Türü'),
                    items: LeaveType.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.displayName)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) selectedType.value = val;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.date_range_outlined),
                    title: const Text('Başlangıç Tarihi', style: TextStyle(fontSize: 14)),
                    subtitle: Text(DateFormatter.formatDate(startDate.value)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: startDate.value,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        startDate.value = picked;
                        if (endDate.value.isBefore(picked)) {
                          endDate.value = picked;
                        }
                      }
                    },
                  ),
                ),
                Obx(
                  () => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Bitiş Tarihi', style: TextStyle(fontSize: 14)),
                    subtitle: Text(DateFormatter.formatDate(endDate.value)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: endDate.value,
                        firstDate: startDate.value,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) endDate.value = picked;
                    },
                  ),
                ),
                AppTextField(
                  controller: noteCtrl,
                  label: 'Açıklama (Opsiyonel)',
                  hint: 'Örn: Sağlık raporu, yıllık izin...',
                ),
                const SizedBox(height: 20),
                Obx(
                  () => AppButton(
                    text: 'İzin Kaydını Kaydet',
                    isLoading: controller.isActionLoading.value,
                    onPressed: () async {
                      final ok = await controller.addLeaveRecord(
                        leaveType: selectedType.value,
                        startDate: startDate.value,
                        endDate: endDate.value,
                        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                      );
                      if (ok) {
                        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                        AppSnackbar.showSuccess(
                          'İzin Kaydedildi',
                          '${selectedType.value.displayName} kaydı oluşturuldu.',
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
