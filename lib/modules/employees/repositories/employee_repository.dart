import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/tenant_service.dart';
import '../models/employee_leave_record_model.dart';
import '../models/employee_model.dart';
import '../models/employee_salary_history_model.dart';
import '../models/employee_transaction_model.dart';

abstract class IEmployeeRepository {
  Future<List<EmployeeModel>> getEmployees();
  Future<EmployeeModel?> getEmployeeById(String employeeId);
  Future<EmployeeModel> createEmployee(EmployeeModel employee);
  Future<void> updateEmployee(EmployeeModel employee);
  Future<void> updateEmployeeSalary({
    required EmployeeModel employee,
    required int newSalaryCents,
    required DateTime changeDate,
    String? note,
    String? changedBy,
  });

  Future<List<EmployeeSalaryHistoryModel>> getSalaryHistory(String employeeId);
  Future<List<EmployeeTransactionModel>> getTransactions(String employeeId);
  Future<EmployeeTransactionModel> addTransaction(EmployeeTransactionModel transaction);
  Future<void> deleteTransaction(String transactionId);

  Future<List<EmployeeLeaveRecordModel>> getLeaveRecords(String employeeId);
  Future<EmployeeLeaveRecordModel> addLeaveRecord(EmployeeLeaveRecordModel leaveRecord);
  Future<void> deleteLeaveRecord(String leaveId);
}

class EmployeeRepository implements IEmployeeRepository {
  final TenantService _tenantService = TenantService.to;
  final FirebaseService _firebaseService = FirebaseService.to;

  CollectionReference<Map<String, dynamic>> get _employeesRef =>
      _tenantService.subCollection(AppConstants.subCollectionEmployees);

  CollectionReference<Map<String, dynamic>> get _salaryHistoryRef =>
      _tenantService.subCollection(AppConstants.subCollectionSalaryHistory);

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _tenantService.subCollection(AppConstants.subCollectionEmployeeTransactions);

  CollectionReference<Map<String, dynamic>> get _leavesRef =>
      _tenantService.subCollection(AppConstants.subCollectionEmployeeLeaveRecords);

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    final snapshot = await _employeesRef.orderBy('fullName').get();
    return snapshot.docs.map((doc) => EmployeeModel.fromFirestore(doc)).toList();
  }

  @override
  Future<EmployeeModel?> getEmployeeById(String employeeId) async {
    final doc = await _employeesRef.doc(employeeId).get();
    if (!doc.exists) return null;
    return EmployeeModel.fromFirestore(doc);
  }

  @override
  Future<EmployeeModel> createEmployee(EmployeeModel employee) async {
    final docRef = _employeesRef.doc();
    final newEmployee = employee.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
    );
    await docRef.set(newEmployee.toMap());
    return newEmployee;
  }

  @override
  Future<void> updateEmployee(EmployeeModel employee) async {
    final map = employee.toMap();
    if (employee.endDate == null) {
      map['endDate'] = FieldValue.delete();
    }
    await _employeesRef.doc(employee.id).update(map);
  }

  @override
  Future<void> updateEmployeeSalary({
    required EmployeeModel employee,
    required int newSalaryCents,
    required DateTime changeDate,
    String? note,
    String? changedBy,
  }) async {
    final batch = _firebaseService.firestore.batch();

    // 1. Personel kartındaki güncel maaşı güncelle
    final empDocRef = _employeesRef.doc(employee.id);
    batch.update(empDocRef, {'baseSalaryCents': newSalaryCents});

    // 2. Maaş geçmişi koleksiyonuna yeni kayıt ekle
    final historyDocRef = _salaryHistoryRef.doc();
    final historyModel = EmployeeSalaryHistoryModel(
      id: historyDocRef.id,
      employeeId: employee.id,
      previousSalaryCents: employee.baseSalaryCents,
      newSalaryCents: newSalaryCents,
      changeDate: changeDate,
      note: note,
      changedBy: changedBy,
      createdAt: DateTime.now(),
    );
    batch.set(historyDocRef, historyModel.toMap());

    await batch.commit();
  }

  @override
  Future<List<EmployeeSalaryHistoryModel>> getSalaryHistory(String employeeId) async {
    final snapshot = await _salaryHistoryRef
        .where('employeeId', isEqualTo: employeeId)
        .get();
    final list = snapshot.docs
        .map((doc) => EmployeeSalaryHistoryModel.fromFirestore(doc))
        .toList();
    list.sort((a, b) => b.changeDate.compareTo(a.changeDate));
    return list;
  }

  @override
  Future<List<EmployeeTransactionModel>> getTransactions(String employeeId) async {
    final snapshot = await _transactionsRef
        .where('employeeId', isEqualTo: employeeId)
        .get();
    final list = snapshot.docs
        .map((doc) => EmployeeTransactionModel.fromFirestore(doc))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<EmployeeTransactionModel> addTransaction(EmployeeTransactionModel transaction) async {
    final docRef = _transactionsRef.doc();
    final newTx = EmployeeTransactionModel(
      id: docRef.id,
      employeeId: transaction.employeeId,
      type: transaction.type,
      amountCents: transaction.amountCents,
      date: transaction.date,
      description: transaction.description,
      createdBy: transaction.createdBy,
      createdAt: DateTime.now(),
    );
    await docRef.set(newTx.toMap());
    return newTx;
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await _transactionsRef.doc(transactionId).delete();
  }

  @override
  Future<List<EmployeeLeaveRecordModel>> getLeaveRecords(String employeeId) async {
    final snapshot = await _leavesRef
        .where('employeeId', isEqualTo: employeeId)
        .get();
    final list = snapshot.docs
        .map((doc) => EmployeeLeaveRecordModel.fromFirestore(doc))
        .toList();
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  @override
  Future<EmployeeLeaveRecordModel> addLeaveRecord(EmployeeLeaveRecordModel leaveRecord) async {
    final docRef = _leavesRef.doc();
    final newLeave = EmployeeLeaveRecordModel(
      id: docRef.id,
      employeeId: leaveRecord.employeeId,
      leaveType: leaveRecord.leaveType,
      startDate: leaveRecord.startDate,
      endDate: leaveRecord.endDate,
      totalDays: leaveRecord.totalDays,
      note: leaveRecord.note,
      createdAt: DateTime.now(),
    );
    await docRef.set(newLeave.toMap());
    return newLeave;
  }

  @override
  Future<void> deleteLeaveRecord(String leaveId) async {
    await _leavesRef.doc(leaveId).delete();
  }
}
