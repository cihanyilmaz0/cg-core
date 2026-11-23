import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/employees_controller.dart';

class EmployeeFormView extends GetView<EmployeesController> {
  const EmployeeFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final isEdit = controller.editingEmployee != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isEdit ? 'Personeli Düzenle' : 'Yeni Personel Ekle'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kimlik ve İletişim Bilgileri',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        AppTextField(
                          controller: controller.fullNameController,
                          label: 'Ad Soyad *',
                          hint: 'Örn: Mehmet Demir',
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: (v) =>
                              Validators.requiredField(v, message: 'Ad soyad zorunludur'),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: controller.phoneController,
                          label: 'Telefon',
                          hint: '05XX XXX XX XX',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: controller.emailController,
                          label: 'E-posta (İsteğe Bağlı)',
                          hint: 'mehmet@ornek.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Görev ve Ücret Bilgileri',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        AppTextField(
                          controller: controller.positionController,
                          label: 'Görev / Pozisyon',
                          hint: 'Örn: Garson, Şoför, Usta',
                          prefixIcon: const Icon(Icons.work_outline),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: controller.departmentController,
                          label: 'Departman',
                          hint: 'Örn: Mutfak, Lojistik, Üretim',
                          prefixIcon: const Icon(Icons.apartment_outlined),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Maaş Türü',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Obx(
                          () => Container(
                            height: 46,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.dividerLight),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _salaryTypeTab(
                                    label: 'Aylık Maaş',
                                    icon: Icons.calendar_month_outlined,
                                    type: SalaryType.monthly,
                                  ),
                                ),
                                Expanded(
                                  child: _salaryTypeTab(
                                    label: 'Günlük Yevmiye',
                                    icon: Icons.today_outlined,
                                    type: SalaryType.daily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Obx(
                          () => AppTextField(
                            controller: controller.salaryController,
                            label: controller.selectedSalaryType.value == SalaryType.monthly
                                ? 'Aylık Maaş Tutarı (₺) *'
                                : 'Günlük Ücret (₺) *',
                            hint: 'Örn: 22.500,00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [TurkishCurrencyInputFormatter()],
                            prefixIcon: const Icon(Icons.currency_lira_rounded),
                            validator: Validators.positiveAmount,
                          ),
                        ),
                        if (isEdit)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'Not: Zam veya maaş değişikliği için personel detay ekranındaki "Maaş Güncelle" butonunu kullanmanız önerilir.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tarihler ve Durum',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        Obx(
                          () => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.event_available_outlined, color: AppColors.primary),
                            title: const Text('İşe Giriş Tarihi', style: TextStyle(fontSize: 14)),
                            subtitle: Text(
                              DateFormatter.formatDate(controller.selectedStartDate.value),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: const Icon(Icons.edit_calendar_outlined),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: controller.selectedStartDate.value,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                controller.selectedStartDate.value = picked;
                              }
                            },
                          ),
                        ),
                        Obx(
                          () => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.event_busy_outlined, color: AppColors.textSecondaryLight),
                            title: const Text('İşten Çıkış Tarihi (Opsiyonel)', style: TextStyle(fontSize: 14)),
                            subtitle: Text(
                              controller.selectedEndDate.value != null
                                  ? DateFormatter.formatDate(controller.selectedEndDate.value)
                                  : 'Belirtilmemiş (Devam ediyor)',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (controller.selectedEndDate.value != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => controller.selectedEndDate.value = null,
                                  ),
                                const Icon(Icons.edit_calendar_outlined),
                              ],
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: controller.selectedEndDate.value ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                controller.selectedEndDate.value = picked;
                              }
                            },
                          ),
                        ),
                        const Divider(),
                        Obx(
                          () => SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Aktif Personel'),
                            subtitle: const Text('Pasif yapılan personeller maaş özetlerinde gizlenir'),
                            value: controller.isActive.value,
                            onChanged: (val) => controller.isActive.value = val,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: controller.notesController,
                          label: 'Açıklama / Notlar',
                          hint: 'Personel hakkında ek notlar...',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => AppButton(
                    text: isEdit ? 'Değişiklikleri Kaydet' : 'Personeli Kaydet',
                    isLoading: controller.isSaving.value,
                    onPressed: controller.saveEmployee,
                    icon: Icons.save_rounded,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _salaryTypeTab({
    required String label,
    required IconData icon,
    required SalaryType type,
  }) {
    final isSelected = controller.selectedSalaryType.value == type;
    return GestureDetector(
      onTap: () => controller.selectedSalaryType.value = type,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
