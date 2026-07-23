/// Delivery fee calculation logic for 24Boda.
///
/// Pricing model:
/// - Base rate per vehicle type (covers the first km)
/// - Per-km rate applied to full distance
/// - Package size surcharge
/// - Peak hour surge multiplier
/// - Platform commission: 20% (rider keeps 80%)
///
/// Why is pricing logic in utils (pure Dart) and not in a Firebase Function?
/// The estimate is shown to the customer BEFORE booking — it must be
/// instant, offline-capable, and free (no API call cost).
/// The FINAL fee is confirmed by a Cloud Function after delivery to
/// prevent client-side tampering of the commission split.
/// Both use the same formula defined here — the Function imports
/// the same constants via a shared config.
///
/// Pricing rationale (Uganda market):
/// These rates are calibrated to:
/// 1. Be affordable for customers (competitive with negotiated boda rates)
/// 2. Give riders a liveable income (UGX 8,000–15,000 per day target)
/// 3. Keep the platform commission sustainable at 20%
///
/// All amounts are in UGX.

/// The size of the package being delivered.
/// Customer selects this during booking from a 4-option picker.
/// Self-declared — not weighed or measured by the system.
enum PackageSize {
  /// Small envelope, documents, phone, keys.
  small,

  /// Laptop bag, small box, packed food order.
  medium,

  /// Large bag, multiple boxes, bulky item.
  large,

  /// Phone, screen, glassware, any breakable item.
  fragile;

  /// Human-readable label shown in the booking UI.
  String get label => switch (this) {
        PackageSize.small => 'Small',
        PackageSize.medium => 'Medium',
        PackageSize.large => 'Large',
        PackageSize.fragile => 'Fragile',
      };

  /// Short description shown below the label in the picker.
  String get description => switch (this) {
        PackageSize.small => 'Envelope, documents, phone',
        PackageSize.medium => 'Laptop bag, small box',
        PackageSize.large => 'Large bag, multiple items',
        PackageSize.fragile => 'Electronics, glassware',
      };

  /// Firestore-safe string value.
  String get value => switch (this) {
        PackageSize.small => 'small',
        PackageSize.medium => 'medium',
        PackageSize.large => 'large',
        PackageSize.fragile => 'fragile',
      };

  /// Deserialise from Firestore string.
  static PackageSize fromValue(String value) => switch (value) {
        'small' => PackageSize.small,
        'medium' => PackageSize.medium,
        'large' => PackageSize.large,
        'fragile' => PackageSize.fragile,
        _ => throw ArgumentError('Unknown PackageSize value: $value'),
      };
}

/// The result of a pricing calculation.
/// Contains the estimated fee, its breakdown, and rider earnings.
class PriceEstimate {
  const PriceEstimate({
    required this.estimatedFee,
    required this.riderEarnings,
    required this.platformCommission,
    required this.baseRate,
    required this.distanceCharge,
    required this.sizeSurcharge,
    required this.surgeMultiplier,
    required this.currency,
  });

  /// Total fee shown to the customer.
  final double estimatedFee;

  /// Rider's share — always 80% of [estimatedFee].
  final double riderEarnings;

  /// Platform's share — always 20% of [estimatedFee].
  final double platformCommission;

  /// The base rate component of the fee.
  final double baseRate;

  /// The distance-based component of the fee.
  final double distanceCharge;

  /// The package size surcharge component.
  final double sizeSurcharge;

  /// The surge multiplier applied (1.0 = no surge).
  final double surgeMultiplier;

  /// Currency code — always 'UGX'.
  final String currency;

  /// Whether surge pricing is currently active.
  bool get isSurge => surgeMultiplier > 1.0;

  @override
  String toString() =>
      'PriceEstimate(estimatedFee: $estimatedFee, riderEarnings: $riderEarnings, surge: $surgeMultiplier)';
}

/// Calculates delivery fee estimates for 24Boda shipments.
abstract final class PricingCalculator {
  // ── Rate tables (UGX) ────────────────────────────────────────────────────

  /// Base rates per vehicle type (UGX).
  /// Covers the minimum cost regardless of distance.
  static const Map<String, double> _baseRates = {
    'boda': 3000,
    'bicycle': 2000,
    'car': 8000,
  };

  /// Per-kilometre rates per vehicle type (UGX).
  static const Map<String, double> _perKmRates = {
    'boda': 500,
    'bicycle': 300,
    'car': 1000,
  };

