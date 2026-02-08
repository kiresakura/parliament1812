import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
// Remove constants import for now
import 'player.dart';

part 'room.freezed.dart';
part 'room.g.dart';

enum GamePhase {
  @JsonValue('waiting')
  waiting,
  
  @JsonValue('preparation')
  preparation,
  
  @JsonValue('conspiracy')
  conspiracy,
  
  @JsonValue('debate')
  debate,
  
  @JsonValue('event')
  event,
  
  @JsonValue('final_speech')
  finalSpeech,
  
  @JsonValue('voting')
  voting,
  
  @JsonValue('result')
  result,
}

enum VoteChoice {
  @JsonValue('a')
  a,
  
  @JsonValue('b')
  b,
  
  @JsonValue('c')
  c,
  
  @JsonValue('abstain')
  abstain,
}

@freezed
class Room with _$Room {
  const factory Room({
    required String id,
    required String code,
    required String name,
    required String hostId,
    required RoomStatus status,
    required GamePhase phase,
    required List<Player> players,
    required RoomSettings settings,
    @Default(1) int round,
    @Default(0) int remainingSeconds,
    @Default('') String currentBill,  // 當前議案內容
    @Default({}) Map<String, dynamic> gameState,  // 遊戲狀態資料
    @Default([]) List<Player> spectators,  // 觀戰者列表
    required DateTime createdAt,
    DateTime? startedAt,
  }) = _Room;

  factory Room.fromJson(Map<String, Object?> json) => _$RoomFromJson(json);
}

@freezed
class RoomSettings with _$RoomSettings {
  const factory RoomSettings({
    @Default(4) int maxPlayers,
    @Default(2) int minPlayers,
    @Default(true) bool allowSpectators,
    @Default(10) int maxSpectators,
    @Default(false) bool isPrivate,
    @Default('') String password,
    @Default(60) int preparationDuration,
    @Default(180) int conspiracyDuration,
    @Default(360) int debateDuration,
    @Default(60) int eventDuration,
    @Default(120) int finalSpeechDuration,
    @Default(60) int votingDuration,
  }) = _RoomSettings;

  factory RoomSettings.fromJson(Map<String, Object?> json) => _$RoomSettingsFromJson(json);
}

enum RoomStatus {
  @JsonValue('waiting')
  waiting,      // 等待玩家加入
  
  @JsonValue('ready')
  ready,        // 可以開始遊戲
  
  @JsonValue('playing')
  playing,      // 遊戲進行中
  
  @JsonValue('finished')
  finished,     // 遊戲結束
  
  @JsonValue('cancelled')
  cancelled,    // 房間取消
}

extension RoomStatusExtension on RoomStatus {
  String get displayName {
    switch (this) {
      case RoomStatus.waiting:
        return '等待中';
      case RoomStatus.ready:
        return '準備就緒';
      case RoomStatus.playing:
        return '遊戲中';
      case RoomStatus.finished:
        return '已結束';
      case RoomStatus.cancelled:
        return '已取消';
    }
  }

  bool get canJoin {
    return this == RoomStatus.waiting || this == RoomStatus.ready;
  }
}

// 房間擴展方法
extension RoomExtension on Room {
  // 是否可以開始遊戲
  bool get canStartGame {
    return status == RoomStatus.waiting && 
           players.length >= settings.minPlayers && 
           players.every((p) => p.isReady || p.isHost);
  }

  // 是否已滿員
  bool get isFull {
    return players.length >= settings.maxPlayers;
  }

  // 獲取房主
  Player? get host {
    try {
      return players.firstWhere((p) => p.id == hostId);
    } catch (e) {
      return null;
    }
  }

  // 獲取存活玩家
  List<Player> get alivePlayers {
    return players.where((p) => p.isAlive).toList();
  }

  // 獲取準備好的玩家數量
  int get readyCount {
    return players.where((p) => p.isReady || p.isHost).length;
  }

  // 獲取各陣營玩家數量
  Map<String, int> get factionCounts {
    final counts = <String, int>{};
    for (final player in players) {
      counts[player.character?.faction ?? "neutral"] = (counts[player.character?.faction ?? "neutral"] ?? 0) + 1;
    }
    return counts;
  }

  // 根據玩家 ID 查找玩家
  Player? findPlayer(String playerId) {
    try {
      return players.firstWhere((p) => p.id == playerId);
    } catch (e) {
      return null;
    }
  }

  // 檢查是否為房主
  bool isHost(String playerId) {
    return hostId == playerId;
  }

  // 獲取當前階段剩餘時間百分比
  double get phaseProgress {
    final totalDuration = getPhaseDuration(phase);
    if (totalDuration <= 0) return 1.0;
    
    final elapsed = totalDuration - remainingSeconds;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  // 獲取階段總時間
  int getPhaseDuration(GamePhase phase) {
    switch (phase) {
      case GamePhase.waiting:
        return 0;
      case GamePhase.preparation:
        return settings.preparationDuration;
      case GamePhase.conspiracy:
        return settings.conspiracyDuration;
      case GamePhase.debate:
        return settings.debateDuration;
      case GamePhase.event:
        return settings.eventDuration;
      case GamePhase.finalSpeech:
        return settings.finalSpeechDuration;
      case GamePhase.voting:
        return settings.votingDuration;
      case GamePhase.result:
        return 30;  // 結果展示 30 秒
    }
  }
}

// 房間工廠類
class RoomFactory {
  static const _uuid = Uuid();

  // 生成房間代碼
  static String generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String result = '';
    
    for (int i = 0; i < 6; i++) {
      result += chars[(random + i) % chars.length];
    }
    
    return result;
  }

  // 創建新房間
  static Room createRoom({
    required String name,
    required String hostPlayerId,
    Player? hostPlayer,
    RoomSettings? settings,
  }) {
    return Room(
      id: _uuid.v4(),
      code: generateRoomCode(),
      name: name,
      hostId: hostPlayerId,
      status: RoomStatus.waiting,
      phase: GamePhase.waiting,
      players: hostPlayer != null ? [hostPlayer] : [],
      settings: settings ?? const RoomSettings(),
      createdAt: DateTime.now(),
    );
  }

  // 創建快速匹配房間
  static Room createQuickMatchRoom() {
    return createRoom(
      name: '快速匹配 ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      hostPlayerId: 'system',
      settings: const RoomSettings(
        preparationDuration: 30,
        conspiracyDuration: 120,
        debateDuration: 300,
      ),
    );
  }
}