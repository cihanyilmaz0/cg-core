class AppConstants {
  AppConstants._();

  static const String appName = 'CG Core';
  static const String appVersion = '1.0.0';
  static const String logoPath = 'assets/images/app_icon.png';

  // Firestore root collections
  static const String collectionUsers = 'users';
  static const String collectionBusinesses = 'businesses';

  // Subcollections under businesses/{businessId}
  static const String subCollectionBranches = 'branches';
  static const String subCollectionEmployees = 'employees';
  static const String subCollectionSalaryHistory = 'employeeSalaryHistory';
  static const String subCollectionEmployeeTransactions = 'employeeTransactions';
  static const String subCollectionEmployeeLeaveRecords = 'employeeLeaveRecords';
  static const String subCollectionVehicles = 'vehicles';
  static const String subCollectionVehicleMaintenance = 'vehicleMaintenanceRecords';
  static const String subCollectionExpenseCategories = 'expenseCategories';
  static const String subCollectionExpenses = 'expenses';
  static const String subCollectionNotifications = 'notifications';
  static const String subCollectionReports = 'reports';

  // Currency
  static const String defaultCurrencySymbol = '₺';
  static const String defaultCurrencyCode = 'TRY';
}
