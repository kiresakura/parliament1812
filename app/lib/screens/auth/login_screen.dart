import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../providers/auth_provider.dart';
import '../../ui/theme/game_colors.dart' as gc;
import '../../ui/theme/game_fonts.dart';

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
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId:
            '1071586546991-0v65rkt7ud4jsp77jk121ta9prjvl6ti.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) return; // User cancelled

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google 登入失敗：無法取得 Token')),
          );
        }
        return;
      }

      final notifier = ref.read(authProvider.notifier);
      final success = await notifier.loginWithGoogleToken(idToken);
      if (success && mounted) {
        context.go('/menu');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(ref.read(authProvider).error ?? 'Google 登入失敗')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google 登入錯誤: $e')),
        );
      }
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _handleAppleLogin() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Apple 登入失敗：無法取得 Token')),
          );
        }
        return;
      }

      final displayName = [
        credential.givenName,
        credential.familyName,
      ].where((n) => n != null).join(' ');

      final notifier = ref.read(authProvider.notifier);
      final success = await notifier.loginWithAppleToken(
        identityToken,
        displayName: displayName.isNotEmpty ? displayName : null,
      );

      if (success && mounted) {
        context.go('/menu');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(ref.read(authProvider).error ?? 'Apple 登入失敗')),
        );
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled or authorization failed
      if (e.code != AuthorizationErrorCode.canceled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple 授權失敗: ${e.message}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple 登入錯誤: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
        decoration: const BoxDecoration(
          gradient: gc.GameColors.bgGradient,
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
                    // 標題 — 維多利亞金 + 陰影
                    Text(
                      '1812',
                      style: GameFont.gameTitle.copyWith(
                        color: gc.GameColors.victorianGold,
                        fontSize: 56,
                        shadows: [
                          Shadow(
                            color: gc.GameColors.goldDim,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '國會風雲',
                      style: GameFont.sectionTitle.copyWith(
                        color: gc.GameColors.victorianGold,
                        fontSize: 28,
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
                            color: gc.GameColors.victorianGold.withValues(alpha: 0.8),
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

                    // 登入按鈕 — 金色漸層
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: gc.GameColors.goldButtonGradient,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: gc.GameColors.goldLight.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gc.GameColors.victorianGold.withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: authState.isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: gc.GameColors.bgPrimary,
                                  ),
                                )
                              : Text(
                                  '登入',
                                  style: GameFont.primaryButton.copyWith(
                                    color: gc.GameColors.bgPrimary,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 分隔線
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: gc.GameColors.victorianGold
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '或',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: gc.GameColors.textMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: gc.GameColors.victorianGold
                                .withValues(alpha: 0.2),
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
                            color: gc.GameColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: Text(
                            '立即註冊',
                            style: TextStyle(
                              color: gc.GameColors.victorianGold,
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
                          color: gc.GameColors.textMuted,
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
