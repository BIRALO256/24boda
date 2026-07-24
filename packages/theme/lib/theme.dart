/// 24Boda theme package.
///
/// Import this single file to access everything:
/// ```dart
/// import 'package:theme/theme.dart';
///
/// // Then use anywhere:
/// AppColors.primary
/// AppTypography.headlineLarge
/// AppSpacing.md
/// AppTheme.light
/// ```
library;

export 'src/app_colors.dart';
export 'src/app_spacing.dart';
export 'src/app_theme.dart';
export 'src/app_typography.dart';

// Reusable widgets — available to both customer_app and rider_app
export 'src/widgets/boda_button.dart';
export 'src/widgets/boda_otp_field.dart';
export 'src/widgets/boda_text_field.dart';
