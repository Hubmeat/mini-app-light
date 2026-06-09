import 'package:flutter/material.dart';

/// A sticker as it lives in the catalog (the picker). Stickers are designed
/// vector glyphs with a signature color + neon glow — not system emoji — so
/// they render identically everywhere and feel part of the brand.
class StickerAsset {
  const StickerAsset(this.id, this.icon, this.color, this.category);

  /// Stable id used as the Hero tag when the sticker flies onto the canvas.
  final String id;
  final IconData icon;

  /// Identity color; also drives the glow.
  final Color color;
  final String category;
}

/// A sticker that has been placed on the canvas, with its transform.
class PlacedSticker {
  PlacedSticker({
    required this.id,
    required this.icon,
    required this.color,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.heroTag,
  });

  /// Unique per placement (a sticker can be placed many times).
  final String id;
  final IconData icon;
  final Color color;
  Offset position; // center, in canvas-local coordinates
  double scale;
  double rotation;

  /// Hero tag held only during the fly-onto-canvas animation, then cleared so
  /// the tag is free to be reused by a future placement of the same sticker.
  Object? heroTag;
}
