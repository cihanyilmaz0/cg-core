import 'dart:math';
import '../../../core/constants/app_enums.dart';
import '../models/employee_leave_record_model.dart';
import '../models/employee_model.dart';
import '../models/employee_monthly_summary_model.dart';
import '../models/employee_salary_history_model.dart';
import '../models/employee_transaction_model.dart';

class EmployeeSalaryCalculator {
  EmployeeSalaryCalculator._();

  /// İlgili ay için geçerli olan maaşı geçmiş kayıtlar üzerinden bulur.
  /// Gelecek aylarda yapılan maaş değişiklikleri geçmiş ayların hesabını etkilemez.
  static int resolveSalaryForMonth({
    required EmployeeModel employee,
    required List<EmployeeSalaryHistoryModel> salaryHistory,
    required int year,
    required int month,
  }) {
    if (salaryHistory.isEmpty) {
      return employee.baseSalaryCents;
    }

    final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);

    // Tarihe göre eskiden yeniye sırala
    final sorted = List<EmployeeSalaryHistoryModel>.from(salaryHistory)
      ..sort((a, b) => a.changeDate.compareTo(b.changeDate));

    // Seçilen ayın sonuna kadar gerçekleşmiş en son maaş değişikliğini bul
    EmployeeSalaryHistoryModel? lastApplicableChange;
    EmployeeSalaryHistoryModel? firstFutureChange;

    for (final item in sorted) {
      if (!item.changeDate.isAfter(monthEnd)) {
        lastApplicableChange = item;
      } else {
        firstFutureChange ??= item;
      }
    }

    if (lastApplicableChange != null) {
      return lastApplicableChange.newSalaryCents;
    }

    if (firstFutureChange != null) {
      return firstFutureChange.previousSalaryCents;
    }

    return employee.baseSalaryCents;
  }

  /// Seçili ay için personelin detaylı hesap özetini oluşturur.
  /// [monthBasisDays] varsayılan 30 günlük hesaplama kuralıdır.
  static EmployeeMonthlySummaryModel calculateMonthlySummary({
    required EmployeeModel employee,
    required List<EmployeeSalaryHistoryModel> salaryHistory,
    required List<EmployeeTransactionModel> transactions,
    required List<EmployeeLeaveRecordModel> leaveRecords,
    required int year,
    required int month,
    int monthBasisDays = 30,
  }) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);

    // 1. İlgili ayın baz maaşı
    final effectiveBaseSalaryCents = resolveSalaryForMonth(
      employee: employee,
      salaryHistory: salaryHistory,
      year: year,
      month: month,
    );

    // 2. İlgili aydaki izin günlerini hesapla
    int unpaidDays = 0;
    int paidDays = 0;

    for (final leave in leaveRecords) {
      final overlapDays = _calculateOverlapDays(
        leave.startDate,
        leave.endDate,
        monthStart,
        monthEnd,
      );
      if (overlapDays <= 0) continue;

      if (leave.leaveType == LeaveType.unpaidLeave ||
          leave.leaveType == LeaveType.unexcusedAbsence) {
        unpaidDays += overlapDays;
      } else {
        paidDays += overlapDays;
      }
    }

    // 3. Hakediş hesabı
    int earnedSalaryCents;
    if (employee.salaryType == SalaryType.daily) {
      final workedDays = max(0, monthBasisDays - unpaidDays);
      earnedSalaryCents = effectiveBaseSalaryCents * workedDays;
    } else {
      if (unpaidDays <= 0) {
        earnedSalaryCents = effectiveBaseSalaryCents;
      } else if (unpaidDays >= monthBasisDays) {
        earnedSalaryCents = 0;
      } else {
        final dailyRateCents = (effectiveBaseSalaryCents / monthBasisDays).round();
        final leaveDeduction = dailyRateCents * unpaidDays;
        earnedSalaryCents = max(0, effectiveBaseSalaryCents - leaveDeduction);
      }
    }

    // 4. İlgili aydaki finansal hareketleri topla
    int bonusCents = 0;
    int advanceCents = 0;
    int salaryPaymentCents = 0;
    int deductionCents = 0;

    for (final tx in transactions) {
      if (tx.date.year == year && tx.date.month == month) {
        switch (tx.type) {
          case EmployeeTransactionType.bonus:
          case EmployeeTransactionType.otherPayment:
            bonusCents += tx.amountCents;
            break;
          case EmployeeTransactionType.advance:
            advanceCents += tx.amountCents;
            break;
          case EmployeeTransactionType.salaryPayment:
            salaryPaymentCents += tx.amountCents;
            break;
          case EmployeeTransactionType.deduction:
            deductionCents += tx.amountCents;
            break;
        }
      }
    }

    return EmployeeMonthlySummaryModel(
      year: year,
      month: month,
      baseSalaryCents: effectiveBaseSalaryCents,
      earnedSalaryCents: earnedSalaryCents,
      bonusCents: bonusCents,
      advanceCents: advanceCents,
      salaryPaymentCents: salaryPaymentCents,
      deductionCents: deductionCents,
      unpaidLeaveDays: unpaidDays,
      paidLeaveDays: paidDays,
    );
  }

  static int _calculateOverlapDays(
    DateTime startA,
    DateTime endA,
    DateTime startB,
    DateTime endB,
  ) {
    final normStartA = DateTime(startA.year, startA.month, startA.day);
    final normEndA = DateTime(endA.year, endA.month, endA.day);
    final normStartB = DateTime(startB.year, startB.month, startB.day);
    final normEndB = DateTime(endB.year, endB.month, endB.day);

    final overlapStart = normStartA.isAfter(normStartB) ? normStartA : normStartB;
    final overlapEnd = normEndA.isBefore(normEndB) ? normEndA : normEndB;

    if (overlapEnd.isBefore(overlapStart)) return 0;
    return overlapEnd.difference(overlapStart).inDays + 1;
  }
}
