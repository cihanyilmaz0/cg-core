import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../../data/models/business_model.dart';
import 'firebase_service.dart';

class TenantService extends GetxService {
  static TenantService get to => Get.find();

  final Rxn<BusinessModel> currentBusiness = Rxn<BusinessModel>();
  final RxString currentBusinessId = ''.obs;
  final RxString currentBranchId = ''.obs;

  bool get hasActiveBusiness => currentBusinessId.value.isNotEmpty;

  void setBusinessId(String businessId) {
    currentBusinessId.value = businessId;
    if (businessId.isNotEmpty) {
      loadBusinessData(businessId);
    } else {
      currentBusiness.value = null;
    }
  }

  void setBranchId(String branchId) {
    currentBranchId.value = branchId;
  }

  Future<void> loadBusinessData(String businessId) async {
    try {
      final doc = await FirebaseService.to.firestore
          .collection(AppConstants.collectionBusinesses)
          .doc(businessId)
          .get();

      if (doc.exists) {
        currentBusiness.value = BusinessModel.fromFirestore(doc);
      }
    } catch (e) {
      // Hata loglama
    }
  }

  /// Aktif işletmenin belirli bir alt koleksiyon referansını döndürür
  CollectionReference<Map<String, dynamic>> subCollection(String subCollectionName) {
    if (currentBusinessId.value.isEmpty) {
      throw StateError('Aktif bir işletme kimliği (BusinessId) bulunamadı!');
    }
    return FirebaseService.to.firestore
        .collection(AppConstants.collectionBusinesses)
        .doc(currentBusinessId.value)
        .collection(subCollectionName);
  }

  void clear() {
    currentBusinessId.value = '';
    currentBranchId.value = '';
    currentBusiness.value = null;
  }
}
