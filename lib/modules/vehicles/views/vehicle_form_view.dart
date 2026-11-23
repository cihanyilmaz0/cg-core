import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../employees/models/employee_model.dart';
import '../controllers/vehicles_controller.dart';

class VehicleFormView extends GetView<VehiclesController> {
  const VehicleFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final isEdit = controller.editingVehicle != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isEdit ? 'Aracı Düzenle' : 'Yeni Araç Ekle'),
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
                          'Temel Araç Bilgileri',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        AppTextField(
                          controller: controller.plateController,
                          label: 'Plaka *',
                          hint: 'Örn: 34 ABC 123',
                          prefixIcon: const Icon(Icons.pin_outlined),
                          validator: (v) =>
                              Validators.requiredField(v, message: 'Plaka zorunludur'),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: controller.brandController,
                                label: 'Marka *',
                                hint: 'Örn: Ford',
                                validator: (v) =>
                                    Validators.requiredField(v, message: 'Marka zorunludur'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: controller.modelController,
                                label: 'Model',
                                hint: 'Örn: Transit',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: controller.yearController,
                                label: 'Model Yılı',
                                hint: 'Örn: 2022',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: controller.vehicleTypeController,
                                label: 'Araç Tipi',
                                hint: 'Panelvan, Binek...',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Obx(
                          () => DropdownButtonFormField<FuelType>(
                            initialValue: controller.selectedFuelType.value,
                            decoration: const InputDecoration(
                              labelText: 'Yakıt Türü',
                              prefixIcon: Icon(Icons.local_gas_station_outlined),
                            ),
                            items: FuelType.values
                                .map((e) => DropdownMenuItem(value: e, child: Text(e.displayName)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) controller.selectedFuelType.value = val;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: controller.currentKmController,
                          label: 'Güncel Kilometre',
                          hint: 'Örn: 45000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          prefixIcon: const Icon(Icons.speed_outlined),
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
                          'Sorumlu & Resmi Tarihler',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        Obx(
                          () => DropdownButtonFormField<EmployeeModel?>(
                            initialValue: controller.selectedEmployee.value,
                            decoration: const InputDecoration(
                              labelText: 'Araç Sorumlusu (Opsiyonel)',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            items: [
                              const DropdownMenuItem<EmployeeModel?>(
                                value: null,
                                child: Text('Atanmamış'),
                              ),
                              ...controller.availableEmployees.map(
                                (emp) => DropdownMenuItem<EmployeeModel?>(
                                  value: emp,
                                  child: Text(emp.fullName),
                                ),
                              ),
                            ],
                            onChanged: (val) => controller.selectedEmployee.value = val,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _datePickerTile(
                          context: context,
                          title: 'Trafik Sigortası Bitiş Tarihi',
                          dateRx: controller.insuranceExpiryDate,
                          icon: Icons.security_outlined,
                        ),
                        _datePickerTile(
                          context: context,
                          title: 'Kasko Bitiş Tarihi',
                          dateRx: controller.cascoExpiryDate,
                          icon: Icons.verified_user_outlined,
                        ),
                        _datePickerTile(
                          context: context,
                          title: 'Muayene Bitiş Tarihi',
                          dateRx: controller.inspectionExpiryDate,
                          icon: Icons.fact_check_outlined,
                        ),
                        const Divider(),
                        Obx(
                          () => SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Aktif Araç'),
                            subtitle: const Text('Pasif yapılan araçlar operasyon listesinde gizlenir'),
                            value: controller.isActive.value,
                            onChanged: (val) => controller.isActive.value = val,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => AppButton(
                    text: isEdit ? 'Değişiklikleri Kaydet' : 'Aracı Kaydet',
                    isLoading: controller.isSaving.value,
                    onPressed: controller.saveVehicle,
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

  Widget _datePickerTile({
    required BuildContext context,
    required String title,
    required Rxn<DateTime> dateRx,
    required IconData icon,
  }) {
    return Obx(
      () => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          dateRx.value != null ? DateFormatter.formatDate(dateRx.value) : 'Belirtilmemiş',
          style: TextStyle(
            fontWeight: dateRx.value != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dateRx.value != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => dateRx.value = null,
              ),
            const Icon(Icons.edit_calendar_outlined),
          ],
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: dateRx.value ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2040),
          );
          if (picked != null) {
            dateRx.value = picked;
          }
        },
      ),
    );
  }
}
