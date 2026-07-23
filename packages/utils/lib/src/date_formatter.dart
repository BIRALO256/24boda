/// Date and time formatting utilities for 24Boda.
///
/// Formats dates for display in the app — relative time for recent events,
/// absolute time for older ones.
///
/// Why relative time ("2 mins ago") and not absolute time?
/// Research on delivery apps consistently shows users find relative time
/// more useful for tracking. "Picked up 3 mins ago" is more meaningful
/// than "Picked up at 14:32:07". Absolute time is used for history screens
/// where the user needs to reconcile with receipts or records.
abstract final class DateFormatter {
  /// Formats a [DateTime] as a human-friendly relative time string.
  ///
  /// Rules:
  /// - < 1 minute ago  → "Just now"
  /// - < 60 minutes    → "X mins ago"
  /// - < 24 hours      → "X hrs ago"
  /// - Yesterday       → "Yesterday at HH:MM"
  /// - This year       → "DD MMM at HH:MM"  e.g. "14 Jul at 09:30"
  /// - Older           → "DD MMM YYYY"       e.g. "14 Jul 2024"
  static String relative(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'min' : 'mins'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hr' : 'hrs'} ago';
    }

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateOnly == yesterday) {
      return 'Yesterday at ${_timeHHMM(dateTime)}';
    }

    if (dateTime.year == now.year) {
      return '${dateTime.day} ${_monthShort(dateTime.month)} at ${_timeHHMM(dateTime)}';
    }

    return '${dateTime.day} ${_monthShort(dateTime.month)} ${dateTime.year}';
  }

  /// Formats a [DateTime] as a short time string: "HH:MM"
  ///
  /// Used on the tracking screen for status timestamps.
  /// Example: DateTime(2024, 7, 14, 9, 5) → "09:05"
  static String timeOnly(DateTime dateTime) => _timeHHMM(dateTime);

  /// Formats a [DateTime] as a full readable date: "Monday, 14 July 2024"
  ///
  /// Used on shipment history and receipt screens.
  static String fullDate(DateTime dateTime) {
    return '${_dayName(dateTime.weekday)}, ${dateTime.day} ${_monthFull(dateTime.month)} ${dateTime.year}';
  }

  /// Formats a [DateTime] as a short date: "14 Jul 2024"
  ///
  /// Used for compact history list items.
  static String shortDate(DateTime dateTime) {
    return '${dateTime.day} ${_monthShort(dateTime.month)} ${dateTime.year}';
  }

  /// Formats a duration as a countdown string.
  ///
  /// Used for the rider job request timer (e.g. "0:28" counting down).
  /// Example: Duration(seconds: 28) → "0:28"
  ///          Duration(seconds: 90) → "1:30"
  static String countdown(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static String _timeHHMM(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _monthShort(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];

  static String _monthFull(int month) => const [
        'January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August',
        'September', 'October', 'November', 'December',
      ][month - 1];

  static String _dayName(int weekday) => const [
        'Monday', 'Tuesday', 'Wednesday',
        'Thursday', 'Friday', 'Saturday', 'Sunday',
      ][weekday - 1];
}
