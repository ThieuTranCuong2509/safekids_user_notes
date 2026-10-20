import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();

  static String formatTimestamp(int epochMs) {
    if (epochMs <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final now = DateTime.now();

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    }
    if (date.year == now.year) {
      return DateFormat('MMM d, HH:mm').format(date);
    }
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
