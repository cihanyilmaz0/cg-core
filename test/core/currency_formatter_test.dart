import 'package:flutter_test/flutter_test.dart';
import 'package:saas_isletme/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('formatCents converts cents to formatted Turkish Lira string', () {
      expect(CurrencyFormatter.formatCents(150050), '₺1.500,50');
      expect(CurrencyFormatter.formatCents(0), '₺0,00');
      expect(CurrencyFormatter.formatCents(100), '₺1,00');
      expect(CurrencyFormatter.formatCents(99), '₺0,99');
      expect(CurrencyFormatter.formatCents(null), '₺0,00');
    });

    test('formatCents without symbol returns bare number', () {
      expect(CurrencyFormatter.formatCents(150050, includeSymbol: false), '1.500,50');
    });

    test('parseToCents handles comma and dot separators without precision loss', () {
      expect(CurrencyFormatter.parseToCents('2.000'), 200000);
      expect(CurrencyFormatter.parseToCents('25.000'), 2500000);
      expect(CurrencyFormatter.parseToCents('1.500.000'), 150000000);
      expect(CurrencyFormatter.parseToCents('1.500,50'), 150050);
      expect(CurrencyFormatter.parseToCents('1500,50'), 150050);
      expect(CurrencyFormatter.parseToCents('1500.50'), 150050);
      expect(CurrencyFormatter.parseToCents('1500'), 150000);
      expect(CurrencyFormatter.parseToCents('₺1.500,50'), 150050);
      expect(CurrencyFormatter.parseToCents('0'), 0);
      expect(CurrencyFormatter.parseToCents(''), 0);
      expect(CurrencyFormatter.parseToCents(null), 0);
    });

    test('centsToLira and liraToCents conversions', () {
      expect(CurrencyFormatter.centsToLira(150050), 1500.50);
      expect(CurrencyFormatter.liraToCents(1500.50), 150050);
    });
  });
}
