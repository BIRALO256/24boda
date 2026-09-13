import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The customer-confirmed pickup used by quoting and shipment creation.
/// GPS results remain suggestions until they enter this state.
final class PickupSelectionNotifier
    extends AutoDisposeNotifier<LocationSnapshot?> {
  @override
  LocationSnapshot? build() => null;

  void confirm(LocationSnapshot pickup) => state = pickup;

  void clear() => state = null;
}

final pickupSelectionProvider =
    AutoDisposeNotifierProvider<PickupSelectionNotifier, LocationSnapshot?>(
      PickupSelectionNotifier.new,
    );
