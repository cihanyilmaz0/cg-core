import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/firebase_service.dart';
import '../models/business_model.dart';

abstract class IBusinessRepository {
  Future<BusinessModel> createBusiness({
    required String name,
    required String sector,
    String? taxNumber,
    required String ownerUid,
  });
  Future<BusinessModel?> getBusinessById(String businessId);
  Future<void> updateBusiness(BusinessModel business);
  Future<void> seedDefaultExpenseCategories(String businessId);
}

class BusinessRepository implements IBusinessRepository {
  final FirebaseService _firebaseService = FirebaseService.to;

  @override
  Future<BusinessModel> createBusiness({
    required String name,
    required String sector,
    String? taxNumber,
    required String ownerUid,
  }) async {
    final docRef = _firebaseService.firestore
        .collection(AppConstants.collectionBusinesses)
        .doc();

    final business = BusinessModel(
      id: docRef.id,
      name: name.trim(),
      sector: sector.trim(),
      taxNumber: taxNumber?.trim(),
      ownerUid: ownerUid,
      currency: AppConstants.defaultCurrencyCode,
      createdAt: DateTime.now(),
    );

    try {
      // Batch ile hem işletme kaydı hem de ana şube oluştur
      final batch = _firebaseService.firestore.batch();
      batch.set(docRef, business.toMap());

      // Varsayılan Merkez Şube
      final branchRef = docRef.collection(AppConstants.subCollectionBranches).doc();
      batch.set(branchRef, {
        'name': 'Merkez',
        'isMain': true,
        'createdAt': Timestamp.now(),
      });

      await batch.commit();

      // Varsayılan kategorileri ekle
      await seedDefaultExpenseCategories(docRef.id);

      return business;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw 'Firestore veritabanı erişim izni reddedildi. Lütfen Firebase Console üzerinden Firestore veritabanını oluşturduğunuzdan emin olun.';
      } else if (e.code == 'not-found') {
        throw 'Firestore veritabanı bulunamadı. Lütfen Firebase Console üzerinden veritabanı oluşturun.';
      }
      throw 'İşletme kaydedilirken veritabanı hatası oluştu: ${e.message ?? e.code}';
    } catch (e) {
      throw 'İşletme kaydı sırasında beklenmeyen bir hata oluştu: $e';
    }
  }

  @override
  Future<BusinessModel?> getBusinessById(String businessId) async {
    final doc = await _firebaseService.firestore
        .collection(AppConstants.collectionBusinesses)
        .doc(businessId)
        .get();

    if (!doc.exists) return null;
    return BusinessModel.fromFirestore(doc);
  }

  @override
  Future<void> updateBusiness(BusinessModel business) async {
    await _firebaseService.firestore
        .collection(AppConstants.collectionBusinesses)
        .doc(business.id)
        .update(business.toMap());
  }

  @override
  Future<void> seedDefaultExpenseCategories(String businessId) async {
    final categoriesRef = _firebaseService.firestore
        .collection(AppConstants.collectionBusinesses)
        .doc(businessId)
        .collection(AppConstants.subCollectionExpenseCategories);

    final defaultCategories = [
      {'name': 'Mutfak / Gıda', 'iconCode': 'restaurant', 'colorHex': '#F97316', 'isDefault': true},
      {'name': 'Temizlik & Hijyen', 'iconCode': 'cleaning_services', 'colorHex': '#06B6D4', 'isDefault': true},
      {'name': 'Personel Yemek', 'iconCode': 'lunch_dining', 'colorHex': '#84CC16', 'isDefault': true},
      {'name': 'Kira', 'iconCode': 'home_work', 'colorHex': '#6366F1', 'isDefault': true},
      {'name': 'Elektrik', 'iconCode': 'bolt', 'colorHex': '#EAB308', 'isDefault': true},
      {'name': 'Su', 'iconCode': 'water_drop', 'colorHex': '#3B82F6', 'isDefault': true},
      {'name': 'Doğalgaz', 'iconCode': 'local_fire_department', 'colorHex': '#EF4444', 'isDefault': true},
      {'name': 'İnternet & İletişim', 'iconCode': 'wifi', 'colorHex': '#8B5CF6', 'isDefault': true},
      {'name': 'Kırtasiye & Büro', 'iconCode': 'description', 'colorHex': '#64748B', 'isDefault': true},
      {'name': 'Ambalaj & Paketleme', 'iconCode': 'inventory_2', 'colorHex': '#D97706', 'isDefault': true},
      {'name': 'Nakliye & Lojistik', 'iconCode': 'local_shipping', 'colorHex': '#0D9488', 'isDefault': true},
      {'name': 'Ofis & Sarf Malzeme', 'iconCode': 'business_center', 'colorHex': '#475569', 'isDefault': true},
      {'name': 'Diğer Genel Giderler', 'iconCode': 'more_horiz', 'colorHex': '#94A3B8', 'isDefault': true},
    ];

    final batch = _firebaseService.firestore.batch();
    for (final cat in defaultCategories) {
      final catDoc = categoriesRef.doc();
      batch.set(catDoc, {
        ...cat,
        'createdAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }
}
