import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  static final NumberFormat _numberFormat = NumberFormat('#,##0.00', 'tr_TR');

  /// Kuruş cinsinden tam sayıyı (örn: 150050) Türkçe para formatına çevirir (örn: 1.500,50 ₺)
  static String formatCents(int? cents, {bool includeSymbol = true}) {
    final double lira = (cents ?? 0) / 100.0;
    if (includeSymbol) {
      return _currencyFormat.format(lira);
    }
    return _numberFormat.format(lira);
  }

  /// Kullanıcının girdiği metinsel TL değerini (örn: "1.500,50" veya "1500.50") hatasız kuruş (int) değerine dönüştürür.
  static int parseToCents(String? input) {
    if (input == null || input.trim().isEmpty) return 0;

    String clean = input.trim();
    // ₺ sembolü veya boşlukları temizle
    clean = clean.replaceAll('₺', '').replaceAll(' ', '');

    // Eğer hem nokta hem virgül varsa (örn 1.250,50)
    if (clean.contains('.') && clean.contains(',')) {
      // Noktaları binlik ayracı varsayarak kaldır, virgülü noktaya çevir
      clean = clean.replaceAll('.', '').replaceAll(',', '.');
    } else if (clean.contains(',')) {
      // Yalnızca virgül varsa (örn 1500,50)
      clean = clean.replaceAll(',', '.');
    } else if (clean.contains('.')) {
      // Yalnızca nokta varsa: birden fazla nokta (1.000.000) veya
      // noktadan sonra tam 3 rakam (2.000, 15.500) Türkçe binlik ayracıdır
      final dotCount = '.'.allMatches(clean).length;
      final afterLastDot = clean.split('.').last;
      if (dotCount > 1 || afterLastDot.length == 3) {
        clean = clean.replaceAll('.', '');
      }
    }

    final double? parsed = double.tryParse(clean);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return 0;

    // Yuvarlama hatasını önlemek için round kullan
    return (parsed * 100).round();
  }

  /// Kuruş değerini double TL değerine dönüştürür
  static double centsToLira(int? cents) {
    return (cents ?? 0) / 100.0;
  }

  /// TL değerini kuruşa çevirir
  static int liraToCents(double? lira) {
    if (lira == null || lira.isNaN || lira.isInfinite) return 0;
    return (lira * 100).round();
  }
}
