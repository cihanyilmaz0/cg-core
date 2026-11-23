import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../controllers/vehicles_controller.dart';
import '../models/vehicle_model.dart';
import '../utils/vehicle_cost_calculator.dart';

class VehiclesListView extends GetView<VehiclesController> {
  const VehiclesListView({super.key});

  @override
  Widget build(BuildContext context) {
    final kmFormatter = NumberFormat('#,##0', 'tr_TR');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Araçlar',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              Text(
                '${controller.activeVehicleCount} aktif araç',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadVehicles,
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.initFormForCreate();
          Get.toNamed(AppRoutes.vehicleForm);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Araç Ekle'),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const LoadingView(message: 'Araçlar yükleniyor...');
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return ErrorStateView(
                  message: controller.errorMessage.value,
                  onRetry: controller.loadVehicles,
                );
              }

              final list = controller.filteredVehicles;
              if (list.isEmpty) {
                return EmptyStateView(
                  title: controller.vehicles.isEmpty
                      ? 'Henüz Araç Kaydı Yok'
                      : 'Sonuç Bulunamadı',
                  message: controller.vehicles.isEmpty
                      ? 'İşletme araçlarınızı ekleyerek yakıt, bakım, sigorta ve muayene giderlerini takip edebilirsiniz.'
                      : 'Arama kriterlerinize uygun araç bulunamadı.',
                  icon: Icons.directions_car_outlined,
                  actionText: controller.vehicles.isEmpty ? 'Araç Ekle' : null,
                  onAction: controller.vehicles.isEmpty
                      ? () {
                          controller.initFormForCreate();
                          Get.toNamed(AppRoutes.vehicleForm);
                        }
                      : null,
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadVehicles,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildVehicleCard(list[index], kmFormatter);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          TextField(
            onChanged: controller.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Plaka, marka veya model ara...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.backgroundLight,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Container(
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.dividerLight),
              ),
              child: Row(
                children: [
                  Expanded(child: _filterTab('Aktif', VehicleStatusFilter.active)),
                  Expanded(child: _filterTab('Pasif', VehicleStatusFilter.passive)),
                  Expanded(child: _filterTab('Tümü', VehicleStatusFilter.all)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab(String label, VehicleStatusFilter filter) {
    final isSelected = controller.statusFilter.value == filter;
    return GestureDetector(
      onTap: () => controller.setStatusFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle, NumberFormat kmFormatter) {
    final warningText = _getExpiryWarning(vehicle);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed(AppRoutes.vehicleDetail, arguments: vehicle),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      vehicle.plate,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicle.brand} ${vehicle.model ?? ''}'.trim(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vehicle.fuelType.displayName} • ${kmFormatter.format(vehicle.currentKm)} km',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!vehicle.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Pasif',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMutedLight),
                ],
              ),
              if (vehicle.assignedEmployeeName != null || warningText != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (vehicle.assignedEmployeeName != null)
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.assignedEmployeeName!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                    if (warningText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              warningText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _getExpiryWarning(VehicleModel v) {
    final checks = [
      ('Sigorta', v.insuranceExpiryDate),
      ('Kasko', v.cascoExpiryDate),
      ('Muayene', v.inspectionExpiryDate),
    ];

    for (final (label, date) in checks) {
      if (date == null) continue;
      final days = VehicleCostCalculator.daysRemaining(date);
      if (days < 0) return '$label süresi doldu';
      if (days <= 30) return '$label: $days gün';
    }
    return null;
  }
}
