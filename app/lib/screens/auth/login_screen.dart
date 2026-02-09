import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authProvider.notifier);
    final success = await notifier.loginWithEmailPassword(
      emailOrUsername: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      context.go('/menu');
    }
  }

  Future<void> _handleGoogleLogin() async {
    // Google Sign-In 整合（需要 google_sign_in package）
    // 暫時用 mock token
    final notifier = ref.read(authProvider.notifier);
    final success =
        await notifier.loginWithGoogleToken('mock_google_testuser');
    if (success && mounted) {
      context.go('/menu');
    }
  }

  Future<void> _handleAppleLogin() async {
    // Apple Sign-In 整合（需要 sign_in_with_apple package）
    // 暫時用 mock token
    final notifier = ref.read(authProvider.notifier);
    final success =
        await notifier.loginWithAppleToken('mock_apple_testuser');
    if (success && mounted) {
      context.go('/menu');
    }
  }

  void _handleGuestMode() {
    // Guest 模式：直接進入主選單
    context.go('/menu');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 標題
                    Text(
                      '1812',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: Parliament1812Theme.darkRed,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      '國會風雲',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: Parliament1812Theme.gold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email / Username
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email 或使用者名稱',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '請輸入 Email 或使用者名稱';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 密碼
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '密碼',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '請輸入密碼';
                        }
                        return null;
                      },
                    ),

                    // 忘記密碼
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go('/forgot-password'),
                        child: Text(
                          '忘記密碼？',
                          style: TextStyle(
                            color: Parliament1812Theme.gold.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),

                    // 錯誤訊息
                    if (authState.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          authState.error!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // 登入按鈕
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleLogin,
                        child: authState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Parliament1812Theme.cream,
                                ),
                              )
                            : const Text('登入'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 分隔線
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Parliament1812Theme.lightBrown
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '或',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Parliament1812Theme.cream
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Parliament1812Theme.lightBrown
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google 登入
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed:
                            authState.isLoading ? null : _handleGoogleLogin,
                        icon: const Icon(Icons.g_mobiledata, size: 24),
                        label: const Text('使用 Google 登入'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Apple 登入
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed:
                            authState.isLoading ? null : _handleAppleLogin,
                        icon: const Icon(Icons.apple, size: 24),
                        label: const Text('使用 Apple 登入'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 註冊連結
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '沒有帳號？',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Parliament1812Theme.cream
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text(
                            '立即註冊',
                            style: TextStyle(
                              color: Parliament1812Theme.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Guest 模式
                    TextButton(
                      onPressed: _handleGuestMode,
                      child: Text(
                        '以訪客身份進入',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Parliament1812Theme.cream
                              .withValues(alpha: 0.5),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
