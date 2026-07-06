import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/glass.dart';

class _Line {
  _Line(this.text, this.kind);
  final String text;
  final String kind; // 'in' | 'ok' | 'err'
}

/// 开发期「接口自检」页：验证 Flutter ↔ node-server 打通。
class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final _api = ApiClient.instance;
  final _logs = <_Line>[];
  final _scroll = ScrollController();
  late final TextEditingController _urlCtrl =
      TextEditingController(text: _api.baseUrl);
  bool _busy = false;
  final String _phone = '13800000000';

  @override
  void initState() {
    super.initState();
    // 进入即自动跑一次自检，方便快速确认前后端打通
    WidgetsBinding.instance.addPostFrameCallback((_) => _selfCheck());
  }

  void _log(String text, [String kind = 'in']) {
    setState(() => _logs.add(_Line(text, kind)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  /// 包一层：打印「调用 → 结果/错误」。
  Future<T?> _call<T>(String label, Future<T> Function() fn) async {
    _log('▶ $label', 'in');
    try {
      final r = await fn();
      _log('✓ $label  →  $r', 'ok');
      return r;
    } on ApiException catch (e) {
      _log('✗ $label  →  $e', 'err');
      return null;
    } catch (e) {
      _log('✗ $label  →  $e', 'err');
      return null;
    }
  }

  Future<void> _guard(Future<void> Function() body) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _api.baseUrl = _urlCtrl.text.trim();
      await body();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selfCheck() => _guard(() async {
        _log('—— 开始一键自检 ——', 'in');
        await _call('GET /health', () => _api.health());
        final send = await _call(
            'POST /auth/phone/code', () => _api.sendPhoneCode(_phone));
        final code = send?['devCode']?.toString();
        if (code == null) {
          _log('没拿到 devCode（server 非 mock 模式？）', 'err');
          return;
        }
        await _call('POST /auth/phone/login',
            () => _api.phoneLogin(_phone, code));
        await _call('GET /usage/me', () => _api.usage());
        await _call('POST /usage/consume', () => _api.consume());
        await _call('GET /billing/plans', () => _api.plans());
        _log('—— 自检结束 ——', 'in');
      });

  Future<void> _login() => _guard(() async {
        final send = await _call(
            'POST /auth/phone/code', () => _api.sendPhoneCode(_phone));
        final code = send?['devCode']?.toString();
        if (code != null) {
          await _call('POST /auth/phone/login',
              () => _api.phoneLogin(_phone, code));
        }
      });

  Future<void> _recharge() => _guard(() async {
        final order =
            await _call('POST /billing/orders', () => _api.createOrder('basic'));
        final id = order?['order']?['id']?.toString();
        if (id != null) {
          await _call('POST mock-pay', () => _api.mockPay(id));
          await _call('GET /usage/me', () => _api.usage());
        }
      });

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      intensity: 0.7,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Glass(
                      radius: 100,
                      padding: const EdgeInsets.all(11),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 12),
                    const Text('接口自检',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        )),
                    const Spacer(),
                    _StatusChip(loggedIn: _api.isLoggedIn),
                  ],
                ),
                const SizedBox(height: 14),
                Glass(
                  radius: AppTheme.radiusMd,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _urlCtrl,
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'http://localhost:3000',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Glass(
                    radius: AppTheme.radiusMd,
                    padding: const EdgeInsets.all(14),
                    child: _logs.isEmpty
                        ? Center(
                            child: Text('点下面「一键自检」开始 👇',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)),
                          )
                        : ListView.builder(
                            controller: _scroll,
                            itemCount: _logs.length,
                            itemBuilder: (_, i) {
                              final l = _logs[i];
                              final color = l.kind == 'ok'
                                  ? AppTheme.mint
                                  : l.kind == 'err'
                                      ? const Color(0xFFFF7A9A)
                                      : AppTheme.textSecondary;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: SelectableText(
                                  l.text,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12.5,
                                    height: 1.35,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                GradientButton(
                  label: _busy ? '请求中…' : '一键自检（跑通登录+用量+套餐）',
                  icon: Icons.bolt,
                  expand: true,
                  onTap: _busy ? () {} : _selfCheck,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _Pill('健康检查', () => _guard(() => _call('GET /health', () => _api.health()))),
                    _Pill('登录', _login),
                    _Pill('查用量', () => _guard(() => _call('GET /usage/me', () => _api.usage()))),
                    _Pill('消耗一次', () => _guard(() => _call('POST /usage/consume', () => _api.consume()))),
                    _Pill('充值basic', _recharge),
                    _Pill('清屏', () => setState(() => _logs.clear())),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 100,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Text(label,
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.loggedIn});
  final bool loggedIn;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (loggedIn ? AppTheme.mint : AppTheme.textFaint)
            .withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(loggedIn ? '已登录' : '未登录',
          style: TextStyle(
            fontSize: 12,
            color: loggedIn ? AppTheme.mint : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}
