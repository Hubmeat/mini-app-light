import 'package:flutter/material.dart';
import '../data/sticker_catalog.dart';
import '../models/sticker.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'sticker_glyph.dart';

/// Hero tag a catalog tile uses while flying onto the canvas.
String stickerFlightTag(String assetId) => 'flight_$assetId';

/// Bottom sheet sticker picker. Tapping a sticker calls [onPick] (so the editor
/// can add it *before* the sheet pops, letting the Hero flight play) and then
/// closes the sheet.
class StickerPickerSheet extends StatefulWidget {
  const StickerPickerSheet({super.key, required this.onPick});

  final void Function(StickerAsset asset) onPick;

  @override
  State<StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends State<StickerPickerSheet> {
  String _category = StickerCatalog.categories.first;

  @override
  Widget build(BuildContext context) {
    final items = StickerCatalog.byCategory(_category);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Glass(
          radius: AppTheme.radiusXl,
          strong: true,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('贴纸',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(width: 8),
                  Text('点一下，贴到照片上',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      )),
                ],
              ),
              const SizedBox(height: 14),
              _CategoryBar(
                selected: _category,
                onSelect: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 220,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: GridView.count(
                    key: ValueKey(_category),
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      for (final s in items)
                        _StickerTile(
                          asset: s,
                          onTap: () {
                            widget.onPick(s);
                            Navigator.of(context).pop();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelect});

  final String selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          for (final c in StickerCatalog.categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: c == selected ? AppTheme.brandGradient : null,
                    color: c == selected
                        ? null
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: c == selected
                          ? Colors.transparent
                          : AppTheme.glassStroke,
                    ),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      color: c == selected
                          ? Colors.white
                          : AppTheme.textSecondary,
                      fontWeight:
                          c == selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StickerTile extends StatelessWidget {
  const _StickerTile({required this.asset, required this.onTap});

  final StickerAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: stickerFlightTag(asset.id),
        // Keep glyph crisp & undistorted mid-flight.
        flightShuttleBuilder: (_, _, _, _, _) => Center(
          child: StickerGlyph(icon: asset.icon, color: asset.color, size: 40),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: StickerGlyph(icon: asset.icon, color: asset.color, size: 30),
        ),
      ),
    );
  }
}
