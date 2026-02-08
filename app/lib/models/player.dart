import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'player.freezed.dart';
part 'player.g.dart';

@freezed
class Player with _$Player {
  const factory Player({
    required String id,
    required String name,
    required CharacterType character,
    required String faction,
    required PlayerResources resources,
    required bool isReady,
    required bool isHost,
    required bool isAlive,  // false = 政治死亡
    @Default([]) List<String> handCards,  // 手牌 ID 列表
    @Default([]) List<String> negativeTraits,  // 負面特質
    @Default({}) Map<String, dynamic> status,  // 狀態效果（沉默、封印等）
  }) = _Player;

  factory Player.fromJson(Map<String, Object?> json) => _$PlayerFromJson(json);
}

@freezed
class PlayerResources with _$PlayerResources {
  const factory PlayerResources({
    @Default(50) int reputation,   // 聲望 ❤️
    @Default(10) int influence,    // 影響力 🌟
    @Default(30) int gold,         // 金幣 💰
  }) = _PlayerResources;

  factory PlayerResources.fromJson(Map<String, Object?> json) => _$PlayerResourcesFromJson(json);
}

enum CharacterType {
  @JsonValue('thomas_worker')
  thomasWorker,
  
  @JsonValue('richard_factory')
  richardFactory,
  
  @JsonValue('george_luddite')
  georgeLuddite,
  
  @JsonValue('robert_reformer')
  robertReformer,
  
  @JsonValue('edward_journalist')
  edwardJournalist,
  
  @JsonValue('william_mp')
  williamMp,
  
  @JsonValue('george_king')
  georgeKing,
}

extension CharacterTypeExtension on CharacterType {
  String get displayName {
    switch (this) {
      case CharacterType.thomasWorker:
        return '工人湯瑪斯';
      case CharacterType.richardFactory:
        return '工廠主理查';
      case CharacterType.georgeLuddite:
        return '盧德派喬治';
      case CharacterType.robertReformer:
        return '改革者羅伯特';
      case CharacterType.edwardJournalist:
        return '記者愛德華';
      case CharacterType.williamMp:
        return '議員威廉';
      case CharacterType.georgeKing:
        return '喬治三世';
    }
  }

  String get description {
    switch (this) {
      case CharacterType.thomasWorker:
        return '勞工派核心，團隊戰士。擅長團結盟友，對資方有額外威脅。';
      case CharacterType.richardFactory:
        return '資方派核心，經濟專家。用金錢控制局面，但容易成為眾矢之的。';
      case CharacterType.georgeLuddite:
        return '激進派代表，高傷害爆發。風險與收益並存的狂戰士。';
      case CharacterType.robertReformer:
        return '改革派領袖，外交天才。調停各方衝突，促進和平合作。';
      case CharacterType.edwardJournalist:
        return '中立記者，情報專家。挖掘真相，掌握全局資訊。';
      case CharacterType.williamMp:
        return '老練議員，政治掮客。人脈廣泛，善於交易和操控。';
      case CharacterType.georgeKing:
        return '英國國王，至高權力。王權強大但精神不穩，孤高難合。';
    }
  }

  String get faction {
    switch (this) {
      case CharacterType.thomasWorker:
      case CharacterType.georgeLuddite:
        return 'labor';  // 勞工派
      case CharacterType.richardFactory:
        return 'capital';  // 資方派
      case CharacterType.robertReformer:
        return 'reform';  // 改革派
      case CharacterType.edwardJournalist:
      case CharacterType.williamMp:
        return 'neutral';  // 中立派
      case CharacterType.georgeKing:
        return 'crown';  // 皇室（特殊）
    }
  }

  PlayerResources get initialResources {
    switch (this) {
      case CharacterType.thomasWorker:
        return const PlayerResources(reputation: 70, influence: 10, gold: 20);
      case CharacterType.richardFactory:
        return const PlayerResources(reputation: 60, influence: 10, gold: 100);
      case CharacterType.georgeLuddite:
        return const PlayerResources(reputation: 80, influence: 10, gold: 10);
      case CharacterType.robertReformer:
        return const PlayerResources(reputation: 65, influence: 12, gold: 40);
      case CharacterType.edwardJournalist:
        return const PlayerResources(reputation: 50, influence: 10, gold: 30);
      case CharacterType.williamMp:
        return const PlayerResources(reputation: 75, influence: 10, gold: 60);
      case CharacterType.georgeKing:
        return const PlayerResources(reputation: 90, influence: 8, gold: 80);
    }
  }

  List<String> get negativeTraits {
    switch (this) {
      case CharacterType.thomasWorker:
        return ['文盲'];
      case CharacterType.richardFactory:
        return ['眾矢之的', '貪婪'];
      case CharacterType.georgeLuddite:
        return ['衝動', '暴躁'];
      case CharacterType.robertReformer:
        return ['優柔寡斷'];
      case CharacterType.edwardJournalist:
        return ['大嘴巴', '易受攻擊'];
      case CharacterType.williamMp:
        return ['牆頭草'];
      case CharacterType.georgeKing:
        return ['精神不穩', '高處不勝寒'];
    }
  }
}

// 工廠方法：建立隨機玩家
class PlayerFactory {
  static const _uuid = Uuid();

  static Player createPlayer({
    required String name,
    required CharacterType character,
    bool isHost = false,
  }) {
    return Player(
      id: _uuid.v4(),
      name: name,
      character: character,
      faction: character.faction,
      resources: character.initialResources,
      isReady: false,
      isHost: isHost,
      isAlive: true,
      negativeTraits: character.negativeTraits,
    );
  }

  static Player createRandomPlayer(String name) {
    final characters = CharacterType.values;
    final randomCharacter = characters[DateTime.now().millisecond % characters.length];
    return createPlayer(name: name, character: randomCharacter);
  }
}