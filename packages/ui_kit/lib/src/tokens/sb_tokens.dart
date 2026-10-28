import 'package:flutter/material.dart';

/// Design-system colours from UI_UX_GUIDELINES §3.1.
abstract final class SbColors {
  static const primary = Color(0xFF1E88E5);
  static const primaryStrong = Color(0xFF1565C0);
  static const primaryContainer = Color(0xFFE3F2FD);
  static const accent = Color(0xFF2E7D32);
  static const accentContainer = Color(0xFFE8F5E9);
  static const success = Color(0xFF067647);
  static const successContainer = Color(0xFFDCFAE6);
  static const warning = Color(0xFFB54708);
  static const warningContainer = Color(0xFFFEF0C7);
  static const error = Color(0xFFB42318);
  static const errorContainer = Color(0xFFFEE4E2);
  static const info = Color(0xFF175CD3);
  static const infoContainer = Color(0xFFD1E9FF);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF5F8FC);
  static const onSurface = Color(0xFF101828);
  static const onSurfaceVariant = Color(0xFF475467);
  static const outline = Color(0xFFD0D5DD);
  static const neutralContainer = Color(0xFFF2F4F7);
  static const metricTints = [
    primaryContainer,
    accentContainer,
    Color(0xFFFFF4E5),
    Color(0xFFF3E8FF),
  ];
}

/// Four-point spacing grid, in logical pixels.
abstract final class SbSpacing {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0;
  static const xl = 20.0, xxl = 24.0, xxxl = 32.0;
  static const screen = lg, card = lg, listGap = md, minTarget = 48.0;
}

/// Shared component radii.
abstract final class SbRadius {
  static const card = 16.0, button = 12.0, input = 12.0;
  static const chip = 20.0, sheet = 24.0;
}

/// Locale-aware bundled fonts and scalable type ramp.
abstract final class SbTypography {
  static TextTheme textTheme(Locale locale) {
    final family =
        locale.languageCode == 'hi' ? 'NotoSansDevanagari' : 'NotoSans';
    TextStyle style(double size, double line, FontWeight weight) => TextStyle(
          fontFamily: family,
          package: 'ui_kit',
          fontFamilyFallback: const [
            'packages/ui_kit/NotoSansDevanagari',
            'packages/ui_kit/NotoSans',
          ],
          fontSize: size,
          height: line / size,
          fontWeight: weight,
          color: SbColors.onSurface,
        );
    return TextTheme(
      displaySmall: style(28, 36, FontWeight.w700),
      headlineSmall: style(22, 30, FontWeight.w700),
      titleMedium: style(17, 24, FontWeight.w600),
      bodyLarge: style(16, 24, FontWeight.w400),
      bodyMedium: style(14, 20, FontWeight.w400),
      labelLarge: style(15, 20, FontWeight.w600),
      labelSmall: style(12, 16, FontWeight.w500),
    );
  }

  static TextStyle amountLarge(Locale locale) =>
      textTheme(locale).headlineSmall!.copyWith(
        fontSize: 24,
        height: 32 / 24,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
