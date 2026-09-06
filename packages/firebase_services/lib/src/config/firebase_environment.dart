enum FirebaseEnvironment {
  development('development'),
  staging('staging'),
  production('production');

  const FirebaseEnvironment(this.value);
  final String value;

  static FirebaseEnvironment fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw StateError('Unknown Firebase environment: $value'),
  );

  static FirebaseEnvironment get current => fromValue(
    const String.fromEnvironment(
      'APP_ENVIRONMENT',
      defaultValue: 'development',
    ),
  );
}

final class FirebaseEnvironmentConfig {
  FirebaseEnvironmentConfig({
    required this.environment,
    required this.projectId,
  }) {
    if (projectId.trim().isEmpty) {
      throw ArgumentError.value(projectId, 'projectId');
    }
  }

  final FirebaseEnvironment environment;
  final String projectId;

  /// Prevents a binary built for one environment from silently connecting to
  /// a differently named Firebase project.
  void verifyProjectConvention() {
    final expectedSuffix = switch (environment) {
      FirebaseEnvironment.development => '-dev',
      FirebaseEnvironment.staging => '-staging',
      FirebaseEnvironment.production => '-prod',
    };
    if (!projectId.endsWith(expectedSuffix)) {
      throw StateError(
        'Firebase project "$projectId" does not match '
        '${environment.value}; expected a project ending in $expectedSuffix.',
      );
    }
  }
}
