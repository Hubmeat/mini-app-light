import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A slow, living aurora: several soft radial glows drifting over the twilight
/// base. Used as the backdrop of every screen so motion is felt even when the
/// UI is still.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
  });

  final Widget child;

  /// 0 = calm, 1 = vivid. Lets individual screens dial the glow up or down.
  final double intensity;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.inkSoft, AppTheme.ink],
            ),
          ),
          child: CustomPaint(
            painter: _AuroraPainter(_c.value, widget.intensity),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _Blob {
  const _Blob(this.color, this.baseX, this.baseY, this.radius, this.phase);
  final Color color;
  final double baseX;
  final double baseY;
  final double radius;
  final double phase;
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t, this.intensity);
  final double t;
  final double intensity;

  static const _blobs = [
    _Blob(AppTheme.violet, 0.18, 0.12, 0.62, 0.0),
    _Blob(AppTheme.cyan, 0.85, 0.20, 0.50, 0.35),
    _Blob(AppTheme.blush, 0.78, 0.82, 0.55, 0.6),
    _Blob(AppTheme.iris, 0.12, 0.78, 0.58, 0.85),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final maxDim = size.longestSide;
    for (final b in _blobs) {
      final angle = (t + b.phase) * 2 * math.pi;
      final dx = math.cos(angle) * 0.06;
      final dy = math.sin(angle * 1.3) * 0.05;
      final center = Offset(
        (b.baseX + dx) * size.width,
        (b.baseY + dy) * size.height,
      );
      final r = b.radius * maxDim;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            b.color.withValues(alpha: 0.42 * intensity),
            b.color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r))
        ..blendMode = BlendMode.plus;
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.t != t || old.intensity != intensity;
}
