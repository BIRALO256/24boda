import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utils/utils.dart';

import 'package:customer_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:customer_app/features/shipment/domain/usecases/create_shipment.dart';
import 'package:customer_app/features/shipment/domain/usecases/watch_shipment.dart';
import 'package:customer_app/features/shipment/presentation/providers/shipment_creation_state.dart';

/// Manages the full shipment creation flow state.
///
/// Single notifier for all 4 screens — holds data as user progresses
/// through: address → details → price → searching → accepted.
class ShipmentCreationNotifier
    extends AutoDisposeNotifier<ShipmentCreationState> {
  StreamSubscription<Shipment>? _shipmentSubscription;

  @override
  ShipmentCreationState build() {
    // Cancel the stream subscription when this provider is disposed
    ref.onDispose(() {
      _shipmentSubscription?.cancel();
    });

    return const ShipmentCreationIdle();
  }

  // ── Screen 1: Address picked ─────────────────────────────────────────────

  void onAddressPicked({required Location dropoff, required Location pickup}) {
    final distanceKm = DistanceFormatter.haversineKm(
      pickup.lat,
      pickup.lng,
      dropoff.lat,
      dropoff.lng,
    );
    final duration = DistanceFormatter.estimateDurationMinutes(distanceKm);

    state = ShipmentCreationAddressPicked(
      dropoff: dropoff,
      pickup: pickup,
      distanceKm: distanceKm,
      estimatedDurationMinutes: duration,
    );
  }

  // ── Screen 2: Package details entered ───────────────────────────────────

  void onDetailsEntered({
    required PackageSize packageSize,
    String? packageDescription,
    String? customerNote,
  }) {
    final current = state;
    if (current is! ShipmentCreationAddressPicked) return;

    final priceEstimate = PricingCalculator.calculate(
      distanceKm: current.distanceKm,
      vehicleType: 'boda',
      packageSize: packageSize,
    );

    state = ShipmentCreationDetailsEntered(
      dropoff: current.dropoff,
      pickup: current.pickup,
      distanceKm: current.distanceKm,
      estimatedDurationMinutes: current.estimatedDurationMinutes,
      packageSize: packageSize,
      priceEstimate: priceEstimate,
      packageDescription: packageDescription,
      customerNote: customerNote,
    );
  }

  // ── Screen 3: User confirms booking ─────────────────────────────────────

  Future<void> confirmBooking() async {
    final current = state;
    if (current is! ShipmentCreationDetailsEntered) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const ShipmentCreationSubmitting();

    try {
      final shipment = await ref
          .read(createShipmentProvider)
          .call(
            customerId: user.uid,
            pickup: current.pickup,
            dropoff: current.dropoff,
            packageSize: current.packageSize.value,
            distanceKm: current.distanceKm,
            estimatedDurationMinutes: current.estimatedDurationMinutes,
            estimatedFee: current.priceEstimate.estimatedFee,
            packageDescription: current.packageDescription,
            customerNote: current.customerNote,
          );

      state = ShipmentCreationSearching(shipment: shipment);

      // Start listening for rider acceptance
      _listenForRider(shipment.id);
    } catch (e) {
      state = ShipmentCreationError(
        message: 'Could not create your delivery. Please try again.',
      );
    }
  }

  // ── Real-time listener ───────────────────────────────────────────────────

  void _listenForRider(String shipmentId) {
    _shipmentSubscription?.cancel();
    _shipmentSubscription = ref
        .read(watchShipmentProvider)
        .call(shipmentId)
        .listen(
          (shipment) {
            if (shipment.status == ShipmentStatus.accepted ||
                shipment.status.isActive) {
              state = ShipmentCreationAccepted(shipment: shipment);
              _shipmentSubscription?.cancel();
            } else if (shipment.status == ShipmentStatus.cancelled) {
              state = const ShipmentCreationError(
                message: 'No riders found. Please try again.',
              );
            }
          },
          onError: (_) {
            state = const ShipmentCreationError(
              message: 'Connection lost. Please check your network.',
            );
          },
        );
  }

  // ── Reset ────────────────────────────────────────────────────────────────

  void reset() {
    _shipmentSubscription?.cancel();
    state = const ShipmentCreationIdle();
  }
}

final shipmentCreationProvider =
    AutoDisposeNotifierProvider<
      ShipmentCreationNotifier,
      ShipmentCreationState
    >(() {
      return ShipmentCreationNotifier();
    });
