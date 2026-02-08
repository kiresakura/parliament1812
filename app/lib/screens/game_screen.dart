import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/connection_indicator.dart';

class GameScreen extends ConsumerWidget {
  final String roomCode;

  const GameScreen({
    super.key,
    required this.roomCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('房間 $roomCode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showLeaveGameDialog(context),
        ),
        actions: [
          const ConnectionIndicator(),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: 遊戲選單（設定、規則等）
            },
          ),
        ],
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 遊戲圖標
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.construction,
                    size: 60,
                    color: theme.colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // 標題
                Text(
                  'Coming in M2',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 副標題
                Text(
                  '遊戲核心功能開發中',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 功能預告
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'M2 版本將包含：',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      ..._getFeatureList(theme).map((feature) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 20,
                                color: theme.colorScheme.secondary,
                              ),
                              
                              const SizedBox(width: 12),
                              
                              Expanded(
                                child: Text(
                                  feature,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // 當前版本資訊
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'M1 骨架版本 - 基礎架構完成',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 返回按鈕
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.go('/room/$roomCode'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('返回房間'),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    ElevatedButton.icon(
                      onPressed: () => context.go('/menu'),
                      icon: const Icon(Icons.home),
                      label: const Text('回到主選單'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getFeatureList(ThemeData theme) {
    return [
      '完整的卡牌戰鬥系統',
      '即時聊天與私訊功能',
      '遊戲階段流程控制',
      '投票表決機制',
      '角色技能與負面特質',
      '56 張卡牌完整實現',
      '聲望與資源管理',
      '突發事件系統',
      '遊戲結果與排名',
      '音效與視覺特效',
    ];
  }

  void _showLeaveGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('離開遊戲'),
        content: const Text('確定要離開遊戲嗎？遊戲進度將會遺失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/rooms');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('離開'),
          ),
        ],
      ),
    );
  }
}