import 'package:flutter/material.dart';

/// Aurora Glass design system.
///
/// A deep twilight base lit by drifting aurora glows, with frosted glass
/// surfaces layered on top. The whole app pulls its colors, gradients and
/// text styles from here so the look stays coherent.
class AppTheme {
  AppTheme._();

  // --- Twilight base ---------------------------------------------------------
  static const Color ink = Color(0xFF0C0A1A); // near-black indigo
  static const Color inkSoft = Color(0xFF161033);
  static const Color inkRaised = Color(0xFF1F1740);

  // --- Aurora accents --------------------------------------------------------
  static const Color violet = Color(0xFF9B7CFF);
  static const Color iris = Color(0xFF6C5CE7);
  static const Color mint = Color(0xFF5EEAD4);
  static const Color cyan = Color(0xFF67E8F9);
  static const Color blush = Color(0xFFF472B6);
  static const Color amberGlow = Color(0xFFFFC371);

  // --- Glass -----------------------------------------------------------------
  static Color glassFill = Colors.white.withValues(alpha: 0.07);
  static Color glassFillStrong = Colors.white.withValues(alpha: 0.12);
  static Color glassStroke = Colors.white.withValues(alpha: 0.16);
  static Color glassStrokeStrong = Colors.white.withValues(alpha: 0.28);

  // --- Text ------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF4F1FF);
  static Color textSecondary = const Color(0xFFF4F1FF).withValues(alpha: 0.66);
  static Color textFaint = const Color(0xFFF4F1FF).withValues(alpha: 0.40);

  // --- Signature gradients ---------------------------------------------------
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, cyan],
  );

  static const LinearGradient blushGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blush, violet],
  );

  static const RadialGradient haloGradient = RadialGradient(
    colors: [violet, Colors.transparent],
  );

  static const double radiusXl = 30;
  static const double radiusLg = 24;
  static const double radiusMd = 18;

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(
        primary: violet,
        secondary: mint,
        surface: inkSoft,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
        fontFamily: 'SF Pro Text',
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
