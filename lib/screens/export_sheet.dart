import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';
import '../widgets/glass.dart';

/// Bottom sheet that previews the finished image and pushes it out — the
/// headline action being a one-tap hand-off to 小红书 (RED) via the system
/// share sheet, where the user picks RED to start a post.
class ExportSheet extends StatefulWidget {
  const ExportSheet({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  static const _caption =
      '今日份氛围感 ✨ 用「光屿」补光修图，质感拉满 #氛围感 #补光神器 #ootd';
  bool _busy = false;

  Future<File> _writeTemp() async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/guangyu_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(widget.imageBytes);
    return file;
  }

  Future<void> _shareToRed() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _writeTemp();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: _caption,
          subject: '光屿 · 氛围感大片',
        ),
      );
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      _toast('分享失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyCaption() async {
    await Clipboard.setData(const ClipboardData(text: _caption));
    _toast('文案已复制，去小红书粘贴吧 ✍️');
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Glass(
          radius: AppTheme.radiusXl,
          strong: true,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Image.memory(
                  widget.imageBytes,
                  height: 230,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _shareToRed,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF2E51), Color(0xFFFF6B9D)],
                    ),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2E51).withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_busy)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.favorite,
                            color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        '一键导入小红书',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SecondaryAction(
                      icon: Icons.text_snippet_outlined,
                      label: '复制文案',
                      onTap: _copyCaption,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SecondaryAction(
                      icon: Icons.ios_share,
                      label: '更多分享',
                      onTap: _shareToRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 100,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppTheme.textPrimary),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}
