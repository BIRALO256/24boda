import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utils/utils.dart';

import 'package:rider_app/features/auth/presentation/providers/auth_notifier.dart';

/// Listens for new shipments with status == 'searching'.
///
/// When the rider is online and a new shipment appears nearby,
/// this provider emits the shipment so the home screen can
/// show the job request modal.
///
/// Why a StreamProvider and not a one-time fetch?
/// New jobs can appear at any time while the rider is online.
/// A stream keeps the listener active — when a new job appears
/// in Firestore it arrives here in under 500ms automatically.
///
/// Why filter by status == 'searching' only?
/// Once a rider accepts, the status changes to 'accepted' and
/// disappears from this query automatically. The stream only
/// emits unassigned jobs that need a rider.
final pendingJobProvider = StreamProvider.autoDispose<Shipment?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection(FirestoreCollections.shipments)
      .where(ShipmentFields.status,
          isEqualTo: ShipmentStatus.searching.value)
      .where(ShipmentFields.riderId, isNull: true)
      .orderBy(ShipmentFields.createdAt, descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return null;
    return Shipment.fromMap(snapshot.docs.first.data());
  });
});

/// Handles accepting and declining job requests.
class JobRequestNotifier extends AutoDisposeNotifier<JobRequestState> {
  @override
  JobRequestState build() => const JobRequestIdle();

  /// Rider accepts the job.
  /// Updates shipment: riderId set, status → accepted, acceptedAt recorded.
  Future<void> acceptJob(String shipmentId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const JobRequestAccepting();

    try {
      final now = DateTime.now().toIso8601String();

      await FirebaseFirestore.instance
          .collection(FirestoreCollections.shipments)
          .doc(shipmentId)
          .update({
        ShipmentFields.riderId: user.id,
        ShipmentFields.status: ShipmentStatus.accepted.value,
        ShipmentFields.acceptedAt: now,
        ShipmentFields.updatedAt: now,
      });

      state = JobRequestAccepted(shipmentId: shipmentId);
    } catch (e) {
      state = const JobRequestIdle();
    }
  }

  /// Rider declines the job — no Firestore change needed.
  /// The shipment stays in 'searching' for the next rider.
  void declineJob() {
    state = const JobRequestDeclined();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (state is! JobRequestDeclined) return;
      state = const JobRequestIdle();
    });
  }

  void reset() => state = const JobRequestIdle();
}

final jobRequestProvider =
    AutoDisposeNotifierProvider<JobRequestNotifier, JobRequestState>(
  () => JobRequestNotifier(),
);

// ── State ──────────────────────────────────────────────────────────────────

sealed class JobRequestState {
  const JobRequestState();
  bool get isDeclined => this is JobRequestDeclined;
}

final class JobRequestIdle extends JobRequestState {
  const JobRequestIdle();
}

final class JobRequestAccepting extends JobRequestState {
  const JobRequestAccepting();
}

final class JobRequestAccepted extends JobRequestState {
  const JobRequestAccepted({required this.shipmentId});
  final String shipmentId;
}

final class JobRequestDeclined extends JobRequestState {
  const JobRequestDeclined();
}
