import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final notifier = ref.read(authProvider.notifier);
    final result =
        await notifier.forgotPassword(_emailController.text.trim());

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result) {
          _submitted = true;
        } else {
          _error = '請求失敗，請稍後再試';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('忘記密碼'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
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
              child: _submitted
                  ? _buildSuccessView(theme)
                  : _buildFormView(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: Parliament1812Theme.gold,
        ),
        const SizedBox(height: 24),
        Text(
          '已寄出重設連結',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Parliament1812Theme.gold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '如果該 Email 已註冊，您將收到密碼重設指示。請檢查您的收件匣。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Parliament1812Theme.cream.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: () => context.go('/login'),
          child: const Text('返回登入'),
        ),
      ],
    );
  }

  Widget _buildFormView(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_reset,
            size: 64,
            color: Parliament1812Theme.gold,
          ),
          const SizedBox(height: 24),
          Text(
            '重設密碼',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Parliament1812Theme.gold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '輸入您的 Email，我們將寄送密碼重設連結。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Parliament1812Theme.cream.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSubmit(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '請輸入 Email';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Email 格式無效';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),

          // 送出按鈕
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Parliament1812Theme.cream,
                      ),
                    )
                  : const Text('寄送重設連結'),
            ),
          ),
          const SizedBox(height: 16),

          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(
              '返回登入',
              style: TextStyle(
                color: Parliament1812Theme.cream.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
