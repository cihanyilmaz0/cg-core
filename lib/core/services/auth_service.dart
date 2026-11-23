import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'tenant_service.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final IAuthRepository _authRepository = Get.find<IAuthRepository>();
  final TenantService _tenantService = TenantService.to;

  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> currentUserProfile = Rx<UserModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool profileFetchFailed = false.obs;

  StreamSubscription<User?>? _authStateSubscription;
  final Completer<void> _initialAuthCompleter = Completer<void>();

  bool get isAuthenticated => firebaseUser.value != null;
  bool get hasBusiness => currentUserProfile.value?.businessId.isNotEmpty ?? false;

  @override
  void onInit() {
    super.onInit();
    _initAuthListener();
  }

  void _initAuthListener() {
    _authStateSubscription = _authRepository.authStateChanges.listen((User? user) async {
      firebaseUser.value = user;
      if (user != null) {
        await refreshUserProfile();
      } else {
        currentUserProfile.value = null;
        profileFetchFailed.value = false;
        _tenantService.clear();
      }
      isLoading.value = false;
      if (!_initialAuthCompleter.isCompleted) {
        _initialAuthCompleter.complete();
      }
    });
  }

  /// İlk oturum ve kullanıcı profilinin Firestore'dan yüklenmesini bekler
  Future<void> waitForInitialAuth() async {
    if (_initialAuthCompleter.isCompleted) return;
    await _initialAuthCompleter.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }

  Future<void> refreshUserProfile() async {
    final user = firebaseUser.value ?? _authRepository.currentUser;
    if (user == null) return;
    firebaseUser.value = user;

    try {
      profileFetchFailed.value = false;
      final profile = await _authRepository.getUserProfile(user.uid);
      currentUserProfile.value = profile;

      if (profile != null && profile.businessId.isNotEmpty) {
        _tenantService.setBusinessId(profile.businessId);
        await _tenantService.loadBusinessData(profile.businessId);
      } else {
        _tenantService.clear();
      }
    } catch (e) {
      profileFetchFailed.value = true;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    firebaseUser.value = null;
    currentUserProfile.value = null;
    _tenantService.clear();
  }

  @override
  void onClose() {
    _authStateSubscription?.cancel();
    super.onClose();
  }
}
