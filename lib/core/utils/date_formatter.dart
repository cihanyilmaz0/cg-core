import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'tr_TR');
  static final DateFormat _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'tr_TR');
  static final DateFormat _periodIdFormat = DateFormat('yyyy-MM');

  static String formatDate(dynamic date) {
    if (date == null) return '-';
    final DateTime dt = _toDateTime(date);
    return _dateFormat.format(dt);
  }

  static String formatDateTime(dynamic date) {
    if (date == null) return '-';
    final DateTime dt = _toDateTime(date);
    return _dateTimeFormat.format(dt);
  }

  static String formatMonthYear(dynamic date) {
    if (date == null) return '-';
    final DateTime dt = _toDateTime(date);
    return _monthYearFormat.format(dt);
  }

  static String toPeriodId(DateTime date) {
    return _periodIdFormat.format(date);
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }
}
