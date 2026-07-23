/// Currency formatting utilities for 24Boda.
///
/// Uganda Shilling (UGX) context:
/// - No decimal places — UGX does not use cents in practice
/// - Thousands separator: comma (e.g. 5,000 not 5000)
/// - Currency prefix: "UGX" or "USh" — we use "UGX" for clarity
/// - Typical delivery fee range: UGX 2,000 — UGX 25,000
///
/// Why no decimal places?
/// UGX is a low-value currency. 1 USD ≈ 3,700 UGX. Nobody
/// prices anything in fractional shillings in Uganda.
/// Showing "UGX 5,000.00" looks foreign and unnatural to local users.
abstract final class CurrencyFormatter {
  /// The currency code used throughout the app.
  static const String currencyCode = 'UGX';

  /// Formats a number as a full UGX amount with currency prefix.
  ///
  /// Examples:
  /// - 5000   → "UGX 5,000"
  /// - 12500  → "UGX 12,500"
  /// - 1000   → "UGX 1,000"
  static String format(double amount) {
    return '$currencyCode ${_formatNumber(amount)}';
  }

  /// Formats a number as UGX without the currency prefix.
  /// Used when the currency is already shown elsewhere in the UI.
  ///
  /// Examples:
  /// - 5000  → "5,000"
  /// - 12500 → "12,500"
  static String formatCompact(double amount) {
    return _formatNumber(amount);
  }

  /// Formats a price range for display on the estimate screen.
  ///
  /// Example: estimateRange(4500, 6000) → "UGX 4,500 – 6,000"
  static String estimateRange(double min, double max) {
    return '$currencyCode ${_formatNumber(min)} – ${_formatNumber(max)}';
  }

  /// Formats rider earnings with a positive prefix.
  ///
  /// Example: earnings(8000) → "+ UGX 8,000"
  static String earnings(double amount) {
    return '+ $currencyCode ${_formatNumber(amount)}';
  }

  /// Formats a number with thousands separator, no decimals.
  static String _formatNumber(double amount) {
    final rounded = amount.round();
    final str = rounded.toString();

    // Insert comma every 3 digits from the right
    final buffer = StringBuffer();
    final chars = str.split('').reversed.toList();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(',');
      buffer.write(chars[i]);
    }
    return buffer.toString().split('').reversed.join();
  }
}
