import 'package:flutter/material.dart';
import '../tokens/sb_tokens.dart';

/// Additional semantic colours available through ThemeData.
@immutable
class SbTheme extends ThemeExtension<SbTheme> {
  const SbTheme({
    this.accent = SbColors.accent,
    this.success = SbColors.success,
    this.warning = SbColors.warning,
    this.info = SbColors.info,
  });
  static const light = SbTheme();
  final Color accent, success, warning, info;

  @override
  SbTheme copyWith({
    Color? accent,
    Color? success,
    Color? warning,
    Color? info,
  }) =>
      SbTheme(
        accent: accent ?? this.accent,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        info: info ?? this.info,
      );

  @override
  SbTheme lerp(SbTheme? other, double t) => other == null
      ? this
      : SbTheme(
          accent: Color.lerp(accent, other.accent, t)!,
          success: Color.lerp(success, other.success, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
          info: Color.lerp(info, other.info, t)!,
        );
}

/// Light-only v1 theme. Body text uses the accessible strong brand blue.
ThemeData sbLightTheme(Locale locale) => ThemeData(
      useMaterial3: true,
      fontFamily:
          locale.languageCode == 'hi' ? 'NotoSansDevanagari' : 'NotoSans',
      package: 'ui_kit',
      fontFamilyFallback: const [
        'packages/ui_kit/NotoSansDevanagari',
        'packages/ui_kit/NotoSans'
      ],
      colorScheme: const ColorScheme.light(
        primary: SbColors.primaryStrong,
        onPrimary: SbColors.surface,
        primaryContainer: SbColors.primaryContainer,
        secondary: SbColors.accent,
        onSecondary: SbColors.surface,
        surface: SbColors.surface,
        onSurface: SbColors.onSurface,
        onSurfaceVariant: SbColors.onSurfaceVariant,
        error: SbColors.error,
        onError: SbColors.surface,
        errorContainer: SbColors.errorContainer,
        outline: SbColors.onSurfaceVariant,
        outlineVariant: SbColors.outline,
      ),
      scaffoldBackgroundColor: SbColors.background,
      textTheme: SbTypography.textTheme(locale),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: const [SbTheme.light],
      inputDecorationTheme: InputDecorationTheme(
        helperStyle: SbTypography.textTheme(locale)
            .bodyMedium
            ?.copyWith(color: SbColors.onSurface, fontWeight: FontWeight.w600),
        errorStyle: SbTypography.textTheme(locale)
            .bodyMedium
            ?.copyWith(color: SbColors.error, fontWeight: FontWeight.w600),
        counterStyle: SbTypography.textTheme(locale)
            .bodyMedium
            ?.copyWith(color: SbColors.onSurface, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SbRadius.input),
        ),
      ),
    );
