import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../domain/models/user_account.dart';

/// 登入頁面
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // 監聽錯誤
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        _showErrorSnackBar(next.errorMessage!);
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: authState.isLoading
            ? _buildLoadingView()
            : _buildLoginView(context),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.accent,
          ),
          SizedBox(height: 16),
          Text(
            '登入中...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginView(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Logo 和標題
            _buildHeader()
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.2, end: 0),

            const SizedBox(height: 60),

            // 社群登入按鈕
            _buildSocialLoginButtons()
                .animate()
                .fadeIn(delay: 200.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 24),

            // 分隔線
            _buildDivider()
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms),

            const SizedBox(height: 24),

            // 訪客登入
            _buildGuestButton()
                .animate()
                .fadeIn(delay: 600.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 40),

            // 服務條款
            _buildTermsText()
                .animate()
                .fadeIn(delay: 800.ms, duration: 600.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 遊戲標題
        Text(
          '1812',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: AppTheme.accent,
            letterSpacing: 8,
            shadows: [
              Shadow(
                color: AppTheme.accent.withAlpha(102),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '國會風雲',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            letterSpacing: 12,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 120,
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.accent,
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '議會辯論 RPG 社交推理遊戲',
          style: GoogleFonts.notoSerif(
            fontSize: 14,
            color: AppTheme.textSecondary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        // Google 登入
        _SocialLoginButton(
          provider: AuthProvider.google,
          onPressed: () => _signIn(AuthProvider.google),
          icon: Icons.g_mobiledata_rounded,
          iconColor: Colors.white,
          backgroundColor: const Color(0xFF4285F4),
        ),

        const SizedBox(height: 16),

        // Apple 登入（僅 iOS）
        if (Platform.isIOS) ...[
          _SocialLoginButton(
            provider: AuthProvider.apple,
            onPressed: () => _signIn(AuthProvider.apple),
            icon: Icons.apple,
            iconColor: Colors.white,
            backgroundColor: Colors.black,
          ),
          const SizedBox(height: 16),
        ],

        // Discord 登入
        _SocialLoginButton(
          provider: AuthProvider.discord,
          onPressed: () => _signIn(AuthProvider.discord),
          icon: Icons.discord,
          iconColor: Colors.white,
          backgroundColor: const Color(0xFF5865F2),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.textSecondary.withAlpha(77),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '或者',
            style: GoogleFonts.notoSerif(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.textSecondary.withAlpha(77),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _signInAsGuest(),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: AppTheme.accent.withAlpha(128),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(
          Icons.person_outline,
          color: AppTheme.textSecondary,
        ),
        label: Text(
          '以訪客身份試玩',
          style: GoogleFonts.notoSerif(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.notoSerif(
          fontSize: 12,
          color: AppTheme.textSecondary.withAlpha(153),
        ),
        children: const [
          TextSpan(text: '登入即表示您同意我們的 '),
          TextSpan(
            text: '服務條款',
            style: TextStyle(
              color: AppTheme.accent,
              decoration: TextDecoration.underline,
            ),
          ),
          TextSpan(text: ' 與 '),
          TextSpan(
            text: '隱私政策',
            style: TextStyle(
              color: AppTheme.accent,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Future<void> _signIn(AuthProvider provider) async {
    final authNotifier = ref.read(authProvider.notifier);

    bool success;
    switch (provider) {
      case AuthProvider.google:
        success = await authNotifier.signInWithGoogle();
        break;
      case AuthProvider.apple:
        success = await authNotifier.signInWithApple();
        break;
      case AuthProvider.discord:
        success = await authNotifier.signInWithDiscord();
        break;
      case AuthProvider.guest:
        success = await authNotifier.signInAsGuest();
        break;
    }

    if (success && mounted) {
      _navigateToHome();
    }
  }

  Future<void> _signInAsGuest() async {
    final success = await ref.read(authProvider.notifier).signInAsGuest();
    if (success && mounted) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    // TODO: 使用 go_router 導航
    // context.go('/home');
    debugPrint('LoginPage: 登入成功，導航到主頁');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// 社群登入按鈕
class _SocialLoginButton extends StatelessWidget {
  final AuthProvider provider;
  final VoidCallback onPressed;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const _SocialLoginButton({
    required this.provider,
    required this.onPressed,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: iconColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              '使用 ${provider.displayName} 登入',
              style: GoogleFonts.notoSerif(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 帳號綁定對話框（訪客升級用）
class LinkAccountDialog extends ConsumerWidget {
  const LinkAccountDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return AlertDialog(
      backgroundColor: AppTheme.primaryMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.accent.withAlpha(77),
          width: 1,
        ),
      ),
      title: Text(
        '綁定帳號',
        style: GoogleFonts.notoSerif(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.accent,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '綁定社群帳號後，您的遊戲進度將會被保存，\n可以在其他裝置上繼續遊玩。',
            style: GoogleFonts.notoSerif(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          if (authState.isLinking)
            const CircularProgressIndicator(color: AppTheme.accent)
          else ...[
            // Google
            _LinkAccountButton(
              provider: AuthProvider.google,
              icon: Icons.g_mobiledata_rounded,
              color: const Color(0xFF4285F4),
              onPressed: () => _linkAccount(context, ref, AuthProvider.google),
            ),
            const SizedBox(height: 12),

            // Apple（僅 iOS）
            if (Platform.isIOS) ...[
              _LinkAccountButton(
                provider: AuthProvider.apple,
                icon: Icons.apple,
                color: Colors.white,
                onPressed: () => _linkAccount(context, ref, AuthProvider.apple),
              ),
              const SizedBox(height: 12),
            ],

            // Discord
            _LinkAccountButton(
              provider: AuthProvider.discord,
              icon: Icons.discord,
              color: const Color(0xFF5865F2),
              onPressed: () => _linkAccount(context, ref, AuthProvider.discord),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '稍後再說',
            style: GoogleFonts.notoSerif(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _linkAccount(
    BuildContext context,
    WidgetRef ref,
    AuthProvider provider,
  ) async {
    final success = await ref.read(authProvider.notifier).linkAccount(provider);
    if (success && context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已成功綁定 ${provider.displayName} 帳號！'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _LinkAccountButton extends StatelessWidget {
  final AuthProvider provider;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _LinkAccountButton({
    required this.provider,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: color.withAlpha(179), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(icon, color: color, size: 20),
        label: Text(
          provider.displayName,
          style: GoogleFonts.notoSerif(
            fontSize: 14,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// 顯示帳號綁定對話框
void showLinkAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const LinkAccountDialog(),
  );
}
