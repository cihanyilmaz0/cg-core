import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/tenant_service.dart';
import '../../../core/utils/app_snackbar.dart';

class SettingsController extends GetxController {
  final AuthService authService = AuthService.to;
  final TenantService tenantService = TenantService.to;
  final FirebaseService _firebaseService = FirebaseService.to;

  final RxBool isDeletingAccount = false.obs;

  Future<void> signOut() async {
    await authService.signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> deleteAccount() async {
    final user = _firebaseService.auth.currentUser;
    if (user == null) return;

    try {
      isDeletingAccount.value = true;

      // 1. Kullanıcının profil dokümanını sil
      await _firebaseService.firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .delete();

      // 2. Firebase Auth hesabını kalıcı olarak sil
      await user.delete();

      await authService.signOut();
      Get.offAllNamed(AppRoutes.login);
      AppSnackbar.showInfo(
        'Hesap Silindi',
        'Hesabınız ve oturum bilgileriniz kalıcı olarak silindi.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        AppSnackbar.showError(
          'Yeniden Giriş Gerekli',
          'Güvenlik nedeniyle hesabınızı silmeden önce çıkış yapıp yeniden giriş yapmanız gerekmektedir.',
        );
      } else {
        AppSnackbar.showError('Hata', e.message ?? 'Hesap silinemedi.');
      }
    } catch (e) {
      AppSnackbar.showError('Hata', 'Hesap silinirken hata oluştu: $e');
    } finally {
      isDeletingAccount.value = false;
    }
  }
}
