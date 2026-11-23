import 'dart:math';
import '../../../core/constants/app_enums.dart';
import '../models/vehicle_cost_summary_model.dart';
import '../models/vehicle_maintenance_model.dart';

class VehicleCostCalculator {
  VehicleCostCalculator._();

  static VehicleCostSummaryModel calculateSummary({
    required List<VehicleMaintenanceModel> records,
    required int year,
    required int month,
  }) {
    int totalCostCents = 0;
    int monthlyTotalCostCents = 0;
    int monthlyFuelCostCents = 0;
    int monthlyMaintenanceCostCents = 0;

    int? minKm;
    int? maxKm;

    for (final rec in records) {
      totalCostCents += rec.amountCents;

      if (rec.odometerKm != null && rec.odometerKm! > 0) {
        minKm = minKm == null ? rec.odometerKm! : min(minKm, rec.odometerKm!);
        maxKm = maxKm == null ? rec.odometerKm! : max(maxKm, rec.odometerKm!);
      }

      if (rec.date.year == year && rec.date.month == month) {
        monthlyTotalCostCents += rec.amountCents;

        if (rec.expenseType == VehicleExpenseType.fuel) {
          monthlyFuelCostCents += rec.amountCents;
        } else if (rec.expenseType == VehicleExpenseType.maintenance ||
            rec.expenseType == VehicleExpenseType.repair ||
            rec.expenseType == VehicleExpenseType.tire) {
          monthlyMaintenanceCostCents += rec.amountCents;
        }
      }
    }

    int? costPerKmCents;
    int trackedKmDelta = 0;
    if (minKm != null && maxKm != null && maxKm > minKm) {
      trackedKmDelta = maxKm - minKm;
      costPerKmCents = (totalCostCents / trackedKmDelta).round();
    }

    return VehicleCostSummaryModel(
      totalCostCents: totalCostCents,
      monthlyTotalCostCents: monthlyTotalCostCents,
      monthlyFuelCostCents: monthlyFuelCostCents,
      monthlyMaintenanceCostCents: monthlyMaintenanceCostCents,
      costPerKmCents: costPerKmCents,
      trackedKmDelta: trackedKmDelta,
    );
  }

  /// Tarihe kalan gün sayısını döndürür (negatifse süresi geçmiştir).
  static int daysRemaining(DateTime? targetDate, {DateTime? now}) {
    if (targetDate == null) return 9999;
    final ref = now ?? DateTime.now();
    final normRef = DateTime(ref.year, ref.month, ref.day);
    final normTarget = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return normTarget.difference(normRef).inDays;
  }
}
