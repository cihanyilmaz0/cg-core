class VehicleCostSummaryModel {
  final int totalCostCents;
  final int monthlyTotalCostCents;
  final int monthlyFuelCostCents;
  final int monthlyMaintenanceCostCents;
  final int? costPerKmCents;
  final int trackedKmDelta;

  VehicleCostSummaryModel({
    required this.totalCostCents,
    required this.monthlyTotalCostCents,
    required this.monthlyFuelCostCents,
    required this.monthlyMaintenanceCostCents,
    this.costPerKmCents,
    this.trackedKmDelta = 0,
  });
}
