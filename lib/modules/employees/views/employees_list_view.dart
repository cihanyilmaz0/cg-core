import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../controllers/employees_controller.dart';
import '../models/employee_model.dart';

class EmployeesListView extends GetView<EmployeesController> {
  const EmployeesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personeller',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '${controller.activeEmployeeCount} aktif personel',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadEmployees,
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.initFormForCreate();
          Get.toNamed(AppRoutes.employeeForm);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Personel Ekle'),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const LoadingView(message: 'Personeller yükleniyor...');
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return ErrorStateView(
                  message: controller.errorMessage.value,
                  onRetry: controller.loadEmployees,
                );
              }

              final list = controller.filteredEmployees;
              if (list.isEmpty) {
                return EmptyStateView(
                  title: controller.employees.isEmpty
                      ? 'Henüz Personel Kaydı Yok'
                      : 'Sonuç Bulunamadı',
                  message: controller.employees.isEmpty
                      ? 'İşletmenizdeki personelleri ekleyerek maaş, avans ve izin takibine başlayabilirsiniz.'
                      : 'Arama kriterlerinize uygun personel bulunamadı.',
                  icon: Icons.groups_outlined,
                  actionText: controller.employees.isEmpty ? 'Personel Ekle' : null,
                  onAction: controller.employees.isEmpty
                      ? () {
                          controller.initFormForCreate();
                          Get.toNamed(AppRoutes.employeeForm);
                        }
                      : null,
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadEmployees,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildEmployeeCard(list[index]);
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
              hintText: 'Ad, pozisyon veya departman ara...',
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
                  Expanded(child: _filterTab('Aktif', EmployeeStatusFilter.active)),
                  Expanded(child: _filterTab('Pasif', EmployeeStatusFilter.passive)),
                  Expanded(child: _filterTab('Tümü', EmployeeStatusFilter.all)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab(String label, EmployeeStatusFilter filter) {
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

  Widget _buildEmployeeCard(EmployeeModel employee) {
    final initials = _getInitials(employee.fullName);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed(AppRoutes.employeeDetail, arguments: employee),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: employee.isActive
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.grey.shade200,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: employee.isActive ? AppColors.primary : Colors.grey.shade600,
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
                            employee.fullName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!employee.isActive)
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildSubtitle(employee),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${CurrencyFormatter.formatCents(employee.baseSalaryCents)} / ${employee.salaryType.displayName}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMutedLight),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _buildSubtitle(EmployeeModel employee) {
    final parts = <String>[];
    if (employee.position != null && employee.position!.isNotEmpty) {
      parts.add(employee.position!);
    }
    if (employee.department != null && employee.department!.isNotEmpty) {
      parts.add(employee.department!);
    }
    if (parts.isEmpty && employee.phone != null && employee.phone!.isNotEmpty) {
      return employee.phone!;
    }
    return parts.isEmpty ? 'Görev belirtilmemiş' : parts.join(' • ');
  }
}
