import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/tenant_service.dart';
import '../../../data/repositories/business_repository.dart';
import '../models/expense_category_model.dart';
import '../models/expense_model.dart';

abstract class IExpenseRepository {
  Future<List<ExpenseCategoryModel>> getCategories();
  Future<ExpenseCategoryModel> createCategory(ExpenseCategoryModel category);
  Future<void> deleteCategory(String categoryId);

  Future<List<ExpenseModel>> getExpenses({int? year, int? month});
  Future<ExpenseModel> createExpense(ExpenseModel expense);
  Future<void> deleteExpense(String expenseId);
}

class ExpenseRepository implements IExpenseRepository {
  final TenantService _tenantService = TenantService.to;

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _tenantService.subCollection(AppConstants.subCollectionExpenseCategories);

  CollectionReference<Map<String, dynamic>> get _expensesRef =>
      _tenantService.subCollection(AppConstants.subCollectionExpenses);

  @override
  Future<List<ExpenseCategoryModel>> getCategories() async {
    var snapshot = await _categoriesRef.orderBy('name').get();

    // Eğer işletmenin kategorisi yoksa varsayılanları tohumla
    if (snapshot.docs.isEmpty && _tenantService.hasActiveBusiness) {
      await BusinessRepository().seedDefaultExpenseCategories(
        _tenantService.currentBusinessId.value,
      );
      snapshot = await _categoriesRef.orderBy('name').get();
    }

    return snapshot.docs.map((doc) => ExpenseCategoryModel.fromFirestore(doc)).toList();
  }

  @override
  Future<ExpenseCategoryModel> createCategory(ExpenseCategoryModel category) async {
    final docRef = _categoriesRef.doc();
    final newCat = ExpenseCategoryModel(
      id: docRef.id,
      name: category.name.trim(),
      iconCode: category.iconCode,
      colorHex: category.colorHex,
      isDefault: false,
      createdAt: DateTime.now(),
    );
    await docRef.set(newCat.toMap());
    return newCat;
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _categoriesRef.doc(categoryId).delete();
  }

  @override
  Future<List<ExpenseModel>> getExpenses({int? year, int? month}) async {
    Query<Map<String, dynamic>> query = _expensesRef;

    if (year != null && month != null) {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0, 23, 59, 59);
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    final snapshot = await query.get();
    final list = snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final docRef = _expensesRef.doc();
    final newExpense = ExpenseModel(
      id: docRef.id,
      categoryId: expense.categoryId,
      categoryName: expense.categoryName,
      amountCents: expense.amountCents,
      title: expense.title,
      description: expense.description,
      paymentMethod: expense.paymentMethod,
      branchId: expense.branchId,
      relatedVehicleId: expense.relatedVehicleId,
      relatedEmployeeId: expense.relatedEmployeeId,
      date: expense.date,
      receiptUrl: expense.receiptUrl,
      createdBy: expense.createdBy,
      createdAt: DateTime.now(),
    );
    await docRef.set(newExpense.toMap());
    return newExpense;
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await _expensesRef.doc(expenseId).delete();
  }
}
