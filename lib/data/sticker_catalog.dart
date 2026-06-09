import 'package:flutter/material.dart';
import '../models/sticker.dart';
import '../theme/app_theme.dart';

/// Curated sticker set — designed vector glyphs, each with a signature color,
/// grouped into the picker's category tabs.
class StickerCatalog {
  static const categories = ['心动', '闪耀', '可爱', '元气', '文字'];

  static const List<StickerAsset> all = [
    // 心动
    StickerAsset('heart', Icons.favorite, AppTheme.blush, '心动'),
    StickerAsset('heart_o', Icons.favorite_border, Color(0xFFFF8FC7), '心动'),
    StickerAsset('hearts', Icons.favorite_outlined, Color(0xFFFF5C8A), '心动'),
    StickerAsset('cupid', Icons.volunteer_activism, AppTheme.blush, '心动'),
    StickerAsset('loyalty', Icons.loyalty, Color(0xFFFF6FB5), '心动'),
    StickerAsset('spark_heart', Icons.favorite, AppTheme.violet, '心动'),
    // 闪耀
    StickerAsset('sparkle', Icons.auto_awesome, AppTheme.cyan, '闪耀'),
    StickerAsset('star', Icons.star_rounded, AppTheme.amberGlow, '闪耀'),
    StickerAsset('star_o', Icons.star_border_rounded, AppTheme.cyan, '闪耀'),
    StickerAsset('flare', Icons.flare, Color(0xFFFFE08A), '闪耀'),
    StickerAsset('moon', Icons.nightlight_round, AppTheme.violet, '闪耀'),
    StickerAsset('bolt', Icons.bolt, AppTheme.amberGlow, '闪耀'),
    // 可爱
    StickerAsset('cat', Icons.pets, AppTheme.violet, '可爱'),
    StickerAsset('bubble', Icons.bubble_chart, AppTheme.mint, '可爱'),
    StickerAsset('cake', Icons.cake, Color(0xFFFF9FD0), '可爱'),
    StickerAsset('icecream', Icons.icecream, AppTheme.blush, '可爱'),
    StickerAsset('toys', Icons.toys, AppTheme.cyan, '可爱'),
    StickerAsset('crown', Icons.workspace_premium, AppTheme.amberGlow, '可爱'),
    // 元气
    StickerAsset('sun', Icons.wb_sunny, AppTheme.amberGlow, '元气'),
    StickerAsset('flower', Icons.local_florist, AppTheme.blush, '元气'),
    StickerAsset('spa', Icons.spa, AppTheme.mint, '元气'),
    StickerAsset('cloud', Icons.cloud, AppTheme.cyan, '元气'),
    StickerAsset('drop', Icons.water_drop, AppTheme.cyan, '元气'),
    StickerAsset('snow', Icons.ac_unit, Color(0xFFBEEBFF), '元气'),
    // 文字
    StickerAsset('music', Icons.music_note, AppTheme.violet, '文字'),
    StickerAsset('camera', Icons.camera_alt, AppTheme.mint, '文字'),
    StickerAsset('tag', Icons.sell, AppTheme.blush, '文字'),
    StickerAsset('chat', Icons.chat_bubble, AppTheme.cyan, '文字'),
    StickerAsset('verified', Icons.verified, AppTheme.amberGlow, '文字'),
    StickerAsset('label', Icons.local_offer, AppTheme.violet, '文字'),
  ];

  static StickerAsset byId(String id) => all.firstWhere((s) => s.id == id);

  static List<StickerAsset> byCategory(String category) =>
      all.where((s) => s.category == category).toList();
}
