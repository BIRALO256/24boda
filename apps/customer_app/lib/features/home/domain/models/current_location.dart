import 'package:core_models/core_models.dart';

final class CurrentLocation {
  const CurrentLocation({required this.location, required this.accuracyMeters});

  final Location location;
  final double accuracyMeters;
}
