import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:utils/utils.dart';

import 'package:rider_app/features/auth/presentation/providers/auth_notifier.dart';

/// Manages the rider's online/offline status and location updates.
///
/// When online:
/// 1. Sets riders/{uid}.isOnline = true in Firestore
/// 2. Starts a GPS location update loop every 5 seconds
/// 3. Writes current lat/lng to riders/{uid}.currentLocation
///
/// When offline:
/// 1. Sets riders/{uid}.isOnline = false in Firestore
/// 2. Stops the location update loop
/// 3. Clears riders/{uid}.currentLocation
///
/// Why 5 seconds?
/// Uber uses 4-5 seconds. Bolt uses 5 seconds.
/// Faster = more battery drain and more Firestore writes.
/// Slower = rider pin on customer map feels laggy.
/// 5 seconds is the industry standard balance.
///
/// Why update location ONLY when online?
/// A rider who is offline cannot receive jobs — nobody is watching
/// their location. Updating it when offline wastes battery and
/// Firestore quota for zero user benefit.
class OnlineStatusNotifier extends AutoDisposeNotifier<bool> {
  Timer? _locationTimer;

  @override
  bool build() {
    ref.onDispose(() {
      _locationTimer?.cancel();
    });
    return false; // starts offline
  }

  Future<void> goOnline() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _updateOnlineStatus(user.id, isOnline: true);
    state = true;

    // Start location update loop
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateLocation(user.id),
    );

    // Immediate first update
    await _updateLocation(user.id);
  }

  Future<void> goOffline() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _locationTimer?.cancel();
    _locationTimer = null;

    await _updateOnlineStatus(user.id, isOnline: false);
    await _clearLocation(user.id);
    state = false;
  }

  Future<void> toggle() async {
    if (state) {
      await goOffline();
    } else {
      await goOnline();
    }
  }

  // ── Firestore helpers ────────────────────────────────────────────────────

  Future<void> _updateOnlineStatus(String uid, {required bool isOnline}) async {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.riders)
        .doc(uid)
        .update({
      RiderFields.isOnline: isOnline,
      RiderFields.updatedAt: DateTime.now().toIso8601String(),
    });
  }

  Future<void> _updateLocation(String uid) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await FirebaseFirestore.instance
          .collection(FirestoreCollections.riders)
          .doc(uid)
          .update({
        RiderFields.currentLocation: {
          'lat': position.latitude,
          'lng': position.longitude,
          'address': '',
        },
        RiderFields.lastSeen: DateTime.now().toIso8601String(),
        RiderFields.updatedAt: DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Location failed — continue silently, will retry on next tick
    }
  }

  Future<void> _clearLocation(String uid) async {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.riders)
        .doc(uid)
        .update({
      RiderFields.currentLocation: FieldValue.delete(),
      RiderFields.isOnline: false,
      RiderFields.updatedAt: DateTime.now().toIso8601String(),
    });
  }
}

final onlineStatusProvider =
    AutoDisposeNotifierProvider<OnlineStatusNotifier, bool>(
  () => OnlineStatusNotifier(),
);
