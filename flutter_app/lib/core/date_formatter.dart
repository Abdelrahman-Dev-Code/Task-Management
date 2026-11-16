/// أدوات تنسيق التواريخ والأوقات باللغة العربية بشكل مقروء وسريع
class DateFormatter {
  /// تحويل نص تاريخ (ISO 8601 أو YYYY-MM-DD HH:mm:ss) إلى وصف عربي نسبي
  static String formatRelative(String raw) {
    final dt = tryParse(raw);
    if (dt == null) return raw;

    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inSeconds < 60 && !diff.isNegative) {
      return 'الآن';
    }
    if (diff.inMinutes < 60 && !diff.isNegative) {
      final m = diff.inMinutes;
      return m == 1 ? 'منذ دقيقة' : 'منذ $m دقائق';
    }
    if (diff.inHours < 24 && local.day == now.day && local.month == now.month && local.year == now.year) {
      return 'اليوم • ${_formatTime(local)}';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return 'أمس • ${_formatTime(local)}';
    }

    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '${local.year}/$mm/$dd • ${_formatTime(local)}';
  }

  /// تنسيق تاريخ الاستحقاق مع توضيح (اليوم / غداً / متأخرة)
  static String formatDueDate(String dueDate, {bool isCompleted = false}) {
    final parsed = tryParse(dueDate);
    if (parsed == null) return dueDate;

    final target = DateTime(parsed.year, parsed.month, parsed.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysDiff = target.difference(today).inDays;

    if (!isCompleted && daysDiff < 0) {
      final absDays = daysDiff.abs();
      return absDays == 1 ? 'متأخرة منذ أمس' : 'متأخرة منذ $absDays أيام';
    }
    if (daysDiff == 0) return 'اليوم ($dueDate)';
    if (daysDiff == 1) return 'غداً ($dueDate)';
    return dueDate;
  }

  static DateTime? tryParse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    // دعم صيغة MySQL/Laravel مثل "2026-11-16 14:30:00" بالإضافة إلى ISO 8601
    final normalized = trimmed.contains('T') ? trimmed : trimmed.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized);
  }

  static String _formatTime(DateTime dt) {
    final hour24 = dt.hour;
    final period = hour24 >= 12 ? 'م' : 'ص';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour12:$min $period';
  }
}
