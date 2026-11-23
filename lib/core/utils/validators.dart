class Validators {
  Validators._();

  static String? requiredField(String? value, {String message = 'Bu alan zorunludur'}) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi gereklidir';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi giriniz';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gereklidir';
    }
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon numarası gereklidir';
    }
    final cleanPhone = value.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length < 10) {
      return 'Geçerli bir telefon numarası giriniz (en az 10 hane)';
    }
    return null;
  }

  static String? positiveAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tutar zorunludur';
    }
    String clean = value.replaceAll('.', '').replaceAll(',', '.').replaceAll('₺', '').trim();
    final double? parsed = double.tryParse(clean);
    if (parsed == null || parsed <= 0) {
      return 'Sıfırdan büyük geçerli bir tutar giriniz';
    }
    return null;
  }
}
