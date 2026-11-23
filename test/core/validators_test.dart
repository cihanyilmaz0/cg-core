import 'package:flutter_test/flutter_test.dart';
import 'package:saas_isletme/core/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    test('requiredField validates non-empty inputs', () {
      expect(Validators.requiredField(''), 'Bu alan zorunludur');
      expect(Validators.requiredField(null), 'Bu alan zorunludur');
      expect(Validators.requiredField('   '), 'Bu alan zorunludur');
      expect(Validators.requiredField('Geçerli Değer'), isNull);
    });

    test('email validator checks proper formats', () {
      expect(Validators.email(''), 'E-posta adresi gereklidir');
      expect(Validators.email('gecersiz-eposta'), 'Geçerli bir e-posta adresi giriniz');
      expect(Validators.email('test@'), 'Geçerli bir e-posta adresi giriniz');
      expect(Validators.email('ahmet@isletme.com'), isNull);
    });

    test('password validator enforces minimum length', () {
      expect(Validators.password(''), 'Şifre gereklidir');
      expect(Validators.password('12345'), 'Şifre en az 6 karakter olmalıdır');
      expect(Validators.password('123456'), isNull);
    });

    test('positiveAmount validator checks for numbers > 0', () {
      expect(Validators.positiveAmount(''), 'Tutar zorunludur');
      expect(Validators.positiveAmount('0'), 'Sıfırdan büyük geçerli bir tutar giriniz');
      expect(Validators.positiveAmount('-50'), 'Sıfırdan büyük geçerli bir tutar giriniz');
      expect(Validators.positiveAmount('abc'), 'Sıfırdan büyük geçerli bir tutar giriniz');
      expect(Validators.positiveAmount('150,50'), isNull);
      expect(Validators.positiveAmount('1000'), isNull);
    });
  });
}
