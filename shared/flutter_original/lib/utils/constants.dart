// 遊戲常數定義

/// 遊戲階段枚舉
enum GamePhase {
  waiting('等待中'),
  preparing('角色研究'),
  conspiracy('私下密謀'),
  debate('開場陳述'),
  event1('突發事件 #1'),
  debate2('自由辯論'),
  event2('突發事件 #2'),
  voteRound1('第一輪投票'),
  finalDebate('最後攻防'),
  voteRound2('第二輪投票'),
  reveal('結果揭曉'),
  finished('遊戲結束');

  final String name;
  const GamePhase(this.name);
}

/// 投票選項
enum VoteOption {
  A('禁止機器', '立法禁止工廠使用省力機器'),
  B('保護財產', '嚴厲打擊破壞機器的暴民'),
  C('折衷改革', '允許機器但立法保障工人權益'),
  D('皇家調查', '成立皇家調查委員會深入研究');

  final String title;
  final String description;
  const VoteOption(this.title, this.description);
}

/// 角色類型
enum RoleType {
  worker('工人', '紡織工人'),
  factory('工廠主', '工廠主'),
  luddite('盧德派', '盧德派'),
  reformer('改革者', '改革者'),
  mp('議員', '議員');

  final String name;
  final String description;
  const RoleType(this.name, this.description);
}

/// 階段持續時間（分鐘）
class PhaseDurations {
  static const int preparing = 15;
  static const int conspiracy = 10;
  static const int debate = 25;
  static const int event = 5;
  static const int debate2 = 30;
  static const int voteRound1 = 5;
  static const int finalDebate = 10;
  static const int voteRound2 = 5;
  static const int reveal = 10;
}