  /// Package size surcharge as a multiplier on the subtotal.
  /// small = 0% surcharge, large = 50% surcharge.
  static const Map<String, double> _sizeSurcharges = {
    'small': 0.00,
    'medium': 0.20,
    'large': 0.50,
    'fragile': 0.30,
  };

  /// Platform commission rate — rider keeps 80%, platform takes 20%.
  static const double platformCommissionRate = 0.20;
  static const double riderShareRate = 0.80;

  // ── Peak hours ────────────────────────────────────────────────────────────

  /// Peak hour surge multiplier.
  /// Applied during morning rush (7–9 AM) and evening rush (5–8 PM).
  /// Increases rider earnings during high-demand periods,
  /// which incentivises more riders to come online when needed most.
  static const double _surgeMultiplier = 1.3;

  /// Whether the given hour is a peak hour.
  static bool _isPeakHour(int hour) =>
      (hour >= 7 && hour < 9) || (hour >= 17 && hour < 20);

  // ── Main calculation ──────────────────────────────────────────────────────

  /// Calculates a delivery fee estimate.
  ///
  /// Parameters:
  /// - [distanceKm]: straight-line distance (from [DistanceFormatter.haversineKm])
  /// - [vehicleType]: 'boda', 'bicycle', or 'car'
  /// - [packageSize]: the [PackageSize] selected by the customer
  /// - [bookingTime]: when the booking is made (defaults to now)
  ///
  /// Returns a [PriceEstimate] with full breakdown.
  ///
  /// Example:
  /// ```dart
  /// final estimate = PricingCalculator.calculate(
  ///   distanceKm: 3.5,
  ///   vehicleType: 'boda',
  ///   packageSize: PackageSize.small,
  /// );
  /// // estimate.estimatedFee → 4,750 UGX
  /// ```
  static PriceEstimate calculate({
    required double distanceKm,
    required String vehicleType,
    required PackageSize packageSize,
    DateTime? bookingTime,
  }) {
    final time = bookingTime ?? DateTime.now();
    final type = vehicleType.toLowerCase();

    // 1. Base rate for this vehicle type
    final baseRate = _baseRates[type] ?? _baseRates['boda']!;

    // 2. Distance charge
    final perKm = _perKmRates[type] ?? _perKmRates['boda']!;
    final distanceCharge = perKm * distanceKm;

    // 3. Subtotal before size surcharge
    final subtotal = baseRate + distanceCharge;

    // 4. Package size surcharge
    final surchargeRate = _sizeSurcharges[packageSize.value] ?? 0.0;
    final sizeSurcharge = subtotal * surchargeRate;

    // 5. Subtotal after size surcharge
    final subtotalWithSize = subtotal + sizeSurcharge;

    // 6. Surge multiplier for peak hours
    final surgeMultiplier =
        _isPeakHour(time.hour) ? _surgeMultiplier : 1.0;

    // 7. Final fee — rounded to nearest 50 UGX for clean pricing
    final rawFee = subtotalWithSize * surgeMultiplier;
    final estimatedFee = _roundToNearest50(rawFee);

    // 8. Commission split
    final riderEarnings = estimatedFee * riderShareRate;
    final platformCommission = estimatedFee * platformCommissionRate;

    return PriceEstimate(
      estimatedFee: estimatedFee,
      riderEarnings: riderEarnings,
      platformCommission: platformCommission,
      baseRate: baseRate,
      distanceCharge: distanceCharge,
      sizeSurcharge: sizeSurcharge,
      surgeMultiplier: surgeMultiplier,
      currency: 'UGX',
    );
  }

  /// Returns an estimate range (min, max) shown before the customer
  /// selects a vehicle type. Uses boda as the cheapest option.
  ///
  /// Returns a tuple of (minFee, maxFee) in UGX.
  static (double min, double max) estimateRange(double distanceKm) {
    final min = calculate(
      distanceKm: distanceKm,
      vehicleType: 'boda',
      packageSize: PackageSize.small,
    ).estimatedFee;

    final max = calculate(
      distanceKm: distanceKm,
      vehicleType: 'car',
      packageSize: PackageSize.large,
    ).estimatedFee;

    return (min, max);
  }

  /// Rounds a fee to the nearest 50 UGX.
  /// Clean round numbers feel more natural in the Ugandan market.
  /// e.g. 4,823 → 4,850 | 4,812 → 4,800
  static double _roundToNearest50(double amount) {
    return (amount / 50).round() * 50.0;
  }
}
