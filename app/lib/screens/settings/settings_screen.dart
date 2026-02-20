import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/audio_service.dart';
import '../../services/performance_service.dart';
import '../../l10n/app_localizations.dart';

/// 設定畫面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══════════════════════════════════════════
          // 語言設定
          // ═══════════════════════════════════════════
          _SectionHeader(title: l10n.languageSettings, icon: Icons.language),
          const SizedBox(height: 8),
          ...supportedLocales.map((locale) {
            final isSelected = _isLocaleSelected(currentLocale, locale);
            return _LanguageTile(
              locale: locale,
              isSelected: isSelected,
              onTap: () => ref.read(localeProvider.notifier).setLocale(locale),
            );
          }),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════
          // 音效設定
          // ═══════════════════════════════════════════
          _SectionHeader(title: l10n.audioSettings, icon: Icons.volume_up),
          const SizedBox(height: 8),
          _AudioToggleTile(
            title: l10n.soundEffects,
            icon: Icons.music_note,
            provider: sfxEnabledProvider,
            onChanged: (value) {
              final prefs = ref.read(sharedPreferencesProvider);
              ref.read(audioServiceProvider).setSfxEnabled(value, prefs);
            },
          ),
          _AudioToggleTile(
            title: l10n.backgroundMusic,
            icon: Icons.library_music,
            provider: bgmEnabledProvider,
            onChanged: (value) {
              final prefs = ref.read(sharedPreferencesProvider);
              ref.read(audioServiceProvider).setBgmEnabled(value, prefs);
            },
          ),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════
          // 畫面品質
          // ═══════════════════════════════════════════
          _SectionHeader(title: l10n.graphicsQuality, icon: Icons.tune),
          const SizedBox(height: 8),
          _GraphicsQualitySection(),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════
          // 帳號管理
          // ═══════════════════════════════════════════
          _SectionHeader(title: l10n.accountSettings, icon: Icons.person),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: Text(l10n.logout),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
              title: Text(
                l10n.deleteAccount,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () => _showDeleteAccountDialog(context, ref, l10n),
            ),
          ),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════
          // 關於
          // ═══════════════════════════════════════════
          _SectionHeader(title: l10n.aboutApp, icon: Icons.info_outline),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: Text(l10n.version),
              trailing: Text(
                '1.0.0',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isLocaleSelected(Locale? current, Locale target) {
    if (current == null) {
      // 預設為 zh_TW
      return target.languageCode == 'zh' && target.countryCode == 'TW';
    }
    return current.languageCode == target.languageCode &&
        current.countryCode == target.countryCode;
  }

  void _showDeleteAccountDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: 實際刪除帳號
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 共用 Widget
// ═══════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final Locale locale;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.locale,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = LocaleNotifier.getDisplayName(locale);

    return Card(
      color: isSelected
          ? theme.colorScheme.secondary.withValues(alpha: 0.1)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.secondary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.secondary : null,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: theme.colorScheme.secondary)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _AudioToggleTile extends ConsumerWidget {
  final String title;
  final IconData icon;
  final StateProvider<bool> provider;
  final ValueChanged<bool> onChanged;

  const _AudioToggleTile({
    required this.title,
    required this.icon,
    required this.provider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(provider);

    return Card(
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(title),
        value: enabled,
        onChanged: (value) {
          ref.read(provider.notifier).state = value;
          onChanged(value);
        },
      ),
    );
  }
}

// 音效啟用 providers（簡易版本）
final sfxEnabledProvider = StateProvider<bool>((ref) => true);
final bgmEnabledProvider = StateProvider<bool>((ref) => true);

// ═══════════════════════════════════════════
// 畫面品質設定
// ═══════════════════════════════════════════

class _GraphicsQualitySection extends ConsumerWidget {
  static const _qualityOptions = GraphicsQuality.values;

  static IconData _iconForQuality(GraphicsQuality quality) {
    switch (quality) {
      case GraphicsQuality.auto:
        return Icons.auto_awesome;
      case GraphicsQuality.low:
        return Icons.speed;
      case GraphicsQuality.medium:
        return Icons.balance;
      case GraphicsQuality.high:
        return Icons.high_quality;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentQuality = ref.watch(graphicsQualityProvider);
    final detectedQuality = ref.watch(detectedQualityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _qualityOptions.map((quality) {
        final isSelected = currentQuality == quality;
        return Card(
          color: isSelected
              ? theme.colorScheme.secondary.withValues(alpha: 0.1)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? BorderSide(color: theme.colorScheme.secondary, width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            leading: Icon(
              _iconForQuality(quality),
              color: isSelected ? theme.colorScheme.secondary : null,
            ),
            title: Text(
              quality.displayName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.secondary : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quality.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (quality == GraphicsQuality.auto && isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '偵測建議：${detectedQuality.displayName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: theme.colorScheme.secondary)
                : null,
            onTap: () {
              ref.read(graphicsQualityProvider.notifier).setQuality(quality);
            },
          ),
        );
      }).toList(),
    );
  }
}
