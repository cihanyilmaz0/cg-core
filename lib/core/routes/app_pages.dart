import 'package:get/get.dart';
import '../../modules/auth/bindings/auth_binding.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/auth/views/register_business_view.dart';
import '../../modules/dashboard/bindings/dashboard_binding.dart';
import '../../modules/dashboard/views/dashboard_view.dart';
import '../../modules/employees/bindings/employees_binding.dart';
import '../../modules/employees/views/employee_detail_view.dart';
import '../../modules/employees/views/employee_form_view.dart';
import '../../modules/employees/views/employees_list_view.dart';
import '../../modules/expenses/bindings/expenses_binding.dart';
import '../../modules/expenses/views/expense_categories_view.dart';
import '../../modules/expenses/views/expense_form_view.dart';
import '../../modules/expenses/views/expenses_list_view.dart';
import '../../modules/reports/bindings/reports_binding.dart';
import '../../modules/reports/views/reports_view.dart';
import '../../modules/settings/bindings/settings_binding.dart';
import '../../modules/settings/views/settings_view.dart';
import '../../modules/shell/bindings/main_shell_binding.dart';
import '../../modules/shell/views/main_shell_view.dart';
import '../../modules/splash/bindings/splash_binding.dart';
import '../../modules/splash/views/splash_view.dart';
import '../../modules/vehicles/bindings/vehicles_binding.dart';
import '../../modules/vehicles/views/vehicle_detail_view.dart';
import '../../modules/vehicles/views/vehicle_form_view.dart';
import '../../modules/vehicles/views/vehicles_list_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.registerBusiness,
      page: () => const RegisterBusinessView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.mainShell,
      page: () => const MainShellView(),
      binding: MainShellBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.employees,
      page: () => const EmployeesListView(),
      binding: EmployeesBinding(),
    ),
    GetPage(
      name: AppRoutes.employeeForm,
      page: () => const EmployeeFormView(),
      binding: EmployeesBinding(),
    ),
    GetPage(
      name: AppRoutes.employeeDetail,
      page: () => const EmployeeDetailView(),
      binding: EmployeeDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.vehicles,
      page: () => const VehiclesListView(),
      binding: VehiclesBinding(),
    ),
    GetPage(
      name: AppRoutes.vehicleForm,
      page: () => const VehicleFormView(),
      binding: VehiclesBinding(),
    ),
    GetPage(
      name: AppRoutes.vehicleDetail,
      page: () => const VehicleDetailView(),
      binding: VehicleDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.expenses,
      page: () => const ExpensesListView(),
      binding: ExpensesBinding(),
    ),
    GetPage(
      name: AppRoutes.expenseForm,
      page: () => const ExpenseFormView(),
      binding: ExpensesBinding(),
    ),
    GetPage(
      name: AppRoutes.expenseCategories,
      page: () => const ExpenseCategoriesView(),
      binding: ExpensesBinding(),
    ),
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsView(),
      binding: ReportsBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
  ];
}
