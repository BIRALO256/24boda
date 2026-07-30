import 'package:core_models/core_models.dart';
import 'package:utils/utils.dart';

/// State machine for the shipment creation flow.
///
/// Tracks everything the user has entered across all 4 screens:
/// - Dropoff address (Screen 1)
/// - Package details (Screen 2)
/// - Calculated price (Screen 3)
/// - Created shipment (Screen 4)
///
/// Why one state object for all 4 screens?
/// The data from each screen is needed in the next screen.
/// The dropoff from Screen 1 is needed to calculate the price in Screen 3.
/// The package size from Screen 2 affects the price in Screen 3.
/// One shared state means no prop drilling between screens.
sealed class ShipmentCreationState {
  const ShipmentCreationState();
}

/// Initial state — user hasn't started yet.
final class ShipmentCreationIdle extends ShipmentCreationState {
  const ShipmentCreationIdle();
}

/// User has picked a dropoff address. Ready to go to Screen 2.
final class ShipmentCreationAddressPicked extends ShipmentCreationState {
  const ShipmentCreationAddressPicked({
    required this.dropoff,
    required this.pickup,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
  });

  final Location dropoff;
  final Location pickup;
  final double distanceKm;
  final int estimatedDurationMinutes;
}

/// User has filled in package details. Ready for price estimate.
final class ShipmentCreationDetailsEntered extends ShipmentCreationState {
  const ShipmentCreationDetailsEntered({
    required this.dropoff,
    required this.pickup,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.packageSize,
    required this.priceEstimate,
    this.packageDescription,
    this.customerNote,
  });

  final Location dropoff;
  final Location pickup;
  final double distanceKm;
  final int estimatedDurationMinutes;
  final PackageSize packageSize;
  final PriceEstimate priceEstimate;
  final String? packageDescription;
  final String? customerNote;
}

/// Creating the shipment in Firestore — loading state.
final class ShipmentCreationSubmitting extends ShipmentCreationState {
  const ShipmentCreationSubmitting();
}

/// Shipment created and status is 'searching' — real-time listener active.
final class ShipmentCreationSearching extends ShipmentCreationState {
  const ShipmentCreationSearching({required this.shipment});
  final Shipment shipment;
}

/// A rider accepted the shipment. Move to tracking screen.
final class ShipmentCreationAccepted extends ShipmentCreationState {
  const ShipmentCreationAccepted({required this.shipment});
  final Shipment shipment;
}

/// Something went wrong.
final class ShipmentCreationError extends ShipmentCreationState {
  const ShipmentCreationError({required this.message});
  final String message;
}
