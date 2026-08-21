import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:core_models/core_models.dart';
import 'package:theme/theme.dart';
import 'package:utils/utils.dart';

import 'package:customer_app/features/tracking/presentation/providers/tracking_provider.dart';
import 'package:customer_app/features/tracking/presentation/widgets/rider_info_card.dart';
import 'package:customer_app/features/tracking/presentation/widgets/tracking_status_bar.dart';

/// Real-time delivery tracking screen.
///
/// Architecture:
/// - [shipmentStreamProvider] — listens to shipment document for status changes
/// - [riderLocationProvider] — listens to rider document for location changes
/// - Google Map updates the rider marker position in real time
///
/// Why two separate streams?
/// Status changes infrequently (4-5 times per delivery).
/// Rider location changes every 5 seconds.
/// Separating them prevents the status card from rebuilding
/// 12x per minute unnecessarily. Each provider only triggers
/// rebuilds when its specific data changes.
///
/// Map behaviour:
/// - Pickup pin (orange) — where the rider is going first
/// - Dropoff pin (dark) — final destination
/// - Rider pin (moving boda icon) — updates in real time
/// - Camera follows the rider as they move
///
/// When status = delivered:
/// The shipment is terminal. We show a success state and offer
/// a "Rate your rider" button (rating feature in next step).
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({
    super.key,
    required this.shipmentId,
    required this.riderId,
  });

  final String shipmentId;
  final String riderId;

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  GoogleMapController? _mapController;

  // Markers shown on the map
  Set<Marker> _markers = {};

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Animates the camera to show both the rider and the relevant destination.
  Future<void> _animateCameraToFit(LatLng point1, LatLng point2) async {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        point1.latitude < point2.latitude ? point1.latitude : point2.latitude,
        point1.longitude < point2.longitude
            ? point1.longitude
            : point2.longitude,
      ),
      northeast: LatLng(
        point1.latitude > point2.latitude ? point1.latitude : point2.latitude,
        point1.longitude > point2.longitude
            ? point1.longitude
            : point2.longitude,
      ),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shipmentAsync = ref.watch(shipmentStreamProvider(widget.shipmentId));
    final riderLocationAsync =
        ref.watch(riderLocationProvider(widget.riderId));

    // React to shipment status changes
    ref.listen(shipmentStreamProvider(widget.shipmentId), (_, next) {
      next.whenData((shipment) {
        if (shipment.status == ShipmentStatus.delivered) {
          // TODO: navigate to rating screen in next step
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Package delivered! Rate your rider.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      });
    });

    return shipmentAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text('Could not load tracking info. $error'),
        ),
      ),
      data: (shipment) {
        // Build map markers
        _buildMarkers(shipment, riderLocationAsync.valueOrNull);

        // Animate camera when rider location updates
        final riderLocation = riderLocationAsync.valueOrNull;
        if (riderLocation != null) {
          final riderLatLng = LatLng(riderLocation.lat, riderLocation.lng);
          final destination = shipment.status == ShipmentStatus.enRoutePickup ||
                  shipment.status == ShipmentStatus.accepted
              ? LatLng(shipment.pickup.lat, shipment.pickup.lng)
              : LatLng(shipment.dropoff.lat, shipment.dropoff.lng);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _animateCameraToFit(riderLatLng, destination);
          });
        }

        // Fetch rider profile for the info card
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // ── Layer 1: Full-screen map ─────────────────────────────────
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      shipment.pickup.lat,
                      shipment.pickup.lng,
                    ),
                    zoom: 14,
                  ),
                  onMapCreated: _onMapCreated,
                  markers: _markers,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  trafficEnabled: true,
                ),
              ),

              // ── Layer 2: Back button ─────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        // Back to home
                        GestureDetector(
                          onTap: () => Navigator.of(context)
                              .popUntil((route) => route.isFirst),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.dark.withValues(alpha: 0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.dark,
                            ),
                          ),
                        ),

                        const SizedBox(width: AppSpacing.sm),

                        // Status pill
                        TrackingStatusBar(status: shipment.status),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Layer 3: Rider info card (bottom) ────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _RiderInfoLoader(
                  riderId: widget.riderId,
                  shipment: shipment,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _buildMarkers(Shipment shipment, Location? riderLocation) {
    final markers = <Marker>{};

    // Pickup pin — orange
    markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: LatLng(shipment.pickup.lat, shipment.pickup.lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueOrange,
      ),
      infoWindow: InfoWindow(title: 'Pickup', snippet: shipment.pickup.address),
    ));

    // Dropoff pin — dark red
    markers.add(Marker(
      markerId: const MarkerId('dropoff'),
      position: LatLng(shipment.dropoff.lat, shipment.dropoff.lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      ),
      infoWindow:
          InfoWindow(title: 'Dropoff', snippet: shipment.dropoff.address),
    ));

    // Rider pin — moves in real time
    if (riderLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('rider'),
        position: LatLng(riderLocation.lat, riderLocation.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
        infoWindow: const InfoWindow(title: 'Your rider'),
      ));
    }

    setState(() => _markers = markers);
  }
}

/// Loads the rider's UserProfile from Firestore for the info card.
///
/// Separated into its own widget so it has its own async boundary.
/// The tracking map doesn't rebuild when the rider profile loads.
class _RiderInfoLoader extends ConsumerWidget {
  const _RiderInfoLoader({
    required this.riderId,
    required this.shipment,
  });

  final String riderId;
  final Shipment shipment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riderProfileAsync = ref.watch(_riderProfileProvider(riderId));

    return riderProfileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return RiderInfoCard(rider: profile, shipment: shipment);
      },
    );
  }
}

/// Fetches the rider's UserProfile from Firestore.
final _riderProfileProvider =
    FutureProvider.autoDispose.family<UserProfile?, String>((ref, riderId) async {
  if (riderId.isEmpty) return null;

  final doc = await FirebaseFirestore.instance
      .collection(FirestoreCollections.users)
      .doc(riderId)
      .get();

  if (!doc.exists || doc.data() == null) return null;
  return UserProfile.fromMap(doc.data()!);
});
