import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/services/tenant_service.dart';
import '../../employees/models/employee_model.dart';
import '../../employees/models/employee_transaction_model.dart';
import '../../expenses/models/expense_category_model.dart';
import '../../expenses/models/expense_model.dart';
import '../../vehicles/models/vehicle_maintenance_model.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../models/report_summary_model.dart';

abstract class IReportRepository {
  Future<ReportSummaryModel> generateReport({required int year, required int month});
  Future<void> saveMonthlyReportSnapshot(ReportSummaryModel report);
}

class ReportRepository implements IReportRepository {
  final TenantService _tenantService = TenantService.to;

  @override
  Future<ReportSummaryModel> generateReport({
    required int year,
    required int month,
  }) async {
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year, 12, 31, 23, 59, 59);

    final results = await Future.wait([
      _tenantService
          .subCollection(AppConstants.subCollectionEmployeeTransactions)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(yearEnd))
          .get(),
      _tenantService
          .subCollection(AppConstants.subCollectionVehicleMaintenance)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(yearEnd))
          .get(),
      _tenantService
          .subCollection(AppConstants.subCollectionExpenses)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(yearEnd))
          .get(),
      _tenantService.subCollection(AppConstants.subCollectionEmployees).get(),
      _tenantService.subCollection(AppConstants.subCollectionVehicles).get(),
      _tenantService.subCollection(AppConstants.subCollectionExpenseCategories).get(),
    ]);

    final txList = results[0].docs
        .map((d) => EmployeeTransactionModel.fromFirestore(d))
        .where((tx) => tx.type != EmployeeTransactionType.deduction)
        .toList();

    final vehicleMaintList = results[1].docs
        .map((d) => VehicleMaintenanceModel.fromFirestore(d))
        .toList();

    final expenseList = results[2].docs
        .map((d) => ExpenseModel.fromFirestore(d))
        .toList();

    final employeeMap = {
      for (final d in results[3].docs) d.id: EmployeeModel.fromFirestore(d),
    };
    final vehicleMap = {
      for (final d in results[4].docs) d.id: VehicleModel.fromFirestore(d),
    };
    final categoryMap = {
      for (final d in results[5].docs) d.id: ExpenseCategoryModel.fromFirestore(d),
    };

    // 1. Aylık trend (1-12 aylar arası, son 6 ayı göstereceğiz)
    final Map<int, int> monthlyPersonnel = {for (int m = 1; m <= 12; m++) m: 0};
    final Map<int, int> monthlyVehicle = {for (int m = 1; m <= 12; m++) m: 0};
    final Map<int, int> monthlyGeneral = {for (int m = 1; m <= 12; m++) m: 0};

    int yearlyTotal = 0;

    // Seçili ay kırılımları
    final Map<String, int> personnelTotals = {};
    final Map<String, int> vehicleTotals = {};
    final Map<String, int> categoryTotals = {};
    final Map<String, Color> categoryColors = {};

    for (final tx in txList) {
      final m = tx.date.month;
      monthlyPersonnel[m] = (monthlyPersonnel[m] ?? 0) + tx.amountCents;
      yearlyTotal += tx.amountCents;

      if (m == month) {
        personnelTotals[tx.employeeId] =
            (personnelTotals[tx.employeeId] ?? 0) + tx.amountCents;
      }
    }

    for (final rec in vehicleMaintList) {
      final m = rec.date.month;
      monthlyVehicle[m] = (monthlyVehicle[m] ?? 0) + rec.amountCents;
      yearlyTotal += rec.amountCents;

      if (m == month) {
        vehicleTotals[rec.vehicleId] =
            (vehicleTotals[rec.vehicleId] ?? 0) + rec.amountCents;
      }
    }

    for (final exp in expenseList) {
      final m = exp.date.month;
      monthlyGeneral[m] = (monthlyGeneral[m] ?? 0) + exp.amountCents;
      yearlyTotal += exp.amountCents;

      if (m == month) {
        final cat = categoryMap[exp.categoryId];
        final catName = cat?.name ?? exp.categoryName ?? 'Diğer';
        final catColor = cat?.color ?? const Color(0xFF0D9488);
        categoryTotals[catName] = (categoryTotals[catName] ?? 0) + exp.amountCents;
        categoryColors[catName] = catColor;
      }
    }

    final monthShortFmt = DateFormat('MMM', 'tr_TR');
    final startM = (month - 5).clamp(1, 12);
    final trends = <MonthlyTrendItem>[];
    for (int m = startM; m <= month; m++) {
      trends.add(
        MonthlyTrendItem(
          year: year,
          month: m,
          label: monthShortFmt.format(DateTime(year, m)),
          personnelCents: monthlyPersonnel[m] ?? 0,
          vehicleCents: monthlyVehicle[m] ?? 0,
          generalCents: monthlyGeneral[m] ?? 0,
        ),
      );
    }

    // Seçili ay toplamları
    final mPersonnel = monthlyPersonnel[month] ?? 0;
    final mVehicle = monthlyVehicle[month] ?? 0;
    final mGeneral = monthlyGeneral[month] ?? 0;
    final mTotal = mPersonnel + mVehicle + mGeneral;

    // Kategori kırılımı (Genel kategoriler + Personel + Araç özetleri)
    final catBreakdown = <CategoryBreakdownItem>[];
    categoryTotals.forEach((name, amount) {
      catBreakdown.add(
        CategoryBreakdownItem(
          name: name,
          amountCents: amount,
          color: categoryColors[name] ?? const Color(0xFF64748B),
        ),
      );
    });
    if (mPersonnel > 0) {
      catBreakdown.add(
        CategoryBreakdownItem(
          name: 'Personel Ödemeleri',
          amountCents: mPersonnel,
          color: const Color(0xFF1E3A8A),
        ),
      );
    }
    if (mVehicle > 0) {
      catBreakdown.add(
        CategoryBreakdownItem(
          name: 'Araç Giderleri',
          amountCents: mVehicle,
          color: const Color(0xFFD97706),
        ),
      );
    }
    catBreakdown.sort((a, b) => b.amountCents.compareTo(a.amountCents));

    // Personel maliyet listesi
    final personnelItems = personnelTotals.entries.map((entry) {
      final emp = employeeMap[entry.key];
      return EntityCostItem(
        id: entry.key,
        title: emp?.fullName ?? 'Personel',
        subtitle: emp?.position ?? emp?.department ?? 'Maaş / Avans / Prim',
        amountCents: entry.value,
      );
    }).toList()
      ..sort((a, b) => b.amountCents.compareTo(a.amountCents));

    // Araç maliyet listesi
    final vehicleItems = vehicleTotals.entries.map((entry) {
      final veh = vehicleMap[entry.key];
      return EntityCostItem(
        id: entry.key,
        title: veh?.plate ?? 'Araç',
        subtitle: veh != null ? '${veh.brand} ${veh.model ?? ''}'.trim() : 'Araç Gideri',
        amountCents: entry.value,
      );
    }).toList()
      ..sort((a, b) => b.amountCents.compareTo(a.amountCents));

    final summary = ReportSummaryModel(
      year: year,
      month: month,
      monthlyTotalCents: mTotal,
      yearlyTotalCents: yearlyTotal,
      monthlyPersonnelCents: mPersonnel,
      monthlyVehicleCents: mVehicle,
      monthlyGeneralCents: mGeneral,
      monthlyTrends: trends,
      categoryBreakdown: catBreakdown,
      personnelCosts: personnelItems,
      vehicleCosts: vehicleItems,
    );

    // Özet dokümanını arka planda Firestore'a kaydet (maliyet optimizasyonu için)
    saveMonthlyReportSnapshot(summary).catchError((_) {});

    return summary;
  }

  @override
  Future<void> saveMonthlyReportSnapshot(ReportSummaryModel report) async {
    if (!_tenantService.hasActiveBusiness) return;
    final periodId = '${report.year}-${report.month.toString().padLeft(2, '0')}';

    final docRef = _tenantService
        .subCollection(AppConstants.subCollectionReports)
        .doc(periodId);

    final doc = await docRef.get();
    final now = Timestamp.now();

    if (doc.exists) {
      await docRef.update({
        'totalExpenseCents': report.monthlyTotalCents,
        'generatedAt': now,
      });
    } else {
      await docRef.set({
        'period': periodId,
        'totalExpenseCents': report.monthlyTotalCents,
        'generatedAt': now,
        'createdAt': now,
      });
    }
  }
}
