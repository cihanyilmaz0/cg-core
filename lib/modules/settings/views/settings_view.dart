import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/settings_controller.dart';
import 'legal_document_view.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Ayarlar ve Hesap'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // İşletme Kartı
            Obx(() {
              final business = controller.tenantService.currentBusiness.value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.store_rounded, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'İşletme Bilgileri',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 22),
                      _infoRow('İşletme Adı', business?.name ?? '-'),
                      _infoRow('Sektör', business?.sector ?? '-'),
                      _infoRow('Para Birimi', business?.currency ?? 'TRY'),
                      if (business?.taxNumber != null && business!.taxNumber!.isNotEmpty)
                        _infoRow('Vergi No', business.taxNumber!),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),

            // Kullanıcı Kartı
            Obx(() {
              final user = controller.authService.currentUserProfile.value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person_outline_rounded, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Yönetici Hesabı',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 22),
                      _infoRow('Ad Soyad', user?.fullName ?? '-'),
                      _infoRow('E-posta', user?.email ?? '-'),
                      _infoRow('Yetki', user?.role.displayName ?? '-'),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),

            // Gizlilik & Yasal
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                    title: const Text('Gizlilik Politikası ve KVKK'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Get.to(
                      () => const LegalDocumentView(type: LegalDocumentType.privacyPolicy),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                    title: const Text('Kullanım Koşulları (Sözleşme)'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Get.to(
                      () => const LegalDocumentView(type: LegalDocumentType.termsOfUse),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondaryLight),
                    title: const Text('Uygulama Sürümü'),
                    trailing: const Text(
                      'v${AppConstants.appVersion}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Çıkış Yap & Hesabı Sil
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.primary),
                    title: const Text('Oturumu Kapat'),
                    onTap: () => _confirmSignOut(context),
                  ),
                  const Divider(height: 1),
                  Obx(
                    () => ListTile(
                      leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                      title: const Text(
                        'Hesabımı Kalıcı Olarak Sil',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Kullanıcı hesabınızı ve profil erişiminizi kaldırır',
                        style: TextStyle(fontSize: 12),
                      ),
                      enabled: !controller.isDeletingAccount.value,
                      onTap: () => _confirmDeleteAccount(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondaryLight)),
          Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.signOut();
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hesabı Kalıcı Olarak Sil'),
        content: const Text(
          'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz ve uygulamaya erişiminiz kalıcı olarak kapatılır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.deleteAccount();
            },
            child: const Text('Evet, Hesabımı Sil'),
          ),
        ],
      ),
    );
  }
}
