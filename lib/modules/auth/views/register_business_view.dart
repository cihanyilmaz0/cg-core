import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

class RegisterBusinessView extends GetView<AuthController> {
  const RegisterBusinessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('İşletme Kaydı'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (Navigator.of(context).canPop()) {
              Get.back();
            } else {
              await AuthService.to.signOut();
              Get.offAllNamed(AppRoutes.login);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: controller.registerFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Yeni İşletme Oluşturun',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bilgileri doldurarak SaaS işletme hesabınızı anında kullanmaya başlayın.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),

                // İşletme Bilgileri
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.store_mall_directory_rounded, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'İşletme Bilgileri',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        AppTextField(
                          controller: controller.businessNameController,
                          label: 'İşletme / Firma Adı',
                          hint: 'Örn: Star Cafe & Restoran',
                          prefixIcon: const Icon(Icons.business_outlined),
                          validator: (v) => Validators.requiredField(v, message: 'İşletme adı zorunludur'),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: controller.sectorController,
                          label: 'Faaliyet Sektörü',
                          hint: 'Örn: Kafe, Dağıtım, Atölye, Market',
                          prefixIcon: const Icon(Icons.category_outlined),
                          validator: (v) => Validators.requiredField(v, message: 'Sektör bilgisi zorunludur'),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: controller.taxNumberController,
                          label: 'Vergi No / T.C. (İsteğe Bağlı)',
                          hint: 'Vergi numaranız',
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Yönetici / Sahip Bilgileri
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_outline_rounded, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'Yönetici Hesabı',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        AppTextField(
                          controller: controller.ownerFullNameController,
                          label: 'Adınız Soyadınız',
                          hint: 'Örn: Ahmet Yılmaz',
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: (v) => Validators.requiredField(v, message: 'Ad soyad zorunludur'),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: controller.registerEmailController,
                          label: 'Yönetici E-posta',
                          hint: 'ahmet@isletme.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        Obx(
                          () => AppTextField(
                            controller: controller.registerPasswordController,
                            label: 'Şifre',
                            hint: 'En az 6 karakter',
                            obscureText: !controller.isPasswordVisible.value,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isPasswordVisible.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: controller.togglePasswordVisibility,
                            ),
                            validator: Validators.password,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Obx(
                  () => AppButton(
                    text: 'İşletmeyi Kaydet ve Başla',
                    isLoading: controller.isLoading.value,
                    onPressed: controller.registerBusiness,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
