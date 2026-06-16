import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/sticker_catalog.dart';
import '../data/templates.dart';
import '../models/photo_source.dart';
import '../theme/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/glass.dart';
import '../widgets/sticker_glyph.dart';
import 'api_test_screen.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();

  Future<void> _importFromAlbum() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (picked == null || !mounted) return;
    _openEditor(
      PhotoSource.file(File(picked.path), heroTag: 'photo_${picked.path}'),
    );
  }

  void _openTemplate(PhotoTemplate t) {
    _openEditor(PhotoSource.template(t, heroTag: 'tpl_${t.id}'));
  }

  void _openEditor(PhotoSource source) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditorScreen(photo: source)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _importCard()),
              SliverToBoxAdapter(child: _sectionTitle('灵感模板', '一张照片，秒变大片')),
              SliverToBoxAdapter(child: _templateRail()),
              SliverToBoxAdapter(child: _sectionTitle('补光色卡', '点开任意模板，调节光效')),
              SliverToBoxAdapter(child: _colorGrid()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.violet.withValues(alpha: 0.5),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('光屿',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: 1,
                  )),
              Text('补光 · 修图 · 一键发布',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  )),
            ],
          ),
          const Spacer(),
          Glass(
            radius: 100,
            padding: const EdgeInsets.all(11),
            onTap: () {},
            child: Icon(Icons.tune, size: 20, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 10),
          Glass(
            radius: 100,
            padding: const EdgeInsets.all(11),
            onTap: () async {
              // TODO: replace with ApiClient logout
            },
            child: Icon(Icons.logout,
                size: 20, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _importCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Glass(
        radius: AppTheme.radiusXl,
        strong: true,
        onTap: _importFromAlbum,
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppTheme.blushGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.blush.withValues(alpha: 0.45),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: const Icon(Icons.add_photo_alternate_outlined,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('从相册导入',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      )),
                  const SizedBox(height: 4),
                  Text('挑一张照片，加贴纸、调补光，一键发小红书',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppTheme.textSecondary,
                      )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: AppTheme.textFaint),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              )),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                )),
          ),
        ],
      ),
    );
  }

  Widget _templateRail() {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: kTemplates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final t = kTemplates[i];
          return GestureDetector(
            onTap: () => _openTemplate(t),
            child: SizedBox(
              width: 168,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'tpl_${t.id}',
                      child: Container(
                        width: 168,
                        decoration: BoxDecoration(
                          gradient: t.linear,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: t.gradient.first.withValues(alpha: 0.4),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 14,
                              top: 14,
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  for (final id in t.presetStickerIds)
                                    Builder(builder: (_) {
                                      final a = StickerCatalog.byId(id);
                                      return StickerGlyph(
                                        icon: a.icon,
                                        color: a.color,
                                        size: 22,
                                      );
                                    }),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 14,
                              right: 14,
                              bottom: 14,
                              child: Text(
                                t.caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white
                                      .withValues(alpha: 0.95),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  shadows: const [
                                    Shadow(
                                        color: Colors.black26,
                                        blurRadius: 8),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(t.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _colorGrid() {
    final swatches = <List<Color>>[
      [AppTheme.violet, AppTheme.iris],
      [AppTheme.cyan, AppTheme.mint],
      [AppTheme.blush, AppTheme.violet],
      [AppTheme.amberGlow, AppTheme.blush],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (var i = 0; i < swatches.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => _openTemplate(kTemplates[i]),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: swatches[i],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: swatches[i].first.withValues(alpha: 0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (i != swatches.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}
