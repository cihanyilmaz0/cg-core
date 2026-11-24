import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/firebase_service.dart';
import '../models/user_model.dart';

abstract class IAuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<UserCredential> signInWithEmailAndPassword(String email, String password);
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password);
  Future<UserCredential> signInWithGoogle();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<UserModel?> getUserProfile(String uid);
  Future<void> createUserProfile(UserModel user);
  Future<void> updateUserProfile(UserModel user);
}

class AuthRepository implements IAuthRepository {
  final FirebaseService _firebaseService = FirebaseService.to;
  bool _isGoogleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await GoogleSignIn.instance.initialize();
      _isGoogleSignInInitialized = true;
    }
  }

  @override
  Stream<User?> get authStateChanges => _firebaseService.auth.authStateChanges();

  @override
  User? get currentUser => _firebaseService.auth.currentUser;

  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _firebaseService.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _firebaseService.auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw 'Google ile giriş kullanıcı tarafından iptal edildi.';
      }
      throw e.description ?? e.toString();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseService.auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _firebaseService.auth.signOut();
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firebaseService.firestore
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  @override
  Future<void> createUserProfile(UserModel user) async {
    await _firebaseService.firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateUserProfile(UserModel user) async {
    await _firebaseService.firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .update(user.toMap());
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Girdiğiniz şifre veya e-posta hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta formatı.';
      case 'weak-password':
        return 'Şifreniz çok zayıf. En az 6 karakter giriniz.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı askıya alınmıştır.';
      case 'operation-not-allowed':
        return 'Firebase Authentication servisinde bu giriş yöntemi henüz aktif edilmemiş. Lütfen Firebase Console üzerinden etkinleştiriniz.';
      case 'network-request-failed':
        return 'İnternet bağlantısı kurulamadı. Lütfen bağlantınızı kontrol ediniz.';
      case 'popup-closed-by-user':
        return 'Google ile giriş penceresi kapatıldı.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme yaptınız. Lütfen bir süre sonra tekrar deneyiniz.';
      default:
        return e.message ?? 'Kimlik doğrulama işlemi sırasında bir hata oluştu.';
    }
  }
}
