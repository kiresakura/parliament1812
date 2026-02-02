// 1812 國會風雲 - 教學流程資料
//
// 定義完整的教學課程和步驟

import '../../domain/models/tutorial.dart';

/// 教學資料管理
class TutorialData {
  TutorialData._();

  /// 獲取所有課程
  static List<TutorialLesson> get allLessons => TutorialLesson.values;

  /// 獲取課程的所有步驟
  static List<TutorialStep> getStepsForLesson(TutorialLesson lesson) {
    switch (lesson) {
      case TutorialLesson.introduction:
        return introductionSteps;
      case TutorialLesson.query:
        return querySteps;
      case TutorialLesson.rebut:
        return rebutSteps;
      case TutorialLesson.skill:
        return skillSteps;
      case TutorialLesson.vote:
        return voteSteps;
    }
  }

  /// 獲取所有步驟
  static List<TutorialStep> get allSteps => [
        ...introductionSteps,
        ...querySteps,
        ...rebutSteps,
        ...skillSteps,
        ...voteSteps,
      ];

  /// 根據 ID 獲取步驟
  static TutorialStep? getStepById(String id) {
    try {
      return allSteps.firstWhere((step) => step.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 獲取課程的步驟數量
  static int getStepCount(TutorialLesson lesson) {
    return getStepsForLesson(lesson).length;
  }

  /// 獲取總步驟數
  static int get totalStepCount => allSteps.length;

  // ============================================================
  // 第一課：認識遊戲（5 步驟）
  // ============================================================

  static const List<TutorialStep> introductionSteps = [
    // 步驟 1：歡迎
    TutorialStep(
      id: 'intro_1_welcome',
      lesson: TutorialLesson.introduction,
      title: '歡迎來到 1812 國會',
      description: '''
歡迎來到《1812 國會風雲》！

這是一款以英國工業革命為背景的社交推理遊戲。
你將扮演 1812 年的議會人物，透過辯論、結盟、
投票來達成你的政治目標。

準備好踏入這段歷史旅程了嗎？''',
      targetElement: null,
      requiredAction: TutorialAction.confirm,
      skippable: false,
      hintDelay: 5000,
    ),

    // 步驟 2：聲望系統
    TutorialStep(
      id: 'intro_2_reputation',
      lesson: TutorialLesson.introduction,
      title: '聲望就是你的生命',
      description: '''
在這個遊戲中，「聲望」是最重要的資源。

**聲望 = 你的政治影響力**

• 每個角色有不同的初始聲望（50-100）
• 聲望會影響你的投票權重
• 聲望歸零 = 政治死亡（失去投票權）

保護好你的聲望，這是生存的關鍵！''',
      targetElement: 'reputation_bar',
      requiredAction: TutorialAction.confirm,
      skippable: false,
      hintDelay: 3000,
    ),

    // 步驟 3：辯論機制
    TutorialStep(
      id: 'intro_3_debate',
      lesson: TutorialLesson.introduction,
      title: '辯論就是戰鬥',
      description: '''
議會辯論是遊戲的核心！

**質詢（攻擊）**
消耗 10 聲望，對目標造成 15 點傷害

**反駁（防禦）**
消耗 5 聲望，完全抵消對方的質詢

這就像一場口舌之戰，每一句話都是武器！''',
      targetElement: 'action_buttons',
      requiredAction: TutorialAction.confirm,
      skippable: false,
      hintDelay: 3000,
    ),

    // 步驟 4：投票系統
    TutorialStep(
      id: 'intro_4_voting',
      lesson: TutorialLesson.introduction,
      title: '投票決定一切',
      description: '''
每局遊戲的最終目標是透過投票決定議案結果。

**投票規則**
• 每個玩家可以投給任一選項
• 聲望越高，投票權重越大
• 聲望 > 80：1.5 倍權重
• 聲望 50-80：1.0 倍權重
• 聲望 < 30：0.5 倍權重

你的每一個行動都在為最終投票鋪路！''',
      targetElement: 'vote_panel',
      requiredAction: TutorialAction.confirm,
      skippable: false,
      hintDelay: 3000,
    ),

    // 步驟 5：勝利條件
    TutorialStep(
      id: 'intro_5_victory',
      lesson: TutorialLesson.introduction,
      title: '如何獲勝？',
      description: '''
遊戲的勝利條件取決於你的角色陣營：

**工人派** 🔨
希望禁止機器，保護工人權益

**資方派** 💰
希望保護財產，推動工業發展

**改革派** 📜
希望達成妥協，漸進改革

讓你支持的選項通過投票，就是勝利！

恭喜你完成第一課！接下來讓我們學習實戰技巧。''',
      targetElement: null,
      requiredAction: TutorialAction.confirm,
      skippable: false,
      hintDelay: 3000,
      onCompleteData: {'lessonComplete': true},
    ),
  ];

  // ============================================================
  // 第二課：學習質詢（4 步驟）
  // ============================================================

  static const List<TutorialStep> querySteps = [
    // 步驟 1：什麼是質詢
    TutorialStep(
      id: 'query_1_intro',
      lesson: TutorialLesson.query,
      title: '什麼是質詢？',
      description: '''
「質詢」是辯論中最基本的攻擊手段。

在議會中，質詢代表對對手觀點的公開挑戰。

**質詢效果**
• 消耗自己 10 點聲望
• 對目標造成 15 點聲望傷害
• 如果對方反駁，攻擊會被抵消

選擇正確的目標和時機至關重要！''',
      targetElement: 'query_button',
      requiredAction: TutorialAction.confirm,
      skippable: false,
      hintDelay: 3000,
    ),

    // 步驟 2：如何選擇目標
    TutorialStep(
      id: 'query_2_target',
      lesson: TutorialLesson.query,
      title: '選擇你的目標',
      description: '''
點擊「質詢」按鈕後，你需要選擇攻擊目標。

**選擇建議**
• 優先攻擊敵對陣營的玩家
• 注意對方的聲望和防禦狀態
• 避免攻擊可能結盟的對象

現在，點擊「質詢」按鈕開始選擇目標。''',
      targetElement: 'query_button',
      requiredAction: TutorialAction.tapButton,
      actionValidation: {'buttonId': 'query_button'},
      skippable: false,
      hintDelay: 5000,
    ),

    // 步驟 3：執行質詢
    TutorialStep(
      id: 'query_3_execute',
      lesson: TutorialLesson.query,
      title: '發起質詢！',
      description: '''
現在選擇一個對手，對他發起質詢！

點擊目標玩家的頭像或名字來選擇。
選擇完成後，確認發起質詢。

**提示**
工廠主理查是個不錯的練習目標——
他總是喜歡炫耀他的財富！''',
      targetElement: 'player_list',
      requiredAction: TutorialAction.attackPlayer,
      actionValidation: {'minDamage': 1},
      skippable: false,
      hintDelay: 5000,
      demoConfig: TutorialDemoConfig(
        aiCharacterId: 'factory_richard',
        action: TutorialAction.wait,
        duration: 1500,
        showThinking: false,
        postDialogue: '你竟敢質疑我？不懂經濟的人就是麻煩！',
      ),
    ),

    // 步驟 4：觀察效果
    TutorialStep(
      id: 'query_4_effect',
      lesson: TutorialLesson.query,
      title: '觀察傷害效果',
      description: '''
做得好！你成功發起了一次質詢！

**發生了什麼**
• 你消耗了 10 點聲望
• 對方受到了 15 點傷害
• 這個傷害會顯示在他的聲望條上

注意：對方可以選擇「反駁」來抵消你的攻擊。
所以有時候，突然襲擊會更有效！

恭喜完成第二課！現在你知道如何攻擊了。''',
      targetElement: 'reputation_bar',
      requiredAction: TutorialAction.confirm,
      skippable: false,
      hintDelay: 3000,
      onCompleteData: {'lessonComplete': true},
    ),
  ];

  // ============================================================
  // 第三課：學習反駁（3 步驟）
  // ============================================================

  static const List<TutorialStep> rebutSteps = [
    // 步驟 1：什麼是反駁
    TutorialStep(
      id: 'rebut_1_intro',
      lesson: TutorialLesson.rebut,
      title: '什麼是反駁？',
      description: '''
「反駁」是你的防禦手段！

當有人對你發起質詢時，你可以選擇反駁。

**反駁效果**
• 消耗 5 點聲望
• 完全抵消對方的質詢傷害
• 對方仍然會消耗他的 10 點聲望

善用反駁可以讓攻擊者得不償失！''',
      targetElement: 'rebut_button',
      requiredAction: TutorialAction.confirm,
      skippable: false,
      hintDelay: 3000,
    ),

    // 步驟 2：等待被攻擊
    TutorialStep(
      id: 'rebut_2_wait',
      lesson: TutorialLesson.rebut,
      title: '準備好防禦',
      description: '''
現在讓我們實際練習反駁。

AI 對手即將對你發起質詢。
當攻擊來臨時，你會看到一個「反駁」按鈕。

準備好了嗎？觀察 AI 的行動...''',
      targetElement: null,
      requiredAction: TutorialAction.wait,
      skippable: false,
      hintDelay: 2000,
      demoConfig: TutorialDemoConfig(
        aiCharacterId: 'factory_richard',
        action: TutorialAction.attackPlayer,
        targetId: 'human_player',
        duration: 2500,
        showThinking: true,
        preDialogue: '讓我來教訓一下這個新人...',
        postDialogue: '你這種人根本不懂什麼是進步！',
      ),
    ),

    // 步驟 3：執行反駁
    TutorialStep(
      id: 'rebut_3_execute',
      lesson: TutorialLesson.rebut,
      title: '反駁攻擊！',
      description: '''
你被攻擊了！

快點擊「反駁」按鈕來防禦這次攻擊！

**記住**
• 反駁需要消耗 5 點聲望
• 但可以完全抵消 15 點傷害
• 這是一筆划算的交易！

快按下反駁按鈕！''',
      targetElement: 'rebut_button',
      requiredAction: TutorialAction.defendAttack,
      actionValidation: {'defendSuccess': true},
      skippable: false,
      hintDelay: 1000,
      onCompleteData: {'lessonComplete': true},
    ),
  ];

  // ============================================================
  // 第四課：使用技能（4 步驟）
  // ============================================================

  static const List<TutorialStep> skillSteps = [
    // 步驟 1：介紹角色技能
    TutorialStep(
      id: 'skill_1_intro',
      lesson: TutorialLesson.skill,
      title: '角色專屬技能',
      description: '''
每個角色都有獨特的技能，這是你的王牌！

**四個 MVP 角色技能**

🔨 工人湯瑪斯【團結】
每有 1 名工人盟友，防禦 +10

💰 工廠主理查【收買】
花費金幣使目標沉默 1 回合

📰 記者愛德華【爆料】
揭露目標的秘密任務

🔥 盧德派喬治【怒火】
造成雙倍傷害，但自己也扣 10 聲望''',
      targetElement: 'skill_button',
      requiredAction: TutorialAction.confirm,
      skippable: false,
      hintDelay: 5000,
    ),

    // 步驟 2：選擇使用時機
    TutorialStep(
      id: 'skill_2_timing',
      lesson: TutorialLesson.skill,
      title: '技能使用時機',
      description: '''
技能是珍貴的資源，選對時機很重要！

**使用建議**

• 觀察戰局形勢
• 在關鍵時刻使用
• 配合盟友的行動
• 考慮技能的消耗

現在讓我們來使用一次技能！
點擊技能按鈕開始。''',
      targetElement: 'skill_button',
      requiredAction: TutorialAction.tapButton,
      actionValidation: {'buttonId': 'skill_button'},
      skippable: false,
      hintDelay: 5000,
    ),

    // 步驟 3：執行技能
    TutorialStep(
      id: 'skill_3_execute',
      lesson: TutorialLesson.skill,
      title: '使用技能！',
      description: '''
太好了！現在你可以使用你的角色技能了。

如果技能需要選擇目標，請點擊一個對象。
然後確認使用技能。

**提示**
不同技能有不同的效果和消耗，
仔細閱讀技能說明再決定！''',
      targetElement: 'skill_panel',
      requiredAction: TutorialAction.useSkill,
      actionValidation: {'skillUsed': true},
      skippable: false,
      hintDelay: 5000,
    ),

    // 步驟 4：觀察效果
    TutorialStep(
      id: 'skill_4_effect',
      lesson: TutorialLesson.skill,
      title: '技能效果',
      description: '''
精彩！你成功使用了技能！

**注意觀察**
• 技能對目標的影響
• 自己消耗的資源
• 場上形勢的變化

技能可以在關鍵時刻扭轉戰局，
但也要注意不要過早暴露你的底牌！

恭喜完成第四課！你已經掌握了進階技巧。''',
      targetElement: null,
      requiredAction: TutorialAction.confirm,
      skippable: false,
      hintDelay: 3000,
      onCompleteData: {'lessonComplete': true},
    ),
  ];

  // ============================================================
  // 第五課：完成投票（3 步驟）
  // ============================================================

  static const List<TutorialStep> voteSteps = [
    // 步驟 1：理解投票選項
    TutorialStep(
      id: 'vote_1_options',
      lesson: TutorialLesson.vote,
      title: '投票選項',
      description: '''
現在進入最關鍵的投票階段！

**機器法案的三個選項**

🔨 A. 禁止機器
工人派支持，通過則工人派 +50 分

💰 B. 保護財產
資方派支持，通過則資方派 +50 分

📜 C. 折衷改革
改革派支持，通過則改革派 +30 分

選擇符合你陣營利益的選項！''',
      targetElement: 'vote_options',
      requiredAction: TutorialAction.confirm,
      skippable: false,
      hintDelay: 5000,
    ),

    // 步驟 2：投出你的一票
    TutorialStep(
      id: 'vote_2_cast',
      lesson: TutorialLesson.vote,
      title: '投下神聖的一票',
      description: '''
現在，請為你支持的選項投票！

**記住**
• 你的聲望決定投票權重
• 投票後無法更改
• 觀察其他玩家的動向

點擊你想支持的選項，然後確認投票。''',
      targetElement: 'vote_options',
      requiredAction: TutorialAction.castVote,
      actionValidation: {'voteSubmitted': true},
      skippable: false,
      hintDelay: 5000,
    ),

    // 步驟 3：查看結果
    TutorialStep(
      id: 'vote_3_result',
      lesson: TutorialLesson.vote,
      title: '見證歷史！',
      description: '''
投票已經結束！

讓我們看看最終結果...

**計票規則**
• 統計每個選項的加權票數
• 票數最高的選項獲勝
• 支持該選項的陣營獲得積分

🎉 恭喜你完成全部教學！

你已經學會了：
✓ 聲望與生存
✓ 質詢與反駁
✓ 使用角色技能
✓ 投票與勝利

現在你已準備好進入真正的 1812 國會了！''',
      targetElement: 'result_panel',
      requiredAction: TutorialAction.confirm,
      skippable: false,
      hintDelay: 3000,
      onCompleteData: {
        'lessonComplete': true,
        'tutorialComplete': true,
      },
    ),
  ];

  // ============================================================
  // 快速教學（精簡版，適合回顧）
  // ============================================================

  /// 獲取快速回顧教學步驟
  static List<TutorialStep> get quickRecapSteps => [
    const TutorialStep(
      id: 'recap_1_basics',
      lesson: TutorialLesson.introduction,
      title: '快速回顧：基礎',
      description: '''
**核心規則提醒**

聲望 = 生命值 + 投票權重
質詢 = 消耗 10，造成 15 傷害
反駁 = 消耗 5，抵消質詢

準備好開始遊戲了嗎？''',
      requiredAction: TutorialAction.confirm,
      skippable: true,
      hintDelay: 2000,
    ),
  ];

  /// 根據玩家進度推薦下一課
  static TutorialLesson? recommendNextLesson(TutorialProgress progress) {
    if (progress.isFullyCompleted) {
      return null; // 已完成全部
    }

    // 按順序返回第一個未完成的課程
    for (final lesson in TutorialLesson.values) {
      if (!progress.completedLessons.contains(lesson)) {
        return lesson;
      }
    }

    return null;
  }

  /// 獲取課程完成獎勵描述
  static String getLessonReward(TutorialLesson lesson) {
    switch (lesson) {
      case TutorialLesson.introduction:
        return '解鎖單人練習模式';
      case TutorialLesson.query:
        return '獲得「初出茅廬」稱號';
      case TutorialLesson.rebut:
        return '獲得「銅牆鐵壁」稱號';
      case TutorialLesson.skill:
        return '解鎖進階 AI 難度';
      case TutorialLesson.vote:
        return '解鎖多人對戰模式';
    }
  }
}
