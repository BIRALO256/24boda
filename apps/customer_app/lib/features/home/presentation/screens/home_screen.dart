import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:theme/theme.dart';

import 'package:customer_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:customer_app/features/home/presentation/providers/location_provider.dart';
import 'package:customer_app/features/home/presentation/providers/map_provider.dart';
import 'package:customer_app/features/home/presentation/screens/name_collection_sheet.dart';
import 'package:customer_app/features/home/presentation/widgets/delivery_bottom_sheet.dart';
import 'package:customer_app/features/home/presentation/widgets/home_drawer.dart';
import 'package:customer_app/features/home/presentation/widgets/home_top_bar.dart';
import 'package:customer_app/features/home/presentation/widgets/map_view.dart';

/// Customer home screen — pure orchestrator.
///
/// Stack layout: map fills 100%, top bar and bottom sheet float over it.
/// Drawer opens from the left via the menu button in the top bar.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    await ref.read(locationNotifierProvider.notifier).fetchCurrentLocation();

    if (!mounted) return;
    final user = ref.read(currentUserProvider);
    if (user != null && user.name.isEmpty) {
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
    // Animate camera and drop marker when GPS resolves
    ref.listen<AsyncValue<LocationState>>(
      locationNotifierProvider,
      (_, next) {
        next.whenData((state) {
          if (state is LocationLoaded) {
            final pos = LatLng(
              state.location.lat,
              state.location.lng,
            );
            ref.read(mapNotifierProvider.notifier).animateTo(pos);
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
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      // Drawer opens from the left
      drawer: const HomeDrawer(),
      body: Stack(
        children: [
          // Layer 1 — full-screen map
          const Positioned.fill(
            child: MapView(),
          ),

          // Layer 2 — menu button only (top-left, SafeArea aware)
          Positioned(
            top: 0,
            left: 0,
            child: HomeTopBar(
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),

          // Layer 3 — draggable bottom sheet
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

          // Layer 4 — my location FAB
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
