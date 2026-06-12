import 'package:flutter/material.dart';

import '../models/player.dart';
import '../config/theme.dart';

class PlayerAvatar extends StatelessWidget {
  final CharacterType? character;
  final double size;
  final bool showBorder;
  final bool isOnline;
  final bool isDead;

  const PlayerAvatar({
    super.key,
    required this.character,
    this.size = 48,
    this.showBorder = true,
    this.isOnline = true,
    this.isDead = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final factionColor = Parliament1812Theme.getFactionColor(character?.faction ?? "neutral");
    
    return Stack(
      children: [
        // 主頭像
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDead 
                ? Colors.grey.shade300
                : factionColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: showBorder
                ? Border.all(
                    color: isDead 
                        ? Colors.grey.shade400
                        : factionColor,
                    width: size > 40 ? 3 : 2,
                  )
                : null,
            boxShadow: showBorder
                ? [
                    BoxShadow(
                      color: (isDead ? Colors.grey : factionColor).withValues(alpha: 0.2),
                      blurRadius: size * 0.1,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // 角色圖像（有圖用圖，沒有用 emoji fallback）
              if (_getCharacterPortrait(character) != null)
                Positioned.fill(
                  child: Image.asset(
                    _getCharacterPortrait(character)!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        _getCharacterEmoji(character),
                        style: TextStyle(fontSize: size * 0.4),
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Text(
                    _getCharacterEmoji(character),
                    style: TextStyle(fontSize: size * 0.4),
                  ),
                ),
              
              // 死亡遮罩
              if (isDead)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: size * 0.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // 在線狀態指示
        if (showBorder && size >= 40)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        
        // 角色專屬小圖標
        if (size >= 48)
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: factionColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  _getCharacterIcon(character),
                  color: Colors.white,
                  size: size * 0.15,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String? _getCharacterPortrait(CharacterType? character) {
    switch (character) {
      case CharacterType.thomasWorker:
        return 'assets/images/characters/portrait_thomas.png';
      case CharacterType.richardFactory:
        return 'assets/images/characters/portrait_richard.png';
      case CharacterType.georgeLuddite:
        return 'assets/images/characters/portrait_george.png';
      case CharacterType.robertReformer:
        return 'assets/images/characters/portrait_robert.png';
      case CharacterType.williamMp:
        return 'assets/images/characters/portrait_william.png';
      case CharacterType.edwardJournalist:
      case CharacterType.georgeKing:
      case null:
        return null;
    }
  }

  String _getCharacterEmoji(CharacterType? character) {
    switch (character) {
      case CharacterType.thomasWorker:
        return '👷';
      case CharacterType.richardFactory:
        return '🏭';
      case CharacterType.georgeLuddite:
        return '⚔️';
      case CharacterType.robertReformer:
        return '🤝';
      case CharacterType.edwardJournalist:
        return '📰';
      case CharacterType.williamMp:
        return '🏛️';
      case CharacterType.georgeKing:
        return '👑';
      case null:
        return '❓';
    }
  }

  IconData _getCharacterIcon(CharacterType? character) {
    switch (character) {
      case CharacterType.thomasWorker:
        return Icons.construction;
      case CharacterType.richardFactory:
        return Icons.business;
      case CharacterType.georgeLuddite:
        return Icons.gavel;
      case CharacterType.robertReformer:
        return Icons.balance;
      case CharacterType.edwardJournalist:
        return Icons.article;
      case CharacterType.williamMp:
        return Icons.account_balance;
      case CharacterType.georgeKing:
        return Icons.diamond;
      case null:
        return Icons.person;
    }
  }
}

class PlayerAvatarWithName extends StatelessWidget {
  final CharacterType? character;
  final String playerName;
  final double size;
  final bool showFaction;
  final bool isOnline;
  final bool isDead;

  const PlayerAvatarWithName({
    super.key,
    required this.character,
    required this.playerName,
    this.size = 48,
    this.showFaction = true,
    this.isOnline = true,
    this.isDead = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final factionColor = Parliament1812Theme.getFactionColor(character?.faction ?? "neutral");
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerAvatar(
          character: character,
          size: size,
          isOnline: isOnline,
          isDead: isDead,
        ),
        
        const SizedBox(height: 8),
        
        // 玩家名稱
        SizedBox(
          width: size + 16,
          child: Text(
            playerName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDead 
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                  : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // 角色名稱
        SizedBox(
          width: size + 16,
          child: Text(
            character?.displayName ?? "?",
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDead 
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // 陣營標籤
        if (showFaction) ...[
          const SizedBox(height: 4),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDead 
                  ? Colors.grey.withValues(alpha: 0.1)
                  : factionColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDead 
                    ? Colors.grey.withValues(alpha: 0.3)
                    : factionColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _getFactionDisplayName(character?.faction ?? "neutral"),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDead 
                    ? Colors.grey
                    : factionColor,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getFactionDisplayName(String faction) {
    switch (faction.toLowerCase()) {
      case 'labor':
        return '勞工派';
      case 'capital':
        return '資方派';
      case 'reform':
        return '改革派';
      case 'neutral':
        return '中立派';
      case 'crown':
        return '皇室';
      default:
        return faction;
    }
  }
}

class PlayerAvatarRow extends StatelessWidget {
  final List<Player> players;
  final double avatarSize;
  final int maxVisible;
  final VoidCallback? onShowAll;

  const PlayerAvatarRow({
    super.key,
    required this.players,
    this.avatarSize = 32,
    this.maxVisible = 5,
    this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visiblePlayers = players.take(maxVisible).toList();
    final remainingCount = players.length - maxVisible;
    
    return Row(
      children: [
        // 顯示頭像
        ...visiblePlayers.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;
          
          return Padding(
            padding: EdgeInsets.only(
              left: index > 0 ? -avatarSize * 0.3 : 0,
            ),
            child: PlayerAvatar(
              character: player.character,
              size: avatarSize,
              isOnline: player.isAlive,
              isDead: !player.isAlive,
            ),
          );
        }),
        
        // 剩餘玩家數量
        if (remainingCount > 0) ...[
          Padding(
            padding: EdgeInsets.only(left: -avatarSize * 0.3),
            child: GestureDetector(
              onTap: onShowAll,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}