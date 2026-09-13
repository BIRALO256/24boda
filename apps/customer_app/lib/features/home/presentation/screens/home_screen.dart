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
import 'package:customer_app/features/home/presentation/widgets/location_status_banner.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    final locationState = ref.read(locationNotifierProvider).valueOrNull;
    if (shouldRefreshLocationAfterBackground(
      state: locationState,
      backgroundedAt: backgroundedAt,
      resumedAt: DateTime.now(),
    )) {
      ref.read(locationNotifierProvider.notifier).fetchCurrentLocation();
    }
  }

  Future<void> _initializeScreen() async {
    await ref.read(locationNotifierProvider.notifier).fetchCurrentLocation();

    if (!mounted) return;
    final user = ref.read(currentUserProvider);
    if (user != null && !user.isActive) {
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
    final locationState = ref.watch(locationNotifierProvider).valueOrNull;

    // Animate camera and drop marker when GPS resolves
    ref.listen<AsyncValue<LocationState>>(locationNotifierProvider, (_, next) {
      next.whenData((state) {
        final location = switch (state) {
          LocationLoaded(:final location) => location,
          LocationLowAccuracy(:final location) => location,
          _ => null,
        };
        if (location != null) {
          final pos = LatLng(location.lat, location.lng);
          ref.read(mapNotifierProvider.notifier).animateTo(pos);
        }
      });
    });

    // Do not reveal a geographically false map or partially initialized home
    // screen. Errors are allowed through so the customer can recover or choose
    // a pickup manually instead of being trapped behind a loader.
    if (locationState == null ||
        locationState is LocationInitial ||
        locationState is LocationLoading) {
      return const _LocationStartupView();
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      // Drawer opens from the left
      drawer: const HomeDrawer(),
      body: Stack(
        children: [
          // Layer 1 — full-screen map
          const Positioned.fill(child: MapView()),

          // Layer 2 — menu button only (top-left, SafeArea aware)
          Positioned(
            top: 0,
            left: 0,
            child: HomeTopBar(
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),

          Positioned(
            top: MediaQuery.paddingOf(context).top + 64,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: const LocationStatusBanner(),
          ),

          // Layer 3 — draggable bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.42,
            minChildSize: 0.12,
            maxChildSize: 0.85,
            snap: true,
            snapSizes: const [0.12, 0.42, 0.85],
            builder: (context, scrollController) {
              return DeliveryBottomSheet(scrollController: scrollController);
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

class _LocationStartupView extends StatelessWidget {
  const _LocationStartupView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Image(
                image: AssetImage('packages/theme/assets/images/logo.png'),
                width: 88,
                height: 88,
              ),
              SizedBox(height: AppSpacing.lg),
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: AppSpacing.md),
              Text('Preparing your map…'),
            ],
          ),
        ),
      ),
    );
  }
}
