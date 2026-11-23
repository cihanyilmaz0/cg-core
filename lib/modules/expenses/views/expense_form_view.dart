import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../employees/models/employee_model.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../controllers/expenses_controller.dart';
import '../models/expense_category_model.dart';

class ExpenseFormView extends GetView<ExpensesController> {
  const ExpenseFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Yeni İşletme Gideri'),
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
                          'Gider Bilgileri',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        Obx(
                          () => DropdownButtonFormField<ExpenseCategoryModel>(
                            initialValue: controller.selectedCategory.value,
                            decoration: const InputDecoration(
                              labelText: 'Kategori *',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: controller.categories
                                .map(
                                  (cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Row(
                                      children: [
                                        Icon(cat.icon, size: 18, color: cat.color),
                                        const SizedBox(width: 8),
                                        Text(cat.name),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => controller.selectedCategory.value = val,
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: controller.titleController,
                          label: 'Gider Başlığı',
                          hint: 'Örn: Ekim Ayı Elektrik Faturası, Mutfak Alışverişi',
                          prefixIcon: const Icon(Icons.title_rounded),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: controller.amountController,
                          label: 'Tutar (₺) *',
                          hint: 'Örn: 1.450,00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [TurkishCurrencyInputFormatter()],
                          prefixIcon: const Icon(Icons.currency_lira_rounded),
                          validator: Validators.positiveAmount,
                        ),
                        const SizedBox(height: 14),
                        Obx(
                          () => DropdownButtonFormField<PaymentMethod>(
                            initialValue: controller.selectedPaymentMethod.value,
                            decoration: const InputDecoration(
                              labelText: 'Ödeme Yöntemi',
                              prefixIcon: Icon(Icons.payment_outlined),
                            ),
                            items: PaymentMethod.values
                                .map((e) => DropdownMenuItem(value: e, child: Text(e.displayName)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) controller.selectedPaymentMethod.value = val;
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(
                          () => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                            title: const Text('Gider Tarihi', style: TextStyle(fontSize: 14)),
                            subtitle: Text(
                              DateFormatter.formatDate(controller.selectedDate.value),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: const Icon(Icons.edit_calendar_outlined),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: controller.selectedDate.value,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) controller.selectedDate.value = picked;
                            },
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
                          'Fiş / Fatura Fotoğrafı (İsteğe Bağlı)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        Obx(() {
                          final file = controller.pickedReceiptFile.value;
                          if (file == null) {
                            return Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => controller.pickReceiptImage(ImageSource.camera),
                                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                                    icon: const Icon(Icons.camera_alt_outlined),
                                    label: const Text('Kamera'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => controller.pickReceiptImage(ImageSource.gallery),
                                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                                    icon: const Icon(Icons.photo_library_outlined),
                                    label: const Text('Galeri'),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb
                                    ? Image.network(file.path, height: 180, fit: BoxFit.cover)
                                    : Image.file(
                                        File(file.path),
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => controller.pickedReceiptFile.value = null,
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                label: const Text(
                                  'Fotoğrafı Kaldır',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                            ],
                          );
                        }),
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
                          'Ek Bağlantılar ve Açıklama',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        Obx(
                          () => DropdownButtonFormField<VehicleModel?>(
                            initialValue: controller.selectedVehicle.value,
                            decoration: const InputDecoration(
                              labelText: 'İlgili Araç (İsteğe Bağlı)',
                              prefixIcon: Icon(Icons.directions_car_outlined),
                            ),
                            items: [
                              const DropdownMenuItem<VehicleModel?>(
                                value: null,
                                child: Text('Seçilmedi'),
                              ),
                              ...controller.vehicles.map(
                                (v) => DropdownMenuItem<VehicleModel?>(
                                  value: v,
                                  child: Text('${v.plate} • ${v.brand}'),
                                ),
                              ),
                            ],
                            onChanged: (val) => controller.selectedVehicle.value = val,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Obx(
                          () => DropdownButtonFormField<EmployeeModel?>(
                            initialValue: controller.selectedEmployee.value,
                            decoration: const InputDecoration(
                              labelText: 'İlgili Personel (İsteğe Bağlı)',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            items: [
                              const DropdownMenuItem<EmployeeModel?>(
                                value: null,
                                child: Text('Seçilmedi'),
                              ),
                              ...controller.employees.map(
                                (e) => DropdownMenuItem<EmployeeModel?>(
                                  value: e,
                                  child: Text(e.fullName),
                                ),
                              ),
                            ],
                            onChanged: (val) => controller.selectedEmployee.value = val,
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: controller.descriptionController,
                          label: 'Açıklama',
                          hint: 'Gider hakkında detaylar...',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => AppButton(
                    text: 'Gideri Kaydet',
                    isLoading: controller.isSaving.value,
                    onPressed: controller.saveExpense,
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
}
