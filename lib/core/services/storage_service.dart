import 'dart:convert';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'tenant_service.dart';

class StorageService extends GetxService {
  static StorageService get to => Get.find();

  final TenantService _tenantService = TenantService.to;

  /// Seçilen fiş/fatura görselini sıkıştırılmış Data URI (Base64) formatına dönüştürür.
  /// Bu sayede Firebase Spark (Ücretsiz) planında Storage gerekmeden Firestore'da saklanabilir.
  Future<String> uploadReceiptImage(XFile imageFile, {String folder = 'receipts'}) async {
    final businessId = _tenantService.currentBusinessId.value;
    if (businessId.isEmpty) {
      throw StateError('Aktif işletme kimliği bulunamadı!');
    }

    try {
      final bytes = await imageFile.readAsBytes();
      if (bytes.length > 350 * 1024) {
        throw 'Seçilen görsel boyutu çok büyük (${(bytes.length / 1024).round()} KB). Lütfen daha küçük bir görsel seçiniz.';
      }

      final rawExt = imageFile.name.contains('.')
          ? imageFile.name.split('.').last.toLowerCase()
          : 'jpg';
      final mimeSubType = (rawExt == 'png' || rawExt == 'webp' || rawExt == 'jpeg')
          ? rawExt
          : 'jpeg';

      final base64Str = base64Encode(bytes);
      return 'data:image/$mimeSubType;base64,$base64Str';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Fotoğraf işlenemedi: $e';
    }
  }

  /// Data URI formatındaki görseller dokümanla birlikte silindiği için ek işlem gerekmez.
  Future<void> deleteByUrl(String? url) async {
    return;
  }
}
