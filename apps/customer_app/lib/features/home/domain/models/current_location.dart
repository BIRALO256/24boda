import 'package:core_models/core_models.dart';

final class CurrentLocation {
  const CurrentLocation({
    required this.location,
    required this.accuracyMeters,
    this.acquiredAt,
    this.isMocked = false,
    this.isStable = true,
  });

  final Location location;
  final double accuracyMeters;
  final DateTime? acquiredAt;
  final bool isMocked;
  final bool isStable;
}
