import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:theme/theme.dart';

import 'package:customer_app/features/home/data/repositories/location_repository_impl.dart';

class PickupSelectionScreen extends ConsumerStatefulWidget {
  const PickupSelectionScreen({super.key, required this.initialLocation});

  final Location initialLocation;

  @override
  ConsumerState<PickupSelectionScreen> createState() =>
      _PickupSelectionScreenState();
}

class _PickupSelectionScreenState extends ConsumerState<PickupSelectionScreen> {
  final _landmarkController = TextEditingController();
  late LatLng _coordinate;
  late String _address;
  bool _resolvingAddress = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _coordinate = LatLng(
      widget.initialLocation.lat,
      widget.initialLocation.lng,
    );
    _address = widget.initialLocation.address;
  }

  @override
  void dispose() {
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _resolveAddress() async {
    final requestId = ++_requestId;
    setState(() => _resolvingAddress = true);
    try {
      final address = await ref
          .read(locationRepositoryProvider)
          .getAddressFromCoordinates(
            _coordinate.latitude,
            _coordinate.longitude,
          );
      if (mounted && requestId == _requestId) {
        setState(() => _address = address);
      }
    } catch (_) {
      // Retain the last readable address. Coordinates remain authoritative.
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _resolvingAddress = false);
      }
    }
  }

  void _confirm() {
    final landmark = _landmarkController.text.trim();
    Navigator.of(context).pop(
      LocationSnapshot(
        address: _address,
        coordinate: GeoCoordinate(
          latitude: _coordinate.latitude,
          longitude: _coordinate.longitude,
        ),
        landmark: landmark.isEmpty ? null : landmark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _coordinate,
                zoom: 17,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              onCameraMove: (position) => _coordinate = position.target,
              onCameraIdle: _resolveAddress,
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(
                Icons.location_pin,
                color: AppColors.primary,
                size: 48,
                semanticLabel: 'Selected pickup point',
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Confirm pickup', style: AppTypography.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _resolvingAddress
                                ? 'Finding this address…'
                                : _address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _landmarkController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Nearby landmark (optional)',
                        hintText: 'For example, opposite Acacia Mall',
                        prefixIcon: Icon(Icons.signpost_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: _resolvingAddress ? null : _confirm,
                      child: const Text('Use this pickup location'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
