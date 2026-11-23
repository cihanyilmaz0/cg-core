import 'package:flutter/material.dart';

class MonthlyTrendItem {
  final int year;
  final int month;
  final String label;
  final int personnelCents;
  final int vehicleCents;
  final int generalCents;

  MonthlyTrendItem({
    required this.year,
    required this.month,
    required this.label,
    required this.personnelCents,
    required this.vehicleCents,
    required this.generalCents,
  });

  int get totalCents => personnelCents + vehicleCents + generalCents;
}

class CategoryBreakdownItem {
  final String name;
  final int amountCents;
  final Color color;

  CategoryBreakdownItem({
    required this.name,
    required this.amountCents,
    required this.color,
  });
}

class EntityCostItem {
  final String id;
  final String title;
  final String subtitle;
  final int amountCents;

  EntityCostItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amountCents,
  });
}

class ReportSummaryModel {
  final int year;
  final int month;
  final int monthlyTotalCents;
  final int yearlyTotalCents;
  final int monthlyPersonnelCents;
  final int monthlyVehicleCents;
  final int monthlyGeneralCents;
  final List<MonthlyTrendItem> monthlyTrends;
  final List<CategoryBreakdownItem> categoryBreakdown;
  final List<EntityCostItem> personnelCosts;
  final List<EntityCostItem> vehicleCosts;

  ReportSummaryModel({
    required this.year,
    required this.month,
    required this.monthlyTotalCents,
    required this.yearlyTotalCents,
    required this.monthlyPersonnelCents,
    required this.monthlyVehicleCents,
    required this.monthlyGeneralCents,
    required this.monthlyTrends,
    required this.categoryBreakdown,
    required this.personnelCosts,
    required this.vehicleCosts,
  });
}
