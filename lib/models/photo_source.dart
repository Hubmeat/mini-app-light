import 'dart:io';
import 'package:flutter/material.dart';
import '../data/templates.dart';

/// What the editor canvas is decorating: either a gradient template (the
/// built-in demo "photos") or a real image the user imported from the album.
class PhotoSource {
  const PhotoSource.template(this.template, {this.heroTag}) : file = null;

  PhotoSource.file(this.file, {this.heroTag}) : template = null;

  final PhotoTemplate? template;
  final File? file;

  /// Optional Hero tag so the same photo animates from gallery → editor.
  final Object? heroTag;

  bool get isTemplate => template != null;

  /// The fill painted behind the photo (templates only).
  BoxDecoration get fallbackDecoration => BoxDecoration(
        gradient: template?.linear,
      );

  String get caption => template?.caption ?? '';
  List<String> get presetStickerIds =>
      template?.presetStickerIds ?? const [];
}
