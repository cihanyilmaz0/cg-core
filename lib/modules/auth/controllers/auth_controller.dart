import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/business_repository.dart';

class AuthController extends GetxController {
  final IAuthRepository _authRepository = Get.find<IAuthRepository>();
  final IBusinessRepository _businessRepository = Get.find<IBusinessRepository>();
  final AuthService _authService = AuthService.to;

  // Login form controllers
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();

  // Register Business & Owner controllers
  final businessNameController = TextEditingController();
  final sectorController = TextEditingController(text: 'Genel Ticaret');
  final taxNumberController = TextEditingController();
  final ownerFullNameController = TextEditingController();
  final registerEmailController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final registerFormKey = GlobalKey<FormState>();

  // State observables
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxString errorMessage = ''.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final credential = await _authRepository.signInWithEmailAndPassword(
        loginEmailController.text.trim(),
        loginPasswordController.text,
      );

      final userProfile = await _authRepository.getUserProfile(credential.user!.uid);

      if (userProfile == null || userProfile.businessId.isEmpty) {
        Get.offAllNamed(AppRoutes.registerBusiness);
      } else {
        await _authService.refreshUserProfile();
        Get.offAllNamed(AppRoutes.mainShell);
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Giriş Başarısız',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final credential = await _authRepository.signInWithGoogle();
      final user = credential.user;
      if (user == null) return;

      final userProfile = await _authRepository.getUserProfile(user.uid);

      if (userProfile == null || userProfile.businessId.isEmpty) {
        // Yeni veya işletmesiz kullanıcı -> Google bilgileriyle onboarding'e yönlendir
        ownerFullNameController.text = user.displayName ?? '';
        registerEmailController.text = user.email ?? '';
        Get.offAllNamed(AppRoutes.registerBusiness);
      } else {
        await _authService.refreshUserProfile();
        Get.offAllNamed(AppRoutes.mainShell);
      }
    } catch (e) {
      if (!e.toString().contains('iptal edildi')) {
        errorMessage.value = e.toString();
        Get.snackbar(
          'Google Girişi Başarısız',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> registerBusiness() async {
    if (!registerFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // 1. Firebase Auth üzerinde kullanıcı oluştur veya mevcut oturumu kullan
      String uid;
      String email = registerEmailController.text.trim();

      if (_authService.isAuthenticated) {
        uid = _authService.firebaseUser.value!.uid;
        email = _authService.firebaseUser.value!.email ?? email;
      } else {
        final credential = await _authRepository.createUserWithEmailAndPassword(
          email,
          registerPasswordController.text,
        );
        uid = credential.user!.uid;
      }

      // 2. İşletmeyi oluştur (ve varsayılan şube + gider kategorilerini seed et)
      final business = await _businessRepository.createBusiness(
        name: businessNameController.text.trim(),
        sector: sectorController.text.trim(),
        taxNumber: taxNumberController.text.trim().isEmpty ? null : taxNumberController.text.trim(),
        ownerUid: uid,
      );

      // 3. Kullanıcı profilini oluştur / güncelle
      final userModel = UserModel(
        uid: uid,
        email: email,
        fullName: ownerFullNameController.text.trim(),
        businessId: business.id,
        role: UserRole.owner,
        createdAt: DateTime.now(),
      );

      await _authRepository.createUserProfile(userModel);

      // 4. AuthService ve TenantService'i yenile
      await _authService.refreshUserProfile();

      Get.offAllNamed(AppRoutes.mainShell);

      Get.snackbar(
        'Tebrikler!',
        'İşletmeniz başarıyla oluşturuldu.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.teal.shade800,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Kayıt Hatası',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendPasswordReset() async {
    final email = loginEmailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar(
        'E-posta Gerekli',
        'Lütfen şifre sıfırlama bağlantısı gönderilecek e-posta adresini giriniz.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      await _authRepository.sendPasswordResetEmail(email);
      Get.snackbar(
        'E-posta Gönderildi',
        'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    businessNameController.dispose();
    sectorController.dispose();
    taxNumberController.dispose();
    ownerFullNameController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    super.onClose();
  }
}
