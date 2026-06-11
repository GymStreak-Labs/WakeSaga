import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/ink_signal.dart';

/// Halftone screentone dot grid — 8-10% intensity, imagery surfaces only.
class ScreentonePainter extends CustomPainter {
  const ScreentonePainter({this.color = const Color(0xFFF2EFE6), this.opacity = 0.10});

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: opacity);
    const spacing = 9.0;
    var row = 0;
    for (double y = 4; y < size.height; y += spacing) {
      final offset = row.isEven ? 0.0 : spacing / 2;
      for (double x = 4 + offset; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant ScreentonePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}

/// Radial speed-line burst — the only decorative flourish allowed, used
/// behind the Title Card Slam and the quest-verify flash.
class SpeedLinesPainter extends CustomPainter {
  const SpeedLinesPainter({this.color = Colors.white, this.opacity = 0.14});

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    const lineCount = 72;
    final rng = math.Random(7); // Deterministic burst.
    for (var i = 0; i < lineCount; i++) {
      final angle = (i / lineCount) * 2 * math.pi + rng.nextDouble() * 0.05;
      final innerRadius = maxRadius * (0.32 + rng.nextDouble() * 0.22);
      final width = 0.006 + rng.nextDouble() * 0.012;
      final path = Path()
        ..moveTo(
          center.dx + math.cos(angle - width) * maxRadius,
          center.dy + math.sin(angle - width) * maxRadius,
        )
        ..lineTo(
          center.dx + math.cos(angle) * innerRadius,
          center.dy + math.sin(angle) * innerRadius,
        )
        ..lineTo(
          center.dx + math.cos(angle + width) * maxRadius,
          center.dy + math.sin(angle + width) * maxRadius,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SpeedLinesPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}

/// Small wake-card thumbnail used in Today peeks, Saga timeline and binder.
class MiniCardThumb extends StatelessWidget {
  const MiniCardThumb({
    super.key,
    required this.record,
    this.width = 64,
    this.height = 84,
  });

  final DayRecord record;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasFoil = record.foil != null;
    return Container(
      width: width,
      height: height,
      decoration: InkSignal.panel(
        color: const Color(0xFF1B2230),
        borderColor: hasFoil ? InkSignal.gold : InkSignal.inkBorder,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: ScreentonePainter(opacity: 0.08)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'EP ${record.episode}',
                  style: InkSignal.display(width * 0.22),
                ),
                const SizedBox(height: 2),
                Text(
                  record.wakeTime,
                  style: InkSignal.mono(
                    width * 0.13,
                    color: InkSignal.paper.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
