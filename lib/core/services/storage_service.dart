import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'tenant_service.dart';

class StorageService extends GetxService {
  static StorageService get to => Get.find();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TenantService _tenantService = TenantService.to;
  final Uuid _uuid = const Uuid();

  /// Seçilen fiş/fatura görselini işletmenin izole klasörüne yükler ve indirme URL'sini döndürür.
  Future<String> uploadReceiptImage(XFile imageFile, {String folder = 'receipts'}) async {
    final businessId = _tenantService.currentBusinessId.value;
    if (businessId.isEmpty) {
      throw StateError('Aktif işletme kimliği bulunamadı!');
    }

    final bytes = await imageFile.readAsBytes();
    final ext = imageFile.name.contains('.') ? imageFile.name.split('.').last : 'jpg';
    final fileName = '${_uuid.v4()}.$ext';
    final path = 'businesses/$businessId/$folder/$fileName';

    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: 'image/$ext');

    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  }
}
