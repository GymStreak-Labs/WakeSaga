import 'dart:math' as math;

import 'package:flutter/material.dart';

/// INK-AND-SIGNAL design tokens.
/// Source: docs/plans/cold-open-direction/final-spec.json (design_language).
///
/// Rules enforced across the app:
/// - ONE crimson accent element per screen, ever.
/// - Gold ONLY for rarity, share, and milestones.
/// - 4px radii + 2px ink borders on manga panels; 20pt corners on chrome.
/// - Hard cuts, never crossfades, for hero transitions.
abstract final class InkSignal {
  // Color tokens.
  static const Color base = Color(0xFF0B0E14); // OLED-true ink navy.
  static const Color surface = Color(0xFF161B26);
  static const Color paper = Color(0xFFF2EFE6); // Warm paper-white text.
  static const Color crimson = Color(0xFFFF2E4C); // Single primary action.
  static const Color gold = Color(0xFFFFC93C); // Rarity / share / milestones.
  static const Color knockdownInk = Color(0xFFB3122E); // Canon failures.
  static const Color verifyGreen = Color(0xFF3DDC84); // Quest verification.
  static const Color inkBorder = Color(0xFF2A3344);

  // Shape tokens.
  static const double panelRadius = 4;
  static const double chromeRadius = 20;
  static const double slabHeight = 64; // >= 56pt on pre-9am screens.

  /// Height reserved at the bottom of tab bodies so content never sits
  /// under the floating tab bar (66 bar + 12 gap + breathing room).
  static const double tabBarClearance = 92;

  /// Heavy condensed display type for episode numbers and title cards only.
  static TextStyle display(double size, {Color color = paper}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w900,
    letterSpacing: size * -0.03,
    height: 0.95,
    color: color,
  );

  /// System UI type. 17pt minimum for body copy.
  static TextStyle ui(
    double size, {
    Color color = paper,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
  }) => TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );

  /// Mono receipt type for card footers.
  static TextStyle mono(double size, {Color color = paper}) => TextStyle(
    fontSize: size,
    color: color,
    fontFamily: 'Menlo',
    fontFamilyFallback: const ['Courier New', 'monospace'],
    letterSpacing: 0.5,
  );

  /// Manga panel: 4px radius + 2px ink border, never blurred.
  static BoxDecoration panel({
    Color color = surface,
    Color borderColor = inkBorder,
  }) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(panelRadius),
    border: Border.all(color: borderColor, width: 2),
  );

  /// Chrome sheet shape: 20pt continuous corners.
  static const ShapeBorder sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(chromeRadius)),
  );

  static ThemeData theme() {
    final scheme = const ColorScheme.dark(
      primary: crimson,
      secondary: gold,
      surface: surface,
      onSurface: paper,
      error: knockdownInk,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: base,
      canvasColor: base,
      splashFactory: NoSplash.splashFactory,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: sheetShape,
        showDragHandle: false,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 17, color: paper),
        bodyLarge: TextStyle(fontSize: 19, color: paper),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: paper,
        selectionColor: Color(0x33F2EFE6),
        selectionHandleColor: paper,
      ),
    );
  }
}

/// Display text with the spec's slight -6 degree skew. ALL-CAPS enforced.
class SkewedDisplay extends StatelessWidget {
  const SkewedDisplay(
    this.text, {
    super.key,
    this.size = 48,
    this.color = InkSignal.paper,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final double size;
  final Color color;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.skewX(-6 * math.pi / 180),
      alignment: Alignment.center,
      child: Text(
        text.toUpperCase(),
        textAlign: textAlign,
        style: InkSignal.display(size, color: color),
      ),
    );
  }
}

/// Classic anime subtitle: white with a 2px black stroke, lower third.
class StrokedSubtitle extends StatelessWidget {
  const StrokedSubtitle(
    this.text, {
    super.key,
    this.size = 18,
    this.opacity = 1,
  });

  final String text;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.25,
    );
    return Opacity(
      opacity: opacity,
      child: Stack(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Colors.black,
            ),
          ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: style.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Full-width slab button, 56pt+ tall. The caller controls the color so the
/// one-crimson-per-screen rule stays auditable at the call site.
class SlabButton extends StatelessWidget {
  const SlabButton(
    this.label, {
    super.key,
    required this.onTap,
    this.color = InkSignal.crimson,
    this.textColor = Colors.white,
    this.height = InkSignal.slabHeight,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(InkSignal.panelRadius),
          ),
          child: Text(
            label.toUpperCase(),
            style: InkSignal.ui(
              19,
              color: textColor,
              weight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
