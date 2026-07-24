/// 24Boda utilities package.
///
/// Pure Dart — zero Flutter, zero Firebase dependencies.
/// Import this single file to access everything:
///
/// ```dart
/// import 'package:utils/utils.dart';
///
/// // Firestore constants
/// FirestoreCollections.shipments
/// ShipmentFields.status
///
/// // Validation
/// PhoneValidator.isValid('+256700123456')
/// PhoneValidator.errorMessage  // use directly as TextFormField validator
///
/// // Formatting
/// CurrencyFormatter.format(5000)        // "UGX 5,000"
/// DistanceFormatter.format(2.3)         // "2.3 km"
/// DistanceFormatter.haversineKm(...)    // straight-line distance
/// DateFormatter.relative(dateTime)      // "3 mins ago"
///
/// // Pricing
/// PricingCalculator.calculate(
///   distanceKm: 3.5,
///   vehicleType: 'boda',
///   packageSize: PackageSize.small,
/// )
/// ```
library;

export 'src/currency_formatter.dart';
export 'src/date_formatter.dart';
export 'src/distance_formatter.dart';
export 'src/firestore_collections.dart';
export 'src/phone_validator.dart';
export 'src/pricing_calculator.dart';
