import 'package:flutter_test/flutter_test.dart';
import 'package:saas_isletme/core/constants/app_enums.dart';
import 'package:saas_isletme/modules/employees/models/employee_leave_record_model.dart';
import 'package:saas_isletme/modules/employees/models/employee_model.dart';
import 'package:saas_isletme/modules/employees/models/employee_salary_history_model.dart';
import 'package:saas_isletme/modules/employees/models/employee_transaction_model.dart';
import 'package:saas_isletme/modules/employees/utils/employee_salary_calculator.dart';

void main() {
  final baseEmployee = EmployeeModel(
    id: 'emp_1',
    fullName: 'Ahmet Yılmaz',
    salaryType: SalaryType.monthly,
    baseSalaryCents: 3000000, // 30.000,00 TL
    startDate: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
  );

  group('EmployeeSalaryCalculator Tests', () {
    test('calculates monthly summary with advances, bonuses, payments and deductions', () {
      final transactions = [
        EmployeeTransactionModel(
          id: 'tx_1',
          employeeId: 'emp_1',
          type: EmployeeTransactionType.advance,
          amountCents: 500000, // 5.000 TL
          date: DateTime(2026, 11, 5),
          createdAt: DateTime(2026, 11, 5),
        ),
        EmployeeTransactionModel(
          id: 'tx_2',
          employeeId: 'emp_1',
          type: EmployeeTransactionType.bonus,
          amountCents: 250000, // 2.500 TL
          date: DateTime(2026, 11, 10),
          createdAt: DateTime(2026, 11, 10),
        ),
        EmployeeTransactionModel(
          id: 'tx_3',
          employeeId: 'emp_1',
          type: EmployeeTransactionType.deduction,
          amountCents: 100000, // 1.000 TL
          date: DateTime(2026, 11, 15),
          createdAt: DateTime(2026, 11, 15),
        ),
        EmployeeTransactionModel(
          id: 'tx_4',
          employeeId: 'emp_1',
          type: EmployeeTransactionType.salaryPayment,
          amountCents: 1000000, // 10.000 TL
          date: DateTime(2026, 11, 20),
          createdAt: DateTime(2026, 11, 20),
        ),
      ];

      final summary = EmployeeSalaryCalculator.calculateMonthlySummary(
        employee: baseEmployee,
        salaryHistory: [],
        transactions: transactions,
        leaveRecords: [],
        year: 2026,
        month: 11,
      );

      expect(summary.baseSalaryCents, 3000000);
      expect(summary.earnedSalaryCents, 3000000);
      expect(summary.bonusCents, 250000);
      expect(summary.advanceCents, 500000);
      expect(summary.deductionCents, 100000);
      expect(summary.salaryPaymentCents, 1000000);
      // 30.000 + 2.500 - 5.000 - 10.000 - 1.000 = 16.500 TL (1.650.000 kuruş)
      expect(summary.remainingBalanceCents, 1650000);
    });

    test('deducts unpaid leave days using 30-day rule without affecting paid leave', () {
      final leaves = [
        EmployeeLeaveRecordModel(
          id: 'l_1',
          employeeId: 'emp_1',
          leaveType: LeaveType.unpaidLeave,
          startDate: DateTime(2026, 11, 10),
          endDate: DateTime(2026, 11, 12), // 3 gün ücretsiz izin
          totalDays: 3,
          createdAt: DateTime(2026, 11, 10),
        ),
        EmployeeLeaveRecordModel(
          id: 'l_2',
          employeeId: 'emp_1',
          leaveType: LeaveType.paidLeave,
          startDate: DateTime(2026, 11, 20),
          endDate: DateTime(2026, 11, 21), // 2 gün ücretli izin (kesinti olmaz)
          totalDays: 2,
          createdAt: DateTime(2026, 11, 20),
        ),
      ];

      final summary = EmployeeSalaryCalculator.calculateMonthlySummary(
        employee: baseEmployee,
        salaryHistory: [],
        transactions: [],
        leaveRecords: leaves,
        year: 2026,
        month: 11,
      );

      expect(summary.unpaidLeaveDays, 3);
      expect(summary.paidLeaveDays, 2);
      // Günlük 1.000 TL * 3 gün = 3.000 TL kesinti -> 27.000 TL hakediş
      expect(summary.earnedSalaryCents, 2700000);
      expect(summary.remainingBalanceCents, 2700000);
    });

    test('future salary raise does not alter historical month salary calculation', () {
      // Kasım 2026'da maaş 30.000 TL -> 40.000 TL oldu
      final history = [
        EmployeeSalaryHistoryModel(
          id: 'sh_1',
          employeeId: 'emp_1',
          previousSalaryCents: 3000000,
          newSalaryCents: 4000000,
          changeDate: DateTime(2026, 11, 1),
          createdAt: DateTime(2026, 11, 1),
        ),
      ];

      final updatedEmployee = baseEmployee.copyWith(baseSalaryCents: 4000000);

      // Ekim 2026 (zamdan önceki ay) hesaplaması hâlâ 30.000 TL olmalı!
      final octoberSummary = EmployeeSalaryCalculator.calculateMonthlySummary(
        employee: updatedEmployee,
        salaryHistory: history,
        transactions: [],
        leaveRecords: [],
        year: 2026,
        month: 10,
      );
      expect(octoberSummary.baseSalaryCents, 3000000);
      expect(octoberSummary.earnedSalaryCents, 3000000);

      // Kasım 2026 hesaplaması 40.000 TL olmalı!
      final novemberSummary = EmployeeSalaryCalculator.calculateMonthlySummary(
        employee: updatedEmployee,
        salaryHistory: history,
        transactions: [],
        leaveRecords: [],
        year: 2026,
        month: 11,
      );
      expect(novemberSummary.baseSalaryCents, 4000000);
      expect(novemberSummary.earnedSalaryCents, 4000000);
    });
  });
}
