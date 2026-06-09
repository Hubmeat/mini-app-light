import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../data/sticker_catalog.dart';
import '../models/photo_source.dart';
import '../models/sticker.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/sticker_glyph.dart';
import '../widgets/sticker_picker_sheet.dart';
import '../widgets/page_transitions.dart';
import 'export_sheet.dart';

/// A soft fill-light tint, echoing the "补光灯" idea inside the editor.
class LightTint {
  const LightTint(this.name, this.color);
  final String name;
  final Color color;
}

const _tints = <LightTint>[
  LightTint('原图', Colors.transparent),
  LightTint('蜜桃', Color(0xFFFFB4A2)),
  LightTint('极光', AppTheme.cyan),
  LightTint('梦紫', AppTheme.violet),
  LightTint('暖阳', AppTheme.amberGlow),
  LightTint('薄荷', AppTheme.mint),
];

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.photo});

  final PhotoSource photo;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<PlacedSticker> _stickers = [];
  int _selected = -1;
  int _tint = 0;
  double _tintStrength = 0.28;
  int _placeCounter = 0;

  @override
  void initState() {
    super.initState();
    // Seed with the template's preset stickers, fanned out near the top.
    final presets = widget.photo.presetStickerIds;
    for (var i = 0; i < presets.length; i++) {
      final asset = StickerCatalog.byId(presets[i]);
      _stickers.add(
        PlacedSticker(
          id: 'preset_${_placeCounter++}',
          icon: asset.icon,
          color: asset.color,
          position: Offset(70.0 + i * 60, 90.0 + (i.isEven ? 0 : 30)),
          scale: 0.8,
          rotation: (i - 1) * 0.2,
        ),
      );
    }
  }

  void _addSticker(StickerAsset asset) {
    // Free the flight tag from any older placement so Hero tags stay unique.
    final tag = stickerFlightTag(asset.id);
    for (final s in _stickers) {
      if (s.heroTag == tag) s.heroTag = null;
    }
    final placed = PlacedSticker(
      id: 'p_${_placeCounter++}',
      icon: asset.icon,
      color: asset.color,
      position: _canvasCenter(),
      scale: 1.0,
      heroTag: tag,
    );
    setState(() {
      _stickers.add(placed);
      _selected = _stickers.length - 1;
    });
    // After the Hero flight settles, release the tag so it can be reused.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => placed.heroTag = null);
    });
  }

  Offset _canvasCenter() {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return const Offset(160, 220);
    return box.size.center(Offset.zero);
  }

  void _openStickerPicker() {
    setState(() => _selected = -1);
    Navigator.of(
      context,
    ).push(FadeScaleRoute(page: StickerPickerSheet(onPick: _addSticker)));
  }

  void _deleteSelected() {
    if (_selected < 0) return;
    setState(() {
      _stickers.removeAt(_selected);
      _selected = -1;
    });
  }

  Future<void> _export() async {
    setState(() => _selected = -1);
    // Let the deselect repaint land before capturing.
    await Future.delayed(const Duration(milliseconds: 60));
    try {
      final boundary =
          _canvasKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = bytes!.buffer.asUint8List();
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(FadeScaleRoute(page: ExportSheet(imageBytes: pngBytes)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Stack(
        children: [
          _buildImmersiveBackground(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(onBack: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: _buildCanvas(),
                    ),
                  ),
                ),
                _LightRow(
                  tints: _tints,
                  selected: _tint,
                  strength: _tintStrength,
                  onSelect: (i) => setState(() => _tint = i),
                  onStrength: (v) => setState(() => _tintStrength = v),
                ),
                const SizedBox(height: 10),
                _Toolbar(
                  onSticker: _openStickerPicker,
                  onDelete: _selected >= 0 ? _deleteSelected : null,
                  onExport: _export,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The selected photo, blown up to fill the whole screen and heavily frosted,
  /// so the sharp framed canvas floats over a blurred echo of itself. Falls
  /// back to the template gradient when there's no imported photo.
  Widget _buildImmersiveBackground() {
    final photo = widget.photo;
    final Widget fill = photo.isTemplate
        ? DecoratedBox(decoration: photo.fallbackDecoration)
        : Image.file(photo.file!, fit: BoxFit.cover);
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          fill,
          // Frost the fill behind everything painted so far.
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: const SizedBox.expand(),
          ),
          // Darkening scrim for depth + legibility of the chrome.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.ink.withValues(alpha: 0.55),
                  AppTheme.ink.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return AspectRatio(
      aspectRatio: 3 / 4,
      // Soft shadow + hairline rim sits *outside* the RepaintBoundary so it
      // frames the sharp photo on screen but isn't baked into the export.
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 40,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        child: RepaintBoundary(
          key: _canvasKey,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            child: GestureDetector(
              onTap: () => setState(() => _selected = -1),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPhoto(),
                  _buildTintOverlay(),
                  _buildCaption(),
                  for (var i = 0; i < _stickers.length; i++)
                    _PlacedStickerView(
                      key: ValueKey(_stickers[i].id),
                      sticker: _stickers[i],
                      selected: _selected == i,
                      onSelect: () => setState(() => _selected = i),
                      onChanged: () => setState(() {}),
                    ),
                  if (_selected >= 0) _buildDeleteHandle(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    final photo = widget.photo;
    final Widget inner = photo.isTemplate
        ? DecoratedBox(decoration: photo.fallbackDecoration)
        : Image.file(photo.file!, fit: BoxFit.cover);
    if (photo.heroTag != null) {
      return Hero(tag: photo.heroTag!, child: inner);
    }
    return inner;
  }

  Widget _buildTintOverlay() {
    final tint = _tints[_tint];
    if (tint.color == Colors.transparent) return const SizedBox.shrink();
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.35),
            radius: 1.1,
            colors: [
              tint.color.withValues(alpha: _tintStrength),
              tint.color.withValues(alpha: _tintStrength * 0.25),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaption() {
    final caption = widget.photo.caption;
    if (caption.isEmpty) return const SizedBox.shrink();
    return Positioned(
      left: 18,
      bottom: 18,
      child: IgnorePointer(
        child: Text(
          caption,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 10)],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteHandle() {
    final s = _stickers[_selected];
    final size = 56.0 * s.scale;
    return Positioned(
      left: s.position.dx + size / 2 - 14,
      top: s.position.dy - size / 2 - 14,
      child: GestureDetector(
        onTap: _deleteSelected,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.blush,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
              ),
            ],
          ),
          child: const Icon(Icons.close, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

// --- Placed sticker --------------------------------------------------------

class _PlacedStickerView extends StatefulWidget {
  const _PlacedStickerView({
    super.key,
    required this.sticker,
    required this.selected,
    required this.onSelect,
    required this.onChanged,
  });

  final PlacedSticker sticker;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onChanged;

  @override
  State<_PlacedStickerView> createState() => _PlacedStickerViewState();
}

class _PlacedStickerViewState extends State<_PlacedStickerView> {
  late double _startScale;
  late double _startRotation;

  @override
  Widget build(BuildContext context) {
    final s = widget.sticker;
    const base = 52.0;
    final size = base * s.scale;

    Widget glyph = StickerGlyph(icon: s.icon, color: s.color, size: base);
    if (s.heroTag != null) {
      glyph = Hero(
        tag: s.heroTag!,
        flightShuttleBuilder: (_, _, _, _, _) => Center(
          child: StickerGlyph(icon: s.icon, color: s.color, size: base),
        ),
        child: glyph,
      );
    }

    return Positioned(
      left: s.position.dx - size / 2,
      top: s.position.dy - size / 2,
      child: GestureDetector(
        onTap: widget.onSelect,
        onScaleStart: (_) {
          widget.onSelect();
          _startScale = s.scale;
          _startRotation = s.rotation;
        },
        onScaleUpdate: (d) {
          s.position += d.focalPointDelta;
          s.scale = (_startScale * d.scale).clamp(0.4, 4.0);
          s.rotation = _startRotation + d.rotation;
          widget.onChanged();
        },
        child: Transform.rotate(
          angle: s.rotation,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: widget.selected
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 1.5,
                    )
                  : null,
            ),
            child: FittedBox(child: glyph),
          ),
        ),
      ),
    );
  }
}

// --- Chrome ----------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _CircleIcon(icon: Icons.arrow_back_ios_new, onTap: onBack),
          const Spacer(),
          const Text(
            '编辑',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 100,
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Icon(icon, size: 18, color: AppTheme.textPrimary),
    );
  }
}

class _LightRow extends StatelessWidget {
  const _LightRow({
    required this.tints,
    required this.selected,
    required this.strength,
    required this.onSelect,
    required this.onStrength,
  });

  final List<LightTint> tints;
  final int selected;
  final double strength;
  final void Function(int) onSelect;
  final void Function(double) onStrength;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: tints.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final t = tints[i];
              final isSel = i == selected;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.color == Colors.transparent
                            ? Colors.white.withValues(alpha: 0.08)
                            : t.color.withValues(alpha: 0.85),
                        border: Border.all(
                          color: isSel
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.2),
                          width: isSel ? 2.5 : 1,
                        ),
                      ),
                      child: t.color == Colors.transparent
                          ? Icon(
                              Icons.block,
                              size: 16,
                              color: AppTheme.textSecondary,
                            )
                          : null,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSel
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (selected != 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      activeTrackColor: AppTheme.cyan,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                      thumbColor: Colors.white,
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                    ),
                    child: Slider(
                      value: strength,
                      min: 0.05,
                      max: 0.6,
                      onChanged: onStrength,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.onSticker,
    required this.onDelete,
    required this.onExport,
  });

  final VoidCallback onSticker;
  final VoidCallback? onDelete;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Glass(
        radius: 100,
        strong: true,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ToolItem(icon: Icons.auto_awesome, label: '贴纸', onTap: onSticker),
            _ToolItem(
              icon: Icons.delete_outline,
              label: '删除',
              onTap: onDelete,
              disabled: onDelete == null,
            ),
            GestureDetector(
              onTap: onExport,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.blushGradient,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.ios_share, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      '导出',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  const _ToolItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled ? AppTheme.textFaint : AppTheme.textPrimary;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
