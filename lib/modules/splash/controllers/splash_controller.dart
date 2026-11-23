import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firebase_service.dart';

class SplashController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService.to;
  final AuthService _authService = AuthService.to;

  final RxString statusMessage = 'Yükleniyor...'.obs;

  @override
  void onReady() {
    super.onReady();
    _checkAppEntry();
  }

  Future<void> _checkAppEntry() async {
    // Firebase başlatılamadıysa login ekranına geç
    if (!_firebaseService.isInitialized.value &&
        _firebaseService.initializationError.isNotEmpty) {
      statusMessage.value = 'Firebase bağlantısı bekleniyor...';
      await Future.delayed(const Duration(milliseconds: 800));
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    // Oturum ve Firestore profil kontrolü tamamlanana kadar bekle
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 700)),
      _authService.waitForInitialAuth(),
    ]);

    if (!_authService.isAuthenticated) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    // Oturum var ancak profil henüz yüklenemediyse bir kez daha dene
    if (!_authService.hasBusiness) {
      await _authService.refreshUserProfile();
    }

    if (_authService.hasBusiness) {
      Get.offAllNamed(AppRoutes.mainShell);
      return;
    }

    // Profil ağ/izin hatasından dolayı okunamadıysa yanlışlıkla kayıt ekranına atma, login'e gönder
    if (_authService.profileFetchFailed.value) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    // Oturum var ve kullanıcı gerçekten henüz işletme oluşturmamışsa kayıt ekranına al
    Get.offAllNamed(AppRoutes.registerBusiness);
  }
}
