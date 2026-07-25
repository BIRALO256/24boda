import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:theme/theme.dart';

import 'package:customer_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:customer_app/features/home/presentation/providers/location_provider.dart';
import 'package:customer_app/features/home/presentation/providers/map_provider.dart';
import 'package:customer_app/features/home/presentation/widgets/delivery_bottom_sheet.dart';
import 'package:customer_app/features/home/presentation/widgets/home_top_bar.dart';
import 'package:customer_app/features/home/presentation/widgets/map_view.dart';
import 'package:customer_app/features/home/presentation/screens/name_collection_sheet.dart';

/// The customer home screen.
///
/// This is a pure ORCHESTRATOR — it contains no business logic.
/// It composes widgets, listens to state changes, and coordinates
/// between providers. Every visual element lives in its own widget file.
///
/// Architecture decisions:
///
/// Stack layout (not Column/Row):
/// The map must fill 100% of the screen. The top bar and bottom sheet
/// float OVER the map. Stack is the only layout that allows this.
/// A Column would push the map down — ruining the full-screen effect.
///
/// DraggableScrollableSheet for the bottom panel:
/// The sheet snaps between three positions: collapsed (0.12),
/// default (0.45), expanded (0.85). The snap points are tuned for
/// the thumb zone on standard 5-6" Android phones used in Uganda.
///
/// Name collection triggers here, not in a separate route:
/// Showing a bottom sheet (not a full screen) for name collection
/// lets the user see the map behind it. They can see what they're
/// signing up for while providing their name.
/// Research: showing the product value during onboarding increases
/// completion rates by 30-40% vs blocking with a full screen form.
///
/// Location fetch on mount:
/// GPS fetch is triggered in initState — it runs once, in the background,
/// while the map is already visible. The user sees the map immediately
/// and the location pin drops in when GPS resolves.
/// This is the Uber/Bolt pattern — never block the UI waiting for GPS.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch GPS location on mount — non-blocking.
    // The map shows immediately, location pin drops in when GPS resolves.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    // 1. Fetch current location
    await ref.read(locationNotifierProvider.notifier).fetchCurrentLocation();

    // 2. Check if name collection is needed (first-time user)
    if (!mounted) return;
    final user = ref.read(currentUserProvider);
    if (user != null && (user.name.isEmpty)) {
      _showNameCollectionSheet();
    }
  }

  void _showNameCollectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const NameCollectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // When GPS loads, animate the map camera to the user's position
    // and drop the current location marker
    ref.listen<AsyncValue<LocationState>>(
      locationNotifierProvider,
      (_, next) {
        next.whenData((state) {
          if (state is LocationLoaded) {
            final pos = LatLng(
              state.location.lat,
              state.location.lng,
            );

            // Animate camera to GPS position
            ref.read(mapNotifierProvider.notifier).animateTo(pos);

            // Add current location marker
            ref.read(mapMarkersProvider.notifier).state = {
              Marker(
                markerId: const MarkerId('current_location'),
                position: pos,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
                infoWindow: const InfoWindow(title: 'Your location'),
              ),
            };
          }
        });
      },
    );

    return Scaffold(
      // extendBodyBehindAppBar: no AppBar used — map fills everything
      backgroundColor: AppColors.background,
      // resizeToAvoidBottomInset: false — the keyboard should not
      // resize the map when search fields are focused
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Layer 1: Full-screen map (bottom of stack) ───────────────────
          const Positioned.fill(
            child: MapView(),
          ),

          // ── Layer 2: Floating top bar ────────────────────────────────────
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeTopBar(),
          ),

          // ── Layer 3: Draggable bottom sheet ──────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.42,
            minChildSize: 0.12,
            maxChildSize: 0.85,
            snap: true,
            snapSizes: const [0.12, 0.42, 0.85],
            builder: (context, scrollController) {
              return DeliveryBottomSheet(
                scrollController: scrollController,
              );
            },
          ),

          // ── Layer 4: My location FAB ─────────────────────────────────────
          // Positioned above the default bottom sheet height (0.42)
          // so it's always visible and reachable with the right thumb
          Positioned(
            right: AppSpacing.md,
            bottom: MediaQuery.of(context).size.height * 0.44,
            child: const MyLocationButton(),
          ),
        ],
      ),
    );
  }
}
