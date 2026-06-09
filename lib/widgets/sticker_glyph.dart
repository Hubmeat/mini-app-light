import 'package:flutter/material.dart';

/// A designed sticker glyph: a bright vector icon with a soft neon glow in its
/// own identity color. Used everywhere a sticker is drawn so the look stays
/// consistent (picker tile, canvas, Hero flight).
class StickerGlyph extends StatelessWidget {
  const StickerGlyph({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: Colors.white,
      shadows: [
        Shadow(color: color, blurRadius: size * 0.5),
        Shadow(color: color.withValues(alpha: 0.7), blurRadius: size * 0.22),
      ],
    );
  }
}
