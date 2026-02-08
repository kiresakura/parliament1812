import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // 標題區域
                Column(
                  children: [
                    Text(
                      '1812',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    
                    Text(
                      '國會風雲',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        letterSpacing: 4,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      '政治角力與卡牌策略',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 80),
                
                // 主選單按鈕
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuButton(
                        icon: Icons.play_circle_fill,
                        title: '快速匹配',
                        subtitle: '立即開始一局遊戲',
                        onPressed: () {
                          // TODO: 實現快速匹配
                          context.go('/rooms');
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _MenuButton(
                        icon: Icons.group,
                        title: '房間列表',
                        subtitle: '加入或創建房間',
                        onPressed: () {
                          context.go('/rooms');
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _MenuButton(
                        icon: Icons.casino,
                        title: '卡牌圖鑒',
                        subtitle: '瀏覽所有卡牌效果',
                        onPressed: () {
                          // TODO: 實現卡牌圖鑒
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('卡牌圖鑒將在 M2 版本推出'),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _MenuButton(
                        icon: Icons.school,
                        title: '遊戲教學',
                        subtitle: '學習遊戲規則與策略',
                        onPressed: () {
                          // TODO: 實現教學系統
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('遊戲教學將在 M2 版本推出'),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 設定按鈕
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: 實現設定畫面
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('設定功能將在後續版本推出'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('設定'),
                      ),
                    ],
                  ),
                ),
                
                // 版本資訊
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Parliament 1812 v1.0.0',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        'M1 骨架版本',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}