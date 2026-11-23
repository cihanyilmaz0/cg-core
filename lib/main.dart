import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_constants.dart';
import 'core/routes/app_pages.dart';
import 'core/services/auth_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/tenant_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/business_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  // 1. Core Services & DI Setup
  await Get.putAsync<FirebaseService>(() => FirebaseService().init());
  Get.put<TenantService>(TenantService(), permanent: true);
  Get.put<StorageService>(StorageService(), permanent: true);

  // 2. Global Repositories
  Get.lazyPut<IAuthRepository>(() => AuthRepository(), fenix: true);
  Get.lazyPut<IBusinessRepository>(() => BusinessRepository(), fenix: true);

  // 3. AuthService (Oturum ve kullanıcı durum yöneticisi)
  Get.put<AuthService>(AuthService(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      locale: const Locale('tr', 'TR'),
      fallbackLocale: const Locale('tr', 'TR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      defaultTransition: Transition.cupertino,
    );
  }
}
