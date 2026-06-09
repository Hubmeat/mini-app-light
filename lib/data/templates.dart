import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A photo "frame" template. Each is a gradient backdrop + a caption + a few
/// preset stickers, so tapping one instantly dresses up a photo. These double
/// as the gradient placeholder "photos" before the user imports their own.
class PhotoTemplate {
  const PhotoTemplate({
    required this.id,
    required this.name,
    required this.gradient,
    required this.caption,
    required this.presetStickerIds,
  });

  final String id;
  final String name;
  final List<Color> gradient;
  final String caption;

  /// Ids into [StickerCatalog]; dropped onto the photo when the template opens.
  final List<String> presetStickerIds;

  LinearGradient get linear => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradient,
      );
}

const kTemplates = <PhotoTemplate>[
  PhotoTemplate(
    id: 'aurora',
    name: '极光',
    gradient: [AppTheme.iris, AppTheme.cyan],
    caption: 'tonight feels like aurora',
    presetStickerIds: ['sparkle', 'moon', 'star'],
  ),
  PhotoTemplate(
    id: 'blush',
    name: '初恋',
    gradient: [AppTheme.blush, AppTheme.violet],
    caption: '怦然心动的瞬间',
    presetStickerIds: ['heart', 'loyalty', 'flower'],
  ),
  PhotoTemplate(
    id: 'mint',
    name: '薄荷',
    gradient: [AppTheme.mint, AppTheme.iris],
    caption: 'fresh & free',
    presetStickerIds: ['spa', 'drop', 'bubble'],
  ),
  PhotoTemplate(
    id: 'sunset',
    name: '黄昏',
    gradient: [AppTheme.amberGlow, AppTheme.blush],
    caption: 'golden hour 限定',
    presetStickerIds: ['sun', 'cloud', 'flare'],
  ),
  PhotoTemplate(
    id: 'midnight',
    name: '午夜',
    gradient: [AppTheme.inkRaised, AppTheme.iris],
    caption: 'midnight mood',
    presetStickerIds: ['star', 'sparkle', 'bolt'],
  ),
];
