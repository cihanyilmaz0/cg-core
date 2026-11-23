import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Tutar girilen TextField alanlarını yazarken anlık olarak Türkçe para formatına
/// (binlik ayraçlı: 1.500,50) dönüştüren InputFormatter.
class TurkishCurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _integerFormatter = NumberFormat('#,##0', 'tr_TR');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String raw = newValue.text;

    // Kullanıcı ondalık ayraç olarak klavyeden '.' tuşuna bastıysa (örneğin Android numpad'de ',' yoksa)
    // ve metin sonuna veya yeni bir karakter olarak '.' eklendiyse bunu ',' olarak kabul et
    if (newValue.text.length > oldValue.text.length && !oldValue.text.contains(',')) {
      final oldDots = '.'.allMatches(oldValue.text).length;
      final newDots = '.'.allMatches(newValue.text).length;
      if (newDots > oldDots) {
        // Yeni eklenen son noktayı virgüle çevir
        final lastDotIndex = raw.lastIndexOf('.');
        if (lastDotIndex != -1) {
          raw = '${raw.substring(0, lastDotIndex)},${raw.substring(lastDotIndex + 1)}';
        }
      }
    }

    // Sadece rakamları ve ilk virgülü koru
    final cleaned = StringBuffer();
    bool hasComma = false;
    for (int i = 0; i < raw.length; i++) {
      final ch = raw[i];
      if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) {
        cleaned.write(ch);
      } else if (ch == ',' && !hasComma) {
        hasComma = true;
        cleaned.write(',');
      }
    }

    final cleanStr = cleaned.toString();
    if (cleanStr.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    String integerPart = cleanStr;
    String? decimalPart;

    if (cleanStr.contains(',')) {
      final parts = cleanStr.split(',');
      integerPart = parts[0];
      decimalPart = parts.length > 1 ? parts[1] : '';
      // Kuruş kısmını en fazla 2 basamakla sınırla
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }
    }

    // Tam sayı kısmını binlik ayraçla formatla
    String formattedInteger;
    if (integerPart.isEmpty) {
      formattedInteger = '0';
    } else {
      final parsedInt = int.tryParse(integerPart) ?? 0;
      formattedInteger = _integerFormatter.format(parsedInt);
    }

    final formattedText = decimalPart != null
        ? '$formattedInteger,$decimalPart'
        : formattedInteger;

    // İmleci sağdan mesafeyi koruyarak yerleştir
    final int distanceFromEnd = newValue.text.length - newValue.selection.end;
    int newOffset = formattedText.length - distanceFromEnd;
    if (newOffset < 0) newOffset = 0;
    if (newOffset > formattedText.length) newOffset = formattedText.length;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
