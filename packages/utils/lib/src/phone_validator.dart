/// Phone number validation and formatting utilities for 24Boda.
///
/// Uganda context:
/// - Country code: +256
/// - Mobile numbers: 9 digits after country code
/// - Major networks:
///   MTN Uganda:    077x, 078x, 076x
///   Airtel Uganda: 070x, 075x, 074x
///
/// All phone numbers are stored in E.164 format in Firestore: +256XXXXXXXXX
/// This is the international standard and what Firebase Auth expects.
abstract final class PhoneValidator {
  /// E.164 pattern for Uganda mobile numbers.
  /// Matches: +256 followed by 7 then 8 more digits (total 9 after code).
  /// Covers MTN (077, 078, 076) and Airtel (070, 074, 075).
  static final RegExp _ugandaE164 = RegExp(r'^\+256[7][0-9]{8}$');

  /// Local Uganda pattern — 10 digits starting with 07.
  /// Users often type their number without the country code.
  static final RegExp _ugandaLocal = RegExp(r'^0[7][0-9]{8}$');

  /// Validates a phone number as a Uganda mobile number.
  ///
  /// Accepts both formats:
  /// - E.164: +256700123456
  /// - Local:  0700123456
  ///
  /// Returns true if valid, false otherwise.
  static bool isValid(String phone) {
    final cleaned = _clean(phone);
    return _ugandaE164.hasMatch(cleaned) || _ugandaLocal.hasMatch(cleaned);
  }

  /// Converts any valid Uganda phone number to E.164 format.
  ///
  /// Examples:
  /// - "0700123456"    → "+256700123456"
  /// - "+256700123456" → "+256700123456" (already correct)
  /// - "700123456"     → "+256700123456" (missing leading zero)
  ///
  /// Throws [FormatException] if the number is not a valid Uganda number.
  static String toE164(String phone) {
    final cleaned = _clean(phone);

    if (_ugandaE164.hasMatch(cleaned)) return cleaned;

    if (_ugandaLocal.hasMatch(cleaned)) {
      // Replace leading 0 with +256
      return '+256${cleaned.substring(1)}';
    }

    // Handle numbers entered without leading 0 e.g. "700123456"
    if (RegExp(r'^7[0-9]{8}$').hasMatch(cleaned)) {
      return '+256$cleaned';
    }

    throw FormatException(
      'Invalid Uganda phone number: $phone. '
      'Expected format: 0700123456 or +256700123456',
    );
  }

  /// Formats a phone number for display in the UI.
  ///
  /// Converts E.164 to a readable local format.
  /// Example: "+256700123456" → "0700 123 456"
  static String toDisplayFormat(String phone) {
    try {
      final e164 = toE164(phone);
      // Remove +256 prefix, add leading 0, then space-format
      final local = '0${e164.substring(4)}';
      // Format as: 0XXX XXX XXX
      return '${local.substring(0, 4)} ${local.substring(4, 7)} ${local.substring(7)}';
    } catch (_) {
      return phone; // Return as-is if we can't format it
    }
  }

  /// Returns a validation error message, or null if valid.
  ///
  /// Designed to be used directly with Flutter's [TextFormField.validator]:
  /// ```dart
  /// validator: PhoneValidator.errorMessage,
  /// ```
  static String? errorMessage(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    if (!isValid(phone.trim())) {
      return 'Enter a valid Uganda phone number (e.g. 0700 123 456)';
    }
    return null;
  }

  /// Strips all non-digit and non-plus characters from a phone string.
  static String _clean(String phone) {
    return phone.trim().replaceAll(RegExp(r'[\s\-()]'), '');
  }
}
