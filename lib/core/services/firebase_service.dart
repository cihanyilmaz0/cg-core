import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import '../../firebase_options.dart';

class FirebaseService extends GetxService {
  static FirebaseService get to => Get.find();

  final RxBool isInitialized = false.obs;
  final RxString initializationError = ''.obs;

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  Future<FirebaseService> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isInitialized.value = true;
      log('Firebase başarıyla başlatıldı (Proje: saas-isletme).');
    } catch (e) {
      initializationError.value = e.toString();
      log('Firebase başlatma hatası: $e');
    }
    return this;
  }
}
