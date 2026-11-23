import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_isletme/core/utils/currency_input_formatter.dart';

void main() {
  final formatter = TurkishCurrencyInputFormatter();

  TextEditingValue format(String oldText, String newText) {
    return formatter.formatEditUpdate(
      TextEditingValue(
        text: oldText,
        selection: TextSelection.collapsed(offset: oldText.length),
      ),
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      ),
    );
  }

  group('TurkishCurrencyInputFormatter Tests', () {
    test('formats integer digits with thousand dots', () {
      expect(format('150', '1500').text, '1.500');
      expect(format('2.500', '2.5000').text, '25.000');
      expect(format('100.000', '100.0000').text, '1.000.000');
    });

    test('converts newly typed dot to decimal comma when no comma exists', () {
      expect(format('1.500', '1.500.').text, '1.500,');
    });

    test('keeps at most 2 decimal places after comma', () {
      expect(format('1.500,5', '1.500,55').text, '1.500,55');
      expect(format('1.500,55', '1.500,559').text, '1.500,55');
    });

    test('ignores non-numeric characters', () {
      expect(format('150', '150a').text, '150');
    });
  });
}
