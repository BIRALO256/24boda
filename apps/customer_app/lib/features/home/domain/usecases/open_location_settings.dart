import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/home/data/repositories/location_repository_impl.dart';
import 'package:customer_app/features/home/domain/repositories/location_repository.dart';

final class OpenLocationSettings {
  const OpenLocationSettings(this._repository);

  final LocationRepository _repository;

  Future<bool> openApp() => _repository.openAppSettings();

  Future<bool> openServices() => _repository.openLocationSettings();
}

final openLocationSettingsProvider = Provider<OpenLocationSettings>((ref) {
  return OpenLocationSettings(ref.watch(locationRepositoryProvider));
});
