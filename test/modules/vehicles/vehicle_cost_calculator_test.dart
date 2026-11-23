import 'package:flutter_test/flutter_test.dart';
import 'package:saas_isletme/core/constants/app_enums.dart';
import 'package:saas_isletme/modules/vehicles/models/vehicle_maintenance_model.dart';
import 'package:saas_isletme/modules/vehicles/utils/vehicle_cost_calculator.dart';

void main() {
  group('VehicleCostCalculator Tests', () {
    test('calculates total cost, monthly fuel, monthly maintenance, and cost per km', () {
      final records = [
        VehicleMaintenanceModel(
          id: '1',
          vehicleId: 'v1',
          expenseType: VehicleExpenseType.fuel,
          amountCents: 200000, // 2.000 TL
          date: DateTime(2026, 11, 2),
          odometerKm: 50000,
          createdAt: DateTime(2026, 11, 2),
        ),
        VehicleMaintenanceModel(
          id: '2',
          vehicleId: 'v1',
          expenseType: VehicleExpenseType.maintenance,
          amountCents: 300000, // 3.000 TL
          date: DateTime(2026, 11, 10),
          odometerKm: 51000,
          createdAt: DateTime(2026, 11, 10),
        ),
        VehicleMaintenanceModel(
          id: '3',
          vehicleId: 'v1',
          expenseType: VehicleExpenseType.insurance,
          amountCents: 500000, // 5.000 TL (Ekim ayında)
          date: DateTime(2026, 10, 15),
          odometerKm: 49000,
          createdAt: DateTime(2026, 10, 15),
        ),
      ];

      final summary = VehicleCostCalculator.calculateSummary(
        records: records,
        year: 2026,
        month: 11,
      );

      // Toplam 2.000 + 3.000 + 5.000 = 10.000 TL (1.000.000 kuruş)
      expect(summary.totalCostCents, 1000000);
      // Kasım ayı yakıt: 2.000 TL
      expect(summary.monthlyFuelCostCents, 200000);
      // Kasım ayı bakım: 3.000 TL
      expect(summary.monthlyMaintenanceCostCents, 300000);
      // Kasım ayı toplam: 5.000 TL
      expect(summary.monthlyTotalCostCents, 500000);
      // Kat edilen km: 51.000 - 49.000 = 2.000 km -> 1.000.000 / 2000 = 500 kuruş (5,00 TL/km)
      expect(summary.trackedKmDelta, 2000);
      expect(summary.costPerKmCents, 500);
    });

    test('returns null costPerKm when fewer than 2 distinct odometer readings exist', () {
      final records = [
        VehicleMaintenanceModel(
          id: '1',
          vehicleId: 'v1',
          expenseType: VehicleExpenseType.fuel,
          amountCents: 150000,
          date: DateTime(2026, 11, 5),
          odometerKm: 50000,
          createdAt: DateTime(2026, 11, 5),
        ),
      ];

      final summary = VehicleCostCalculator.calculateSummary(
        records: records,
        year: 2026,
        month: 11,
      );

      expect(summary.costPerKmCents, isNull);
    });

    test('daysRemaining calculates positive, zero, and negative day differences', () {
      final now = DateTime(2026, 11, 21);
      expect(VehicleCostCalculator.daysRemaining(DateTime(2026, 11, 30), now: now), 9);
      expect(VehicleCostCalculator.daysRemaining(DateTime(2026, 11, 21), now: now), 0);
      expect(VehicleCostCalculator.daysRemaining(DateTime(2026, 11, 15), now: now), -6);
    });
  });
}
