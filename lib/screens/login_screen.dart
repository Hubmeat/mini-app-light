import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluwx/fluwx.dart';

import '../screens/home_screen.dart';
import '../services/api_client.dart';
import '../services/auth_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/glass.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _isRegisterMode = false;
  StreamSubscription? _wechatSub;

  String get _phone => _phoneCtrl.text.trim();

  static const _wechatAppId = 'wx5427f2e1c88dbb50';

  @override
  void initState() {
    super.initState();
    _initWechat();
  }

  Future<void> _initWechat() async {
    await registerWxApi(appId: _wechatAppId, universalLink: 'https://guangyu.app/wechat/');
    _wechatSub = weChatResponseEventHandler.listen((resp) {
      if (resp is WeChatAuthResponse) {
        _handleWechatCode(resp.code);
      }
    });
  }

  @override
  void dispose() {
    _wechatSub?.cancel();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final Map<String, dynamic> data;
      if (_isRegisterMode) {
        data = await ApiClient.instance
            .registerWithPassword(_phone, _passwordCtrl.text);
      } else {
        data = await ApiClient.instance
            .loginWithPassword(_phone, _passwordCtrl.text);
      }
      final token = data['token'] as String?;
      if (token != null && mounted) {
        await AuthStorage.instance.saveToken(token);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const _HomeRedirect()),
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } catch (e) {
      if (mounted) _showSnack('发生错误，请稍后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startWechatLogin() async {
    final installed = await isWeChatInstalled;
    if (!installed) {
      _showSnack('请先安装微信 App', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await sendWeChatAuth(
        scope: 'snsapi_userinfo',
        state: 'guangyu_login',
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack('微信登录失败，请重试');
      }
    }
  }

  Future<void> _handleWechatCode(String? code) async {
    if (code == null || code.isEmpty) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack('微信授权取消');
      }
      return;
    }
    try {
      final data = await ApiClient.instance.wechatLogin(code);
      final token = data['token'] as String?;
      if (token != null && mounted) {
        await AuthStorage.instance.saveToken(token);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const _HomeRedirect()),
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message);
    } catch (e) {
      if (mounted) _showSnack('微信登录失败，请重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.withValues(alpha: 0.9)
            : AppTheme.mint.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      intensity: 1.2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                _buildLogo(),
                const SizedBox(height: 48),
                _buildFormCard(),
                const SizedBox(height: 24),
                _buildWechatButton(),
                const SizedBox(height: 32),
                _buildToggleMode(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppTheme.brandGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.violet.withValues(alpha: 0.5),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.brandGradient.createShader(bounds),
          child: const Text(
            '光屿',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '补光 · 修图 · 一键发小红书',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Glass(
      strong: true,
      radius: AppTheme.radiusXl,
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isRegisterMode ? '创建账号' : '欢迎回来',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _PhoneTextField(controller: _phoneCtrl),
            const SizedBox(height: 14),
            _GlassTextField(
              controller: _passwordCtrl,
              hintText: '密码',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textFaint,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return '请输入密码';
                if (v.length < 6) return '密码至少 6 位';
                return null;
              },
            ),
            if (!_isRegisterMode) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _showSnack('请联系管理员重置密码', isError: false),
                  child: Text(
                    '忘记密码？',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.violet.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.violet),
                  )
                : GradientButton(
                    label: _isRegisterMode ? '注册' : '登录',
                    onTap: _submit,
                    expand: true,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildWechatButton() {
    return GestureDetector(
      onTap: _loading ? null : _startWechatLogin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF07C160).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: const Color(0xFF07C160).withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF07C160),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wechat, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  '微信一键登录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF07C160),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isRegisterMode ? '已有账号？' : '还没有账号？',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        GestureDetector(
          onTap: () => setState(() => _isRegisterMode = !_isRegisterMode),
          child: Text(
            _isRegisterMode ? '立即登录' : '立即注册',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.violet,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhoneTextField extends StatelessWidget {
  const _PhoneTextField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 11,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return '请输入手机号';
        if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(v.trim())) return '请输入有效的手机号';
        return null;
      },
      decoration: InputDecoration(
        hintText: '手机号',
        hintStyle: TextStyle(color: AppTheme.textFaint, fontSize: 15),
        counterText: '',
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_outlined, color: AppTheme.textFaint, size: 20),
              const SizedBox(width: 8),
              Text('+86', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(width: 4),
              Container(width: 1, height: 16, color: AppTheme.glassStroke),
            ],
          ),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.violet, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.7)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.9), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppTheme.textFaint, fontSize: 15),
        prefixIcon: Icon(icon, color: AppTheme.textFaint, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(
            color: AppTheme.violet,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(
            color: Colors.red.withValues(alpha: 0.7),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(
            color: Colors.red.withValues(alpha: 0.9),
            width: 1.5,
          ),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }
}

/// 登录成功后替换路由到 HomeScreen，清除返回栈。
class _HomeRedirect extends StatelessWidget {
  const _HomeRedirect();
  @override
  Widget build(BuildContext context) => const HomeScreen();
}
