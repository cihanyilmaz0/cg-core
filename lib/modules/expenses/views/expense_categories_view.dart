import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../controllers/expenses_controller.dart';

class ExpenseCategoriesView extends GetView<ExpensesController> {
  const ExpenseCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Gider Kategorileri'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryModal(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kategori Ekle'),
      ),
      body: Obx(() {
        final list = controller.categories;
        if (list.isEmpty) {
          return EmptyStateView(
            title: 'Henüz Kategori Yok',
            message: 'İşletmeniz için özel gider kategorileri oluşturabilirsiniz.',
            icon: Icons.category_outlined,
            actionText: 'Kategori Ekle',
            onAction: () => _showAddCategoryModal(context),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final cat = list[index];
            return Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 20),
                ),
                title: Text(
                  cat.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                subtitle: Text(
                  cat.isDefault ? 'Varsayılan Kategori' : 'Özel Kategori',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMutedLight),
                  onPressed: () => _confirmDelete(context, cat.id, cat.name),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showAddCategoryModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();

    final iconOptions = [
      ('receipt_long', Icons.receipt_long_rounded),
      ('restaurant', Icons.restaurant_rounded),
      ('cleaning_services', Icons.cleaning_services_rounded),
      ('home_work', Icons.home_work_rounded),
      ('bolt', Icons.bolt_rounded),
      ('local_shipping', Icons.local_shipping_rounded),
      ('business_center', Icons.business_center_rounded),
      ('inventory_2', Icons.inventory_2_rounded),
    ];

    final colorOptions = [
      '#1E3A8A',
      '#0D9488',
      '#F97316',
      '#EF4444',
      '#8B5CF6',
      '#EAB308',
      '#3B82F6',
      '#64748B',
    ];

    final selectedIcon = 'receipt_long'.obs;
    final selectedColor = '#1E3A8A'.obs;

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
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Yeni Gider Kategorisi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: nameCtrl,
                label: 'Kategori Adı *',
                hint: 'Örn: Reklam & Pazarlama, Vergi, Bakım...',
                validator: (v) =>
                    Validators.requiredField(v, message: 'Kategori adı zorunludur'),
              ),
              const SizedBox(height: 14),
              const Text('İkon Seçimi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: iconOptions.map((item) {
                    final isSelected = selectedIcon.value == item.$1;
                    return InkWell(
                      onTap: () => selectedIcon.value = item.$1,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.dividerLight,
                          ),
                        ),
                        child: Icon(
                          item.$2,
                          color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Renk Seçimi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 10,
                  children: colorOptions.map((hex) {
                    final isSelected = selectedColor.value == hex;
                    final col = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                    return InkWell(
                      onTap: () => selectedColor.value = hex,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black, width: 2.5) : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => AppButton(
                  text: 'Kategoriyi Kaydet',
                  isLoading: controller.isSaving.value,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final ok = await controller.addCategory(
                      nameCtrl.text,
                      selectedIcon.value,
                      selectedColor.value,
                    );
                    if (ok) {
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                      AppSnackbar.showSuccess(
                        'Kategori Eklendi',
                        '${nameCtrl.text.trim()} kategorisi oluşturuldu.',
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String categoryId, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text('"$name" kategorisini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.deleteCategory(categoryId);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
