import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../controllers/expenses_controller.dart';
import '../models/expense_model.dart';

class ExpensesListView extends GetView<ExpensesController> {
  const ExpensesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'İşletme Giderleri',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Kategorileri Yönet',
            onPressed: () => Get.toNamed(AppRoutes.expenseCategories),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: controller.loadInitialData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await controller.initForm();
          Get.toNamed(AppRoutes.expenseForm);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Gider Ekle'),
      ),
      body: Column(
        children: [
          _buildTopFiltersAndSummary(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const LoadingView(message: 'Giderler yükleniyor...');
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return ErrorStateView(
                  message: controller.errorMessage.value,
                  onRetry: controller.loadInitialData,
                );
              }

              final list = controller.filteredExpenses;
              if (list.isEmpty) {
                return EmptyStateView(
                  title: 'Bu Ay Gider Kaydı Yok',
                  message: 'Kira, elektrik, mutfak veya diğer işletme giderlerinizi fiş fotoğrafıyla birlikte kaydedebilirsiniz.',
                  icon: Icons.receipt_long_outlined,
                  actionText: 'Gider Ekle',
                  onAction: () async {
                    await controller.initForm();
                    Get.toNamed(AppRoutes.expenseForm);
                  },
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadExpensesForMonth,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildExpenseCard(context, list[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFiltersAndSummary() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          // Ay seçici ve toplam tutar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: controller.previousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Obx(
                () => Column(
                  children: [
                    Text(
                      DateFormatter.formatMonthYear(controller.selectedMonth.value).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Toplam: ${CurrencyFormatter.formatCents(controller.filteredTotalCents)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: controller.nextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: controller.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Gider ara...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Obx(
                  () => DropdownButtonFormField<String?>(
                    initialValue: controller.selectedCategoryFilterId.value,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    hint: const Text('Tümü', style: TextStyle(fontSize: 13)),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tüm Kategoriler', style: TextStyle(fontSize: 12.5)),
                      ),
                      ...controller.categories.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(
                            c.name,
                            style: const TextStyle(fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: controller.setCategoryFilter,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, ExpenseModel expense) {
    final category = controller.findCategory(expense.categoryId);
    final catColor = category?.color ?? AppColors.secondary;
    final catIcon = category?.icon ?? Icons.receipt_long_rounded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(catIcon, color: catColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title ?? expense.categoryName ?? 'İşletme Gideri',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${expense.categoryName ?? category?.name ?? 'Genel'} • ${expense.paymentMethod.displayName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormatter.formatDate(expense.date)}${expense.description != null ? ' • ${expense.description}' : ''}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMutedLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatCents(expense.amountCents),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (expense.receiptUrl != null && expense.receiptUrl!.isNotEmpty)
                      InkWell(
                        onTap: () => _showReceiptPreview(context, expense.receiptUrl!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.image_outlined, size: 13, color: AppColors.info),
                              SizedBox(width: 3),
                              Text('Fiş', style: TextStyle(fontSize: 11, color: AppColors.info)),
                            ],
                          ),
                        ),
                      ),
                    InkWell(
                      onTap: () => _confirmDelete(context, expense.id),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptPreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Fiş / Fatura Görseli', style: TextStyle(fontSize: 16)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
            InteractiveViewer(
              child: url.startsWith('data:image/')
                  ? Image.memory(
                      base64Decode(url.split(',').last),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Görsel çözümlenemedi.'),
                      ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Görsel yüklenemedi.'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String expenseId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gideri Sil'),
        content: const Text('Bu gider kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.deleteExpense(expenseId);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
