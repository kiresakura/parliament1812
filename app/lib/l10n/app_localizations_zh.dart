// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '1812 國會風雲';

  @override
  String get appSubtitle => '國會風雲';

  @override
  String get appTagline => '政治角力與卡牌策略';

  @override
  String get appVersion => 'Parliament 1812 v1.0.0 — M6';

  @override
  String get splashSubtitle => 'PARLIAMENT CRISIS';

  @override
  String get splashTagline => '卡牌與謊言的政治遊戲';

  @override
  String get login => '登入';

  @override
  String get register => '註冊';

  @override
  String get logout => '登出';

  @override
  String get emailOrUsername => 'Email 或使用者名稱';

  @override
  String get password => '密碼';

  @override
  String get confirmPassword => '確認密碼';

  @override
  String get email => 'Email';

  @override
  String get username => '使用者名稱';

  @override
  String get usernameHint => '3-20 個字元';

  @override
  String get passwordHint => '至少 8 個字元';

  @override
  String get forgotPassword => '忘記密碼？';

  @override
  String get noAccount => '沒有帳號？';

  @override
  String get hasAccount => '已有帳號？';

  @override
  String get registerNow => '立即註冊';

  @override
  String get loginNow => '立即登入';

  @override
  String get guestMode => '以訪客身份進入';

  @override
  String get googleLogin => '使用 Google 登入';

  @override
  String get appleLogin => '使用 Apple 登入';

  @override
  String get or => '或';

  @override
  String get createAccount => '建立帳號';

  @override
  String get joinParliament => '加入國會';

  @override
  String get createIdentity => '建立你的議員身份';

  @override
  String get resetPassword => '重設密碼';

  @override
  String get resetPasswordDesc => '輸入您的 Email，我們將寄送密碼重設連結。';

  @override
  String get sendResetLink => '寄送重設連結';

  @override
  String get resetLinkSent => '已寄出重設連結';

  @override
  String get resetLinkSentDesc => '如果該 Email 已註冊，您將收到密碼重設指示。請檢查您的收件匣。';

  @override
  String get backToLogin => '返回登入';

  @override
  String get requestFailed => '請求失敗，請稍後再試';

  @override
  String get validationEmailRequired => '請輸入 Email 或使用者名稱';

  @override
  String get validationPasswordRequired => '請輸入密碼';

  @override
  String get validationEmailInvalid => 'Email 格式無效';

  @override
  String get validationUsernameRequired => '請輸入使用者名稱';

  @override
  String get validationUsernameMinLength => '使用者名稱至少 3 個字元';

  @override
  String get validationUsernameMaxLength => '使用者名稱最多 20 個字元';

  @override
  String get validationPasswordMinLength => '密碼至少 8 個字元';

  @override
  String get validationConfirmPasswordRequired => '請再次輸入密碼';

  @override
  String get validationPasswordMismatch => '密碼不一致';

  @override
  String get validationEmailFieldRequired => '請輸入 Email';

  @override
  String get quickMatch => '快速匹配';

  @override
  String get quickMatchDesc => '立即開始一局遊戲';

  @override
  String get roomList => '房間列表';

  @override
  String get roomListDesc => '加入或創建房間';

  @override
  String get leaderboard => '排行榜';

  @override
  String get leaderboardDesc => '查看全球排名與 ELO 評分';

  @override
  String get dailyQuests => '每日任務';

  @override
  String get dailyQuestsDesc => '完成任務獲取獎勵';

  @override
  String get cardCodex => '卡牌圖鑑';

  @override
  String get cardCodexDesc => '收藏圖鑑與成就系統';

  @override
  String get tutorial => '遊戲教學';

  @override
  String get tutorialDesc => '學習遊戲規則與策略';

  @override
  String get friends => '好友';

  @override
  String get friendsDesc => '管理好友與社交';

  @override
  String get settings => '設定';

  @override
  String get settingsComingSoon => '設定功能將在後續版本推出';

  @override
  String get settingsTitle => '設定';

  @override
  String get languageSettings => '語言設定';

  @override
  String get language => '語言';

  @override
  String get languageZhTW => '繁體中文';

  @override
  String get languageEn => 'English';

  @override
  String get languageZhCN => '简体中文';

  @override
  String get audioSettings => '音效設定';

  @override
  String get soundEffects => '音效';

  @override
  String get backgroundMusic => '背景音樂';

  @override
  String get accountSettings => '帳號管理';

  @override
  String get deleteAccount => '刪除帳號';

  @override
  String get deleteAccountConfirm => '確定要刪除帳號嗎？此操作無法撤銷。';

  @override
  String get aboutApp => '關於';

  @override
  String get version => '版本';

  @override
  String get globalRanking => '全球排行';

  @override
  String get myRanking => '我的排名';

  @override
  String get season => '賽季';

  @override
  String get switchSeason => '切換賽季';

  @override
  String get gamesPlayed => '場次';

  @override
  String get wins => '勝場';

  @override
  String get winRate => '勝率';

  @override
  String get eloRating => 'ELO';

  @override
  String get noRankingData => '本賽季尚無排名資料';

  @override
  String get notRankedYet => '尚未參與排名賽';

  @override
  String get playRankedToGetRank => '完成一場排名賽以獲得排名';

  @override
  String totalRanked(int count) {
    return '/ $count 人';
  }

  @override
  String get unranked => '未上榜';

  @override
  String matchCount(int count) {
    return '$count 場';
  }

  @override
  String winRatePercent(String rate) {
    return '勝率 $rate%';
  }

  @override
  String get allCards => '全部卡牌';

  @override
  String get myCollection => '我的收藏';

  @override
  String get achievements => '成就';

  @override
  String collectionProgress(int collected, int total) {
    return '$collected/$total';
  }

  @override
  String get filterAll => '全部';

  @override
  String get filterCommon => '普通';

  @override
  String get filterUncommon => '稀有';

  @override
  String get filterRare => '史詩';

  @override
  String get filterLegendary => '傳說';

  @override
  String get noCardsCollected => '尚未收藏任何卡牌';

  @override
  String get playToCollect => '完成對局即可獲得卡牌！';

  @override
  String get noAchievementData => '尚無成就資料';

  @override
  String achievementsCompleted(int completed, int total) {
    return '$completed/$total 已完成';
  }

  @override
  String pendingClaim(int count) {
    return '$count 待領取';
  }

  @override
  String get claim => '領取';

  @override
  String get claimReward => '領取獎勵';

  @override
  String get claimed => '已領取';

  @override
  String get claimable => '可領取';

  @override
  String get hiddenAchievement => '🏆 ???';

  @override
  String get hiddenAchievementDesc => '隱藏成就 — 達成特殊條件解鎖';

  @override
  String get rewards => '獎勵';

  @override
  String get difficultyEasy => '🟢 簡單';

  @override
  String get difficultyMedium => '🟡 中等';

  @override
  String get difficultyHard => '🔴 困難';

  @override
  String get difficultyHidden => '🟣 隱藏';

  @override
  String get unlockCondition => '解鎖條件';

  @override
  String influenceCost(int cost) {
    return '影響力消耗：$cost';
  }

  @override
  String effectValue(int value) {
    return '效果值：$value';
  }

  @override
  String exclusiveRole(String role) {
    return '專屬角色：$role';
  }

  @override
  String get questResetCountdown => '重置倒數';

  @override
  String get resetSoon => '即將重置...';

  @override
  String get retry => '重試';

  @override
  String streakDays(int days) {
    return '連續 $days 天';
  }

  @override
  String longestStreak(int days) {
    return '最長紀錄：$days 天';
  }

  @override
  String streakMilestone(int count) {
    return '🎉 ${count}x7 天';
  }

  @override
  String get allCompletedBonus => '全完成獎勵';

  @override
  String get allCompletedBonusDesc => '完成所有任務！領取任務即可獲得額外 10 寶石';

  @override
  String allCompletedBonusProgress(int completed, int total) {
    return '完成所有 $total 個任務可額外獲得 10 寶石（$completed/$total）';
  }

  @override
  String roundN(int round) {
    return '第$round回合';
  }

  @override
  String handCards(int count) {
    return '手牌: $count';
  }

  @override
  String get noHandCards => '暫無手牌';

  @override
  String get phaseConspiracy => '密謀階段';

  @override
  String get phaseDebate => '辯論階段';

  @override
  String get phaseVoting => '投票階段';

  @override
  String get phaseResult => '結果階段';

  @override
  String get phasePreparing => '準備中';

  @override
  String get conspiracySubtitle => '策劃你的行動';

  @override
  String get debateSubtitle => '展開激烈的政治攻防';

  @override
  String get votingSubtitle => '決定議案的命運';

  @override
  String get resultSubtitle => '統計投票結果';

  @override
  String get gameInProgress => '遊戲進行中';

  @override
  String get loadingGame => '載入遊戲中...';

  @override
  String get currentBill => '當前議案';

  @override
  String get noBill => '暫無議案';

  @override
  String get waitingForBill => '等待議案';

  @override
  String get eventLog => '事件日誌';

  @override
  String get chat => '聊天';

  @override
  String get chatInputHint => '輸入訊息...';

  @override
  String get investigate => '調查';

  @override
  String get formAlliance => '結盟';

  @override
  String get bribe => '賄賂';

  @override
  String get interrogate => '質詢';

  @override
  String get rebut => '反駁';

  @override
  String get skill => '技能';

  @override
  String get support => '支持';

  @override
  String get oppose => '反對';

  @override
  String get abstain => '棄權';

  @override
  String get waiting => '等待中';

  @override
  String useCard(String name) {
    return '使用卡牌: $name';
  }

  @override
  String get gameSettings => '遊戲設定';

  @override
  String get soundEffect => '音效';

  @override
  String get gameRules => '遊戲規則';

  @override
  String get leaveGame => '離開遊戲';

  @override
  String get leaveGameConfirm => '確定要離開遊戲嗎？遊戲進度將會遺失。';

  @override
  String get cancel => '取消';

  @override
  String get leave => '離開';

  @override
  String get close => '關閉';

  @override
  String get confirm => '確定';

  @override
  String get copy => '複製';

  @override
  String get share => '分享';

  @override
  String get quickMessage1 => '好手段！';

  @override
  String get quickMessage2 => '結盟？';

  @override
  String get quickMessage3 => '你完了。';

  @override
  String get quickMessage4 => '投我一票';

  @override
  String get quickMessage5 => '有意思...';

  @override
  String get quickMessage6 => '我同意。';

  @override
  String get billEffectPreview => '投票效果預覽';

  @override
  String get billEffectPending => '投票效果將在議案確定後顯示';

  @override
  String get billFactoryAct => '《工廠法案》';

  @override
  String get billFactoryActDesc => '限制工廠工時，改善勞工待遇。';

  @override
  String get billPressLaw => '《新聞審查法》';

  @override
  String get billPressLawDesc => '限制新聞自由，控制輿論傳播。';

  @override
  String get billCornLaw => '《穀物法廢除》';

  @override
  String get billCornLawDesc => '廢除穀物進口關稅，降低糧食價格。';

  @override
  String get billAssemblyLaw => '《結社自由法》';

  @override
  String get billAssemblyLawDesc => '允許工人組織工會和政治團體。';

  @override
  String get billReformAct => '《選舉改革法》';

  @override
  String get billReformActDesc => '擴大選舉權，改革議會選舉制度。';

  @override
  String get billDetailPending => '議案詳情待定...';

  @override
  String get victory => '大獲全勝！';

  @override
  String get defeat => '政治失敗';

  @override
  String get victorySubtitle => '在這場政治角力中表現卓越！';

  @override
  String get defeatSubtitle => '政治是一門藝術，下次會更好。';

  @override
  String get finalRanking => '最終排名';

  @override
  String get mvp => 'MVP';

  @override
  String get gameStats => '遊戲統計';

  @override
  String get cardsUsed => '使用卡牌數';

  @override
  String get damageDealt => '造成傷害';

  @override
  String get damageTaken => '受到傷害';

  @override
  String get voteWinRate => '投票勝率';

  @override
  String get gameDuration => '遊戲時長';

  @override
  String get playAgain => '再來一局';

  @override
  String get backToMenu => '返回主選單';

  @override
  String get reputation => '聲望';

  @override
  String reputationColon(int value) {
    return '聲望: $value';
  }

  @override
  String get score => '分數';

  @override
  String nCards(String count) {
    return '$count 張';
  }

  @override
  String nPoints(String count) {
    return '$count 點';
  }

  @override
  String get createRoom => '創建房間';

  @override
  String get joinRoom => '加入房間';

  @override
  String get roomCode => '房間代碼';

  @override
  String get roomCodeHint => '輸入 6 位房間代碼';

  @override
  String get roomName => '房間名稱';

  @override
  String get roomNameHint => '輸入房間名稱';

  @override
  String get maxPlayers => '最大玩家數：';

  @override
  String nPlayers(int count) {
    return '$count 人';
  }

  @override
  String get privateRoom => '私人房間';

  @override
  String get privateRoomDesc => '需要密碼才能加入';

  @override
  String get roomPassword => '房間密碼';

  @override
  String get roomPasswordHint => '輸入房間密碼';

  @override
  String get passwordOptional => '密碼（如需要）';

  @override
  String get create => '創建';

  @override
  String get join => '加入';

  @override
  String get statusFilter => '狀態篩選';

  @override
  String get filterStatusAll => '全部';

  @override
  String get filterStatusWaiting => '等待中';

  @override
  String get filterStatusPlaying => '遊戲中';

  @override
  String get searchRoom => '搜尋房間';

  @override
  String get noRoomsAvailable => '尚無可用房間';

  @override
  String get createRoomPrompt => '創建一個新房間開始遊戲吧！';

  @override
  String get roomCodeCopied => '房間代碼已複製到剪貼簿';

  @override
  String cannotJoin(String status) {
    return '無法加入：$status';
  }

  @override
  String get roomFull => '房間已滿';

  @override
  String get roomCreateComingSoon => '房間創建功能將在後續版本實現';

  @override
  String get roomSettingsComingSoon => '房間設定功能將在後續版本實現';

  @override
  String get kickPlayerComingSoon => '踢出玩家功能將在後續版本實現';

  @override
  String get readyComingSoon => '準備功能將在後續版本實現';

  @override
  String get players => '玩家';

  @override
  String get playerList => '玩家列表';

  @override
  String get inviteFriend => '邀請好友';

  @override
  String get inviteShareCode => '分享房間代碼給好友：';

  @override
  String get leaveRoom => '離開房間';

  @override
  String get leaveRoomConfirm => '確定要離開房間嗎？';

  @override
  String get startGame => '開始遊戲';

  @override
  String get canStartGame => '可以開始遊戲';

  @override
  String get ready => '準備';

  @override
  String get cancelReady => '取消準備';

  @override
  String get isReady => '已準備';

  @override
  String get notReady => '未準備';

  @override
  String get roomSettings => '房間設定';

  @override
  String get kickPlayer => '踢出玩家';

  @override
  String kickPlayerConfirm(String name) {
    return '確定要踢出 $name 嗎？';
  }

  @override
  String get kick => '踢出';

  @override
  String get host => '房主';

  @override
  String get noCharacterSelected => '未選角色';

  @override
  String characterSelected(String name) {
    return '選擇了角色：$name';
  }

  @override
  String get alreadyTaken => '已被選擇';

  @override
  String get characterThomas => '湯瑪斯';

  @override
  String get characterThomasFull => '工人湯瑪斯';

  @override
  String get characterThomasDesc => '工人領袖\n團結技能：盟友越多，防禦越強';

  @override
  String get characterRichard => '理查';

  @override
  String get characterRichardFull => '工廠主理查';

  @override
  String get characterRichardDesc => '工廠主\n收買技能：用金幣讓對手沉默';

  @override
  String get characterEdward => '愛德華';

  @override
  String get characterEdwardFull => '記者愛德華';

  @override
  String get characterEdwardDesc => '記者\n爆料技能：揭露對手秘密';

  @override
  String get characterGeorge => '喬治';

  @override
  String get characterGeorgeFull => '盧德派喬治';

  @override
  String get characterGeorgeDesc => '盧德派\n怒火技能：造成雙倍傷害';

  @override
  String get unknownCharacter => '未知';

  @override
  String get unknownRole => '未知角色';

  @override
  String get tutorialIntroTitle => '遊戲簡介';

  @override
  String get tutorialIntroContent =>
      '1812 國會風雲是一款以英國國會為背景的卡牌策略遊戲。4 名玩家分別扮演不同陣營的角色，透過質詢、辯論、結盟與投票，爭奪政治影響力。';

  @override
  String get tutorialFlowTitle => '遊戲流程';

  @override
  String get tutorialFlowContent =>
      '每回合分為三個階段：\n\n🤝 密謀階段（120秒）\n私下協商，決定結盟或背叛。\n\n⚔️ 辯論階段（300秒）\n出卡攻擊、防禦、使用技能。消耗影響力和金幣。\n\n🗳️ 投票階段（60秒）\n對當回合議案投支持或反對票。';

  @override
  String get tutorialCardsTitle => '卡牌系統';

  @override
  String get tutorialCardsContent =>
      '開局發 6 張手牌，每回合自動抽 1 張。\n\n🗡️ 攻擊卡 — 對目標造成聲望傷害\n🛡️ 防禦卡 — 抵消攻擊\n🔧 功能卡 — 恢復聲望或特殊效果\n⭐ 專屬卡 — 角色獨有的強力卡牌';

  @override
  String get tutorialCharactersTitle => '角色介紹';

  @override
  String get tutorialCharactersContent =>
      '🔨 工人湯瑪斯 — 初始聲望 70，技能：團結\n🏭 工廠主理查 — 初始聲望 60，技能：收買\n📰 記者愛德華 — 初始聲望 50，技能：爆料\n🔥 盧德派喬治 — 初始聲望 80，技能：怒火';

  @override
  String get tutorialVictoryTitle => '勝利條件';

  @override
  String get tutorialVictoryContent =>
      '聲望歸零 = 政治死亡（淘汰）。\n存活到最後、聲望最高的玩家獲勝。\n投票結果會影響所有人的聲望和資源。';

  @override
  String get cardTypeAttack => '攻擊';

  @override
  String get cardTypeDefense => '防禦';

  @override
  String get cardTypeUtility => '功能';

  @override
  String get cardTypeSignature => '專屬';

  @override
  String get addFriend => '新增好友';

  @override
  String get friendIdHint => '輸入好友 ID';

  @override
  String get sendRequest => '發送邀請';

  @override
  String get friendRequestSent => '已發送';

  @override
  String get removeFriend => '移除好友';

  @override
  String removeFriendConfirm(String name) {
    return '確定要移除好友 $name 嗎？';
  }

  @override
  String get online => '線上';

  @override
  String get offline => '離線';

  @override
  String get inGame => '遊戲中';

  @override
  String get noFriendsYet => '還沒有好友';

  @override
  String get addFriendPrompt => '新增好友開始社交吧！';

  @override
  String get connectionConnected => '已連線';

  @override
  String get connectionDisconnected => '已斷線';

  @override
  String get connectionConnecting => '連線中...';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get appTitle => '1812 国会风云';

  @override
  String get appSubtitle => '国会风云';

  @override
  String get appTagline => '政治角力与卡牌策略';

  @override
  String get appVersion => 'Parliament 1812 v1.0.0 — M6';

  @override
  String get splashSubtitle => 'PARLIAMENT CRISIS';

  @override
  String get splashTagline => '卡牌与谎言的政治游戏';

  @override
  String get login => '登录';

  @override
  String get register => '注册';

  @override
  String get logout => '登出';

  @override
  String get emailOrUsername => 'Email 或用户名';

  @override
  String get password => '密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get email => 'Email';

  @override
  String get username => '用户名';

  @override
  String get usernameHint => '3-20 个字符';

  @override
  String get passwordHint => '至少 8 个字符';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get noAccount => '没有账号？';

  @override
  String get hasAccount => '已有账号？';

  @override
  String get registerNow => '立即注册';

  @override
  String get loginNow => '立即登录';

  @override
  String get guestMode => '以访客身份进入';

  @override
  String get googleLogin => '使用 Google 登录';

  @override
  String get appleLogin => '使用 Apple 登录';

  @override
  String get or => '或';

  @override
  String get createAccount => '创建账号';

  @override
  String get joinParliament => '加入国会';

  @override
  String get createIdentity => '创建你的议员身份';

  @override
  String get resetPassword => '重设密码';

  @override
  String get resetPasswordDesc => '输入您的 Email，我们将发送密码重设链接。';

  @override
  String get sendResetLink => '发送重设链接';

  @override
  String get resetLinkSent => '已发出重设链接';

  @override
  String get resetLinkSentDesc => '如果该 Email 已注册，您将收到密码重设指示。请检查您的收件箱。';

  @override
  String get backToLogin => '返回登录';

  @override
  String get requestFailed => '请求失败，请稍后再试';

  @override
  String get validationEmailRequired => '请输入 Email 或用户名';

  @override
  String get validationPasswordRequired => '请输入密码';

  @override
  String get validationEmailInvalid => 'Email 格式无效';

  @override
  String get validationUsernameRequired => '请输入用户名';

  @override
  String get validationUsernameMinLength => '用户名至少 3 个字符';

  @override
  String get validationUsernameMaxLength => '用户名最多 20 个字符';

  @override
  String get validationPasswordMinLength => '密码至少 8 个字符';

  @override
  String get validationConfirmPasswordRequired => '请再次输入密码';

  @override
  String get validationPasswordMismatch => '密码不一致';

  @override
  String get validationEmailFieldRequired => '请输入 Email';

  @override
  String get quickMatch => '快速匹配';

  @override
  String get quickMatchDesc => '立即开始一局游戏';

  @override
  String get roomList => '房间列表';

  @override
  String get roomListDesc => '加入或创建房间';

  @override
  String get leaderboard => '排行榜';

  @override
  String get leaderboardDesc => '查看全球排名与 ELO 评分';

  @override
  String get dailyQuests => '每日任务';

  @override
  String get dailyQuestsDesc => '完成任务获取奖励';

  @override
  String get cardCodex => '卡牌图鉴';

  @override
  String get cardCodexDesc => '收藏图鉴与成就系统';

  @override
  String get tutorial => '游戏教学';

  @override
  String get tutorialDesc => '学习游戏规则与策略';

  @override
  String get friends => '好友';

  @override
  String get friendsDesc => '管理好友与社交';

  @override
  String get settings => '设定';

  @override
  String get settingsComingSoon => '设定功能将在后续版本推出';

  @override
  String get settingsTitle => '设定';

  @override
  String get languageSettings => '语言设定';

  @override
  String get language => '语言';

  @override
  String get languageZhTW => '繁體中文';

  @override
  String get languageEn => 'English';

  @override
  String get languageZhCN => '简体中文';

  @override
  String get audioSettings => '音效设定';

  @override
  String get soundEffects => '音效';

  @override
  String get backgroundMusic => '背景音乐';

  @override
  String get accountSettings => '账号管理';

  @override
  String get deleteAccount => '删除账号';

  @override
  String get deleteAccountConfirm => '确定要删除账号吗？此操作无法撤销。';

  @override
  String get aboutApp => '关于';

  @override
  String get version => '版本';

  @override
  String get globalRanking => '全球排行';

  @override
  String get myRanking => '我的排名';

  @override
  String get season => '赛季';

  @override
  String get switchSeason => '切换赛季';

  @override
  String get gamesPlayed => '场次';

  @override
  String get wins => '胜场';

  @override
  String get winRate => '胜率';

  @override
  String get eloRating => 'ELO';

  @override
  String get noRankingData => '本赛季尚无排名资料';

  @override
  String get notRankedYet => '尚未参与排名赛';

  @override
  String get playRankedToGetRank => '完成一场排名赛以获得排名';

  @override
  String totalRanked(int count) {
    return '/ $count 人';
  }

  @override
  String get unranked => '未上榜';

  @override
  String matchCount(int count) {
    return '$count 场';
  }

  @override
  String winRatePercent(String rate) {
    return '胜率 $rate%';
  }

  @override
  String get allCards => '全部卡牌';

  @override
  String get myCollection => '我的收藏';

  @override
  String get achievements => '成就';

  @override
  String collectionProgress(int collected, int total) {
    return '$collected/$total';
  }

  @override
  String get filterAll => '全部';

  @override
  String get filterCommon => '普通';

  @override
  String get filterUncommon => '稀有';

  @override
  String get filterRare => '史诗';

  @override
  String get filterLegendary => '传说';

  @override
  String get noCardsCollected => '尚未收藏任何卡牌';

  @override
  String get playToCollect => '完成对局即可获得卡牌！';

  @override
  String get noAchievementData => '尚无成就资料';

  @override
  String achievementsCompleted(int completed, int total) {
    return '$completed/$total 已完成';
  }

  @override
  String pendingClaim(int count) {
    return '$count 待领取';
  }

  @override
  String get claim => '领取';

  @override
  String get claimReward => '领取奖励';

  @override
  String get claimed => '已领取';

  @override
  String get claimable => '可领取';

  @override
  String get hiddenAchievement => '🏆 ???';

  @override
  String get hiddenAchievementDesc => '隐藏成就 — 达成特殊条件解锁';

  @override
  String get rewards => '奖励';

  @override
  String get difficultyEasy => '🟢 简单';

  @override
  String get difficultyMedium => '🟡 中等';

  @override
  String get difficultyHard => '🔴 困难';

  @override
  String get difficultyHidden => '🟣 隐藏';

  @override
  String get unlockCondition => '解锁条件';

  @override
  String influenceCost(int cost) {
    return '影响力消耗：$cost';
  }

  @override
  String effectValue(int value) {
    return '效果值：$value';
  }

  @override
  String exclusiveRole(String role) {
    return '专属角色：$role';
  }

  @override
  String get questResetCountdown => '重置倒数';

  @override
  String get resetSoon => '即将重置...';

  @override
  String get retry => '重试';

  @override
  String streakDays(int days) {
    return '连续 $days 天';
  }

  @override
  String longestStreak(int days) {
    return '最长纪录：$days 天';
  }

  @override
  String streakMilestone(int count) {
    return '🎉 ${count}x7 天';
  }

  @override
  String get allCompletedBonus => '全完成奖励';

  @override
  String get allCompletedBonusDesc => '完成所有任务！领取任务即可获得额外 10 宝石';

  @override
  String allCompletedBonusProgress(int completed, int total) {
    return '完成所有 $total 个任务可额外获得 10 宝石（$completed/$total）';
  }

  @override
  String roundN(int round) {
    return '第$round回合';
  }

  @override
  String handCards(int count) {
    return '手牌: $count';
  }

  @override
  String get noHandCards => '暂无手牌';

  @override
  String get phaseConspiracy => '密谋阶段';

  @override
  String get phaseDebate => '辩论阶段';

  @override
  String get phaseVoting => '投票阶段';

  @override
  String get phaseResult => '结果阶段';

  @override
  String get phasePreparing => '准备中';

  @override
  String get conspiracySubtitle => '策划你的行动';

  @override
  String get debateSubtitle => '展开激烈的政治攻防';

  @override
  String get votingSubtitle => '决定议案的命运';

  @override
  String get resultSubtitle => '统计投票结果';

  @override
  String get gameInProgress => '游戏进行中';

  @override
  String get loadingGame => '载入游戏中...';

  @override
  String get currentBill => '当前议案';

  @override
  String get noBill => '暂无议案';

  @override
  String get waitingForBill => '等待议案';

  @override
  String get eventLog => '事件日志';

  @override
  String get chat => '聊天';

  @override
  String get chatInputHint => '输入讯息...';

  @override
  String get investigate => '调查';

  @override
  String get formAlliance => '结盟';

  @override
  String get bribe => '贿赂';

  @override
  String get interrogate => '质询';

  @override
  String get rebut => '反驳';

  @override
  String get skill => '技能';

  @override
  String get support => '支持';

  @override
  String get oppose => '反对';

  @override
  String get abstain => '弃权';

  @override
  String get waiting => '等待中';

  @override
  String useCard(String name) {
    return '使用卡牌: $name';
  }

  @override
  String get gameSettings => '游戏设定';

  @override
  String get soundEffect => '音效';

  @override
  String get gameRules => '游戏规则';

  @override
  String get leaveGame => '离开游戏';

  @override
  String get leaveGameConfirm => '确定要离开游戏吗？游戏进度将会丢失。';

  @override
  String get cancel => '取消';

  @override
  String get leave => '离开';

  @override
  String get close => '关闭';

  @override
  String get confirm => '确定';

  @override
  String get copy => '复制';

  @override
  String get share => '分享';

  @override
  String get quickMessage1 => '好手段！';

  @override
  String get quickMessage2 => '结盟？';

  @override
  String get quickMessage3 => '你完了。';

  @override
  String get quickMessage4 => '投我一票';

  @override
  String get quickMessage5 => '有意思...';

  @override
  String get quickMessage6 => '我同意。';

  @override
  String get billEffectPreview => '投票效果预览';

  @override
  String get billEffectPending => '投票效果将在议案确定后显示';

  @override
  String get billFactoryAct => '《工厂法案》';

  @override
  String get billFactoryActDesc => '限制工厂工时，改善劳工待遇。';

  @override
  String get billPressLaw => '《新闻审查法》';

  @override
  String get billPressLawDesc => '限制新闻自由，控制舆论传播。';

  @override
  String get billCornLaw => '《谷物法废除》';

  @override
  String get billCornLawDesc => '废除谷物进口关税，降低粮食价格。';

  @override
  String get billAssemblyLaw => '《结社自由法》';

  @override
  String get billAssemblyLawDesc => '允许工人组织工会和政治团体。';

  @override
  String get billReformAct => '《选举改革法》';

  @override
  String get billReformActDesc => '扩大选举权，改革议会选举制度。';

  @override
  String get billDetailPending => '议案详情待定...';

  @override
  String get victory => '大获全胜！';

  @override
  String get defeat => '政治失败';

  @override
  String get victorySubtitle => '在这场政治角力中表现卓越！';

  @override
  String get defeatSubtitle => '政治是一门艺术，下次会更好。';

  @override
  String get finalRanking => '最终排名';

  @override
  String get mvp => 'MVP';

  @override
  String get gameStats => '游戏统计';

  @override
  String get cardsUsed => '使用卡牌数';

  @override
  String get damageDealt => '造成伤害';

  @override
  String get damageTaken => '受到伤害';

  @override
  String get voteWinRate => '投票胜率';

  @override
  String get gameDuration => '游戏时长';

  @override
  String get playAgain => '再来一局';

  @override
  String get backToMenu => '返回主菜单';

  @override
  String get reputation => '声望';

  @override
  String reputationColon(int value) {
    return '声望: $value';
  }

  @override
  String get score => '分数';

  @override
  String nCards(String count) {
    return '$count 张';
  }

  @override
  String nPoints(String count) {
    return '$count 点';
  }

  @override
  String get createRoom => '创建房间';

  @override
  String get joinRoom => '加入房间';

  @override
  String get roomCode => '房间代码';

  @override
  String get roomCodeHint => '输入 6 位房间代码';

  @override
  String get roomName => '房间名称';

  @override
  String get roomNameHint => '输入房间名称';

  @override
  String get maxPlayers => '最大玩家数：';

  @override
  String nPlayers(int count) {
    return '$count 人';
  }

  @override
  String get privateRoom => '私人房间';

  @override
  String get privateRoomDesc => '需要密码才能加入';

  @override
  String get roomPassword => '房间密码';

  @override
  String get roomPasswordHint => '输入房间密码';

  @override
  String get passwordOptional => '密码（如需要）';

  @override
  String get create => '创建';

  @override
  String get join => '加入';

  @override
  String get statusFilter => '状态筛选';

  @override
  String get filterStatusAll => '全部';

  @override
  String get filterStatusWaiting => '等待中';

  @override
  String get filterStatusPlaying => '游戏中';

  @override
  String get searchRoom => '搜索房间';

  @override
  String get noRoomsAvailable => '尚无可用房间';

  @override
  String get createRoomPrompt => '创建一个新房间开始游戏吧！';

  @override
  String get roomCodeCopied => '房间代码已复制到剪贴板';

  @override
  String cannotJoin(String status) {
    return '无法加入：$status';
  }

  @override
  String get roomFull => '房间已满';

  @override
  String get roomCreateComingSoon => '房间创建功能将在后续版本实现';

  @override
  String get roomSettingsComingSoon => '房间设定功能将在后续版本实现';

  @override
  String get kickPlayerComingSoon => '踢出玩家功能将在后续版本实现';

  @override
  String get readyComingSoon => '准备功能将在后续版本实现';

  @override
  String get players => '玩家';

  @override
  String get playerList => '玩家列表';

  @override
  String get inviteFriend => '邀请好友';

  @override
  String get inviteShareCode => '分享房间代码给好友：';

  @override
  String get leaveRoom => '离开房间';

  @override
  String get leaveRoomConfirm => '确定要离开房间吗？';

  @override
  String get startGame => '开始游戏';

  @override
  String get canStartGame => '可以开始游戏';

  @override
  String get ready => '准备';

  @override
  String get cancelReady => '取消准备';

  @override
  String get isReady => '已准备';

  @override
  String get notReady => '未准备';

  @override
  String get roomSettings => '房间设定';

  @override
  String get kickPlayer => '踢出玩家';

  @override
  String kickPlayerConfirm(String name) {
    return '确定要踢出 $name 吗？';
  }

  @override
  String get kick => '踢出';

  @override
  String get host => '房主';

  @override
  String get noCharacterSelected => '未选角色';

  @override
  String characterSelected(String name) {
    return '选择了角色：$name';
  }

  @override
  String get alreadyTaken => '已被选择';

  @override
  String get characterThomas => '汤玛斯';

  @override
  String get characterThomasFull => '工人汤玛斯';

  @override
  String get characterThomasDesc => '工人领袖\n团结技能：盟友越多，防御越强';

  @override
  String get characterRichard => '理查';

  @override
  String get characterRichardFull => '工厂主理查';

  @override
  String get characterRichardDesc => '工厂主\n收买技能：用金币让对手沉默';

  @override
  String get characterEdward => '爱德华';

  @override
  String get characterEdwardFull => '记者爱德华';

  @override
  String get characterEdwardDesc => '记者\n爆料技能：揭露对手秘密';

  @override
  String get characterGeorge => '乔治';

  @override
  String get characterGeorgeFull => '卢德派乔治';

  @override
  String get characterGeorgeDesc => '卢德派\n怒火技能：造成双倍伤害';

  @override
  String get unknownCharacter => '未知';

  @override
  String get unknownRole => '未知角色';

  @override
  String get tutorialIntroTitle => '游戏简介';

  @override
  String get tutorialIntroContent =>
      '1812 国会风云是一款以英国国会为背景的卡牌策略游戏。4 名玩家分别扮演不同阵营的角色，透过质询、辩论、结盟与投票，争夺政治影响力。';

  @override
  String get tutorialFlowTitle => '游戏流程';

  @override
  String get tutorialFlowContent =>
      '每回合分为三个阶段：\n\n🤝 密谋阶段（120秒）\n私下协商，决定结盟或背叛。\n\n⚔️ 辩论阶段（300秒）\n出卡攻击、防御、使用技能。消耗影响力和金币。\n\n🗳️ 投票阶段（60秒）\n对当回合议案投支持或反对票。';

  @override
  String get tutorialCardsTitle => '卡牌系统';

  @override
  String get tutorialCardsContent =>
      '开局发 6 张手牌，每回合自动抽 1 张。\n\n🗡️ 攻击卡 — 对目标造成声望伤害\n🛡️ 防御卡 — 抵消攻击\n🔧 功能卡 — 恢复声望或特殊效果\n⭐ 专属卡 — 角色独有的强力卡牌';

  @override
  String get tutorialCharactersTitle => '角色介绍';

  @override
  String get tutorialCharactersContent =>
      '🔨 工人汤玛斯 — 初始声望 70，技能：团结\n🏭 工厂主理查 — 初始声望 60，技能：收买\n📰 记者爱德华 — 初始声望 50，技能：爆料\n🔥 卢德派乔治 — 初始声望 80，技能：怒火';

  @override
  String get tutorialVictoryTitle => '胜利条件';

  @override
  String get tutorialVictoryContent =>
      '声望归零 = 政治死亡（淘汰）。\n存活到最后、声望最高的玩家获胜。\n投票结果会影响所有人的声望和资源。';

  @override
  String get cardTypeAttack => '攻击';

  @override
  String get cardTypeDefense => '防御';

  @override
  String get cardTypeUtility => '功能';

  @override
  String get cardTypeSignature => '专属';

  @override
  String get addFriend => '新增好友';

  @override
  String get friendIdHint => '输入好友 ID';

  @override
  String get sendRequest => '发送邀请';

  @override
  String get friendRequestSent => '已发送';

  @override
  String get removeFriend => '移除好友';

  @override
  String removeFriendConfirm(String name) {
    return '确定要移除好友 $name 吗？';
  }

  @override
  String get online => '在线';

  @override
  String get offline => '离线';

  @override
  String get inGame => '游戏中';

  @override
  String get noFriendsYet => '还没有好友';

  @override
  String get addFriendPrompt => '新增好友开始社交吧！';

  @override
  String get connectionConnected => '已连线';

  @override
  String get connectionDisconnected => '已断线';

  @override
  String get connectionConnecting => '连线中...';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => '1812 國會風雲';

  @override
  String get appSubtitle => '國會風雲';

  @override
  String get appTagline => '政治角力與卡牌策略';

  @override
  String get appVersion => 'Parliament 1812 v1.0.0 — M6';

  @override
  String get splashSubtitle => 'PARLIAMENT CRISIS';

  @override
  String get splashTagline => '卡牌與謊言的政治遊戲';

  @override
  String get login => '登入';

  @override
  String get register => '註冊';

  @override
  String get logout => '登出';

  @override
  String get emailOrUsername => 'Email 或使用者名稱';

  @override
  String get password => '密碼';

  @override
  String get confirmPassword => '確認密碼';

  @override
  String get email => 'Email';

  @override
  String get username => '使用者名稱';

  @override
  String get usernameHint => '3-20 個字元';

  @override
  String get passwordHint => '至少 8 個字元';

  @override
  String get forgotPassword => '忘記密碼？';

  @override
  String get noAccount => '沒有帳號？';

  @override
  String get hasAccount => '已有帳號？';

  @override
  String get registerNow => '立即註冊';

  @override
  String get loginNow => '立即登入';

  @override
  String get guestMode => '以訪客身份進入';

  @override
  String get googleLogin => '使用 Google 登入';

  @override
  String get appleLogin => '使用 Apple 登入';

  @override
  String get or => '或';

  @override
  String get createAccount => '建立帳號';

  @override
  String get joinParliament => '加入國會';

  @override
  String get createIdentity => '建立你的議員身份';

  @override
  String get resetPassword => '重設密碼';

  @override
  String get resetPasswordDesc => '輸入您的 Email，我們將寄送密碼重設連結。';

  @override
  String get sendResetLink => '寄送重設連結';

  @override
  String get resetLinkSent => '已寄出重設連結';

  @override
  String get resetLinkSentDesc => '如果該 Email 已註冊，您將收到密碼重設指示。請檢查您的收件匣。';

  @override
  String get backToLogin => '返回登入';

  @override
  String get requestFailed => '請求失敗，請稍後再試';

  @override
  String get validationEmailRequired => '請輸入 Email 或使用者名稱';

  @override
  String get validationPasswordRequired => '請輸入密碼';

  @override
  String get validationEmailInvalid => 'Email 格式無效';

  @override
  String get validationUsernameRequired => '請輸入使用者名稱';

  @override
  String get validationUsernameMinLength => '使用者名稱至少 3 個字元';

  @override
  String get validationUsernameMaxLength => '使用者名稱最多 20 個字元';

  @override
  String get validationPasswordMinLength => '密碼至少 8 個字元';

  @override
  String get validationConfirmPasswordRequired => '請再次輸入密碼';

  @override
  String get validationPasswordMismatch => '密碼不一致';

  @override
  String get validationEmailFieldRequired => '請輸入 Email';

  @override
  String get quickMatch => '快速匹配';

  @override
  String get quickMatchDesc => '立即開始一局遊戲';

  @override
  String get roomList => '房間列表';

  @override
  String get roomListDesc => '加入或創建房間';

  @override
  String get leaderboard => '排行榜';

  @override
  String get leaderboardDesc => '查看全球排名與 ELO 評分';

  @override
  String get dailyQuests => '每日任務';

  @override
  String get dailyQuestsDesc => '完成任務獲取獎勵';

  @override
  String get cardCodex => '卡牌圖鑑';

  @override
  String get cardCodexDesc => '收藏圖鑑與成就系統';

  @override
  String get tutorial => '遊戲教學';

  @override
  String get tutorialDesc => '學習遊戲規則與策略';

  @override
  String get friends => '好友';

  @override
  String get friendsDesc => '管理好友與社交';

  @override
  String get settings => '設定';

  @override
  String get settingsComingSoon => '設定功能將在後續版本推出';

  @override
  String get settingsTitle => '設定';

  @override
  String get languageSettings => '語言設定';

  @override
  String get language => '語言';

  @override
  String get languageZhTW => '繁體中文';

  @override
  String get languageEn => 'English';

  @override
  String get languageZhCN => '简体中文';

  @override
  String get audioSettings => '音效設定';

  @override
  String get soundEffects => '音效';

  @override
  String get backgroundMusic => '背景音樂';

  @override
  String get accountSettings => '帳號管理';

  @override
  String get deleteAccount => '刪除帳號';

  @override
  String get deleteAccountConfirm => '確定要刪除帳號嗎？此操作無法撤銷。';

  @override
  String get aboutApp => '關於';

  @override
  String get version => '版本';

  @override
  String get globalRanking => '全球排行';

  @override
  String get myRanking => '我的排名';

  @override
  String get season => '賽季';

  @override
  String get switchSeason => '切換賽季';

  @override
  String get gamesPlayed => '場次';

  @override
  String get wins => '勝場';

  @override
  String get winRate => '勝率';

  @override
  String get eloRating => 'ELO';

  @override
  String get noRankingData => '本賽季尚無排名資料';

  @override
  String get notRankedYet => '尚未參與排名賽';

  @override
  String get playRankedToGetRank => '完成一場排名賽以獲得排名';

  @override
  String totalRanked(int count) {
    return '/ $count 人';
  }

  @override
  String get unranked => '未上榜';

  @override
  String matchCount(int count) {
    return '$count 場';
  }

  @override
  String winRatePercent(String rate) {
    return '勝率 $rate%';
  }

  @override
  String get allCards => '全部卡牌';

  @override
  String get myCollection => '我的收藏';

  @override
  String get achievements => '成就';

  @override
  String collectionProgress(int collected, int total) {
    return '$collected/$total';
  }

  @override
  String get filterAll => '全部';

  @override
  String get filterCommon => '普通';

  @override
  String get filterUncommon => '稀有';

  @override
  String get filterRare => '史詩';

  @override
  String get filterLegendary => '傳說';

  @override
  String get noCardsCollected => '尚未收藏任何卡牌';

  @override
  String get playToCollect => '完成對局即可獲得卡牌！';

  @override
  String get noAchievementData => '尚無成就資料';

  @override
  String achievementsCompleted(int completed, int total) {
    return '$completed/$total 已完成';
  }

  @override
  String pendingClaim(int count) {
    return '$count 待領取';
  }

  @override
  String get claim => '領取';

  @override
  String get claimReward => '領取獎勵';

  @override
  String get claimed => '已領取';

  @override
  String get claimable => '可領取';

  @override
  String get hiddenAchievement => '🏆 ???';

  @override
  String get hiddenAchievementDesc => '隱藏成就 — 達成特殊條件解鎖';

  @override
  String get rewards => '獎勵';

  @override
  String get difficultyEasy => '🟢 簡單';

  @override
  String get difficultyMedium => '🟡 中等';

  @override
  String get difficultyHard => '🔴 困難';

  @override
  String get difficultyHidden => '🟣 隱藏';

  @override
  String get unlockCondition => '解鎖條件';

  @override
  String influenceCost(int cost) {
    return '影響力消耗：$cost';
  }

  @override
  String effectValue(int value) {
    return '效果值：$value';
  }

  @override
  String exclusiveRole(String role) {
    return '專屬角色：$role';
  }

  @override
  String get questResetCountdown => '重置倒數';

  @override
  String get resetSoon => '即將重置...';

  @override
  String get retry => '重試';

  @override
  String streakDays(int days) {
    return '連續 $days 天';
  }

  @override
  String longestStreak(int days) {
    return '最長紀錄：$days 天';
  }

  @override
  String streakMilestone(int count) {
    return '🎉 ${count}x7 天';
  }

  @override
  String get allCompletedBonus => '全完成獎勵';

  @override
  String get allCompletedBonusDesc => '完成所有任務！領取任務即可獲得額外 10 寶石';

  @override
  String allCompletedBonusProgress(int completed, int total) {
    return '完成所有 $total 個任務可額外獲得 10 寶石（$completed/$total）';
  }

  @override
  String roundN(int round) {
    return '第$round回合';
  }

  @override
  String handCards(int count) {
    return '手牌: $count';
  }

  @override
  String get noHandCards => '暫無手牌';

  @override
  String get phaseConspiracy => '密謀階段';

  @override
  String get phaseDebate => '辯論階段';

  @override
  String get phaseVoting => '投票階段';

  @override
  String get phaseResult => '結果階段';

  @override
  String get phasePreparing => '準備中';

  @override
  String get conspiracySubtitle => '策劃你的行動';

  @override
  String get debateSubtitle => '展開激烈的政治攻防';

  @override
  String get votingSubtitle => '決定議案的命運';

  @override
  String get resultSubtitle => '統計投票結果';

  @override
  String get gameInProgress => '遊戲進行中';

  @override
  String get loadingGame => '載入遊戲中...';

  @override
  String get currentBill => '當前議案';

  @override
  String get noBill => '暫無議案';

  @override
  String get waitingForBill => '等待議案';

  @override
  String get eventLog => '事件日誌';

  @override
  String get chat => '聊天';

  @override
  String get chatInputHint => '輸入訊息...';

  @override
  String get investigate => '調查';

  @override
  String get formAlliance => '結盟';

  @override
  String get bribe => '賄賂';

  @override
  String get interrogate => '質詢';

  @override
  String get rebut => '反駁';

  @override
  String get skill => '技能';

  @override
  String get support => '支持';

  @override
  String get oppose => '反對';

  @override
  String get abstain => '棄權';

  @override
  String get waiting => '等待中';

  @override
  String useCard(String name) {
    return '使用卡牌: $name';
  }

  @override
  String get gameSettings => '遊戲設定';

  @override
  String get soundEffect => '音效';

  @override
  String get gameRules => '遊戲規則';

  @override
  String get leaveGame => '離開遊戲';

  @override
  String get leaveGameConfirm => '確定要離開遊戲嗎？遊戲進度將會遺失。';

  @override
  String get cancel => '取消';

  @override
  String get leave => '離開';

  @override
  String get close => '關閉';

  @override
  String get confirm => '確定';

  @override
  String get copy => '複製';

  @override
  String get share => '分享';

  @override
  String get quickMessage1 => '好手段！';

  @override
  String get quickMessage2 => '結盟？';

  @override
  String get quickMessage3 => '你完了。';

  @override
  String get quickMessage4 => '投我一票';

  @override
  String get quickMessage5 => '有意思...';

  @override
  String get quickMessage6 => '我同意。';

  @override
  String get billEffectPreview => '投票效果預覽';

  @override
  String get billEffectPending => '投票效果將在議案確定後顯示';

  @override
  String get billFactoryAct => '《工廠法案》';

  @override
  String get billFactoryActDesc => '限制工廠工時，改善勞工待遇。';

  @override
  String get billPressLaw => '《新聞審查法》';

  @override
  String get billPressLawDesc => '限制新聞自由，控制輿論傳播。';

  @override
  String get billCornLaw => '《穀物法廢除》';

  @override
  String get billCornLawDesc => '廢除穀物進口關稅，降低糧食價格。';

  @override
  String get billAssemblyLaw => '《結社自由法》';

  @override
  String get billAssemblyLawDesc => '允許工人組織工會和政治團體。';

  @override
  String get billReformAct => '《選舉改革法》';

  @override
  String get billReformActDesc => '擴大選舉權，改革議會選舉制度。';

  @override
  String get billDetailPending => '議案詳情待定...';

  @override
  String get victory => '大獲全勝！';

  @override
  String get defeat => '政治失敗';

  @override
  String get victorySubtitle => '在這場政治角力中表現卓越！';

  @override
  String get defeatSubtitle => '政治是一門藝術，下次會更好。';

  @override
  String get finalRanking => '最終排名';

  @override
  String get mvp => 'MVP';

  @override
  String get gameStats => '遊戲統計';

  @override
  String get cardsUsed => '使用卡牌數';

  @override
  String get damageDealt => '造成傷害';

  @override
  String get damageTaken => '受到傷害';

  @override
  String get voteWinRate => '投票勝率';

  @override
  String get gameDuration => '遊戲時長';

  @override
  String get playAgain => '再來一局';

  @override
  String get backToMenu => '返回主選單';

  @override
  String get reputation => '聲望';

  @override
  String reputationColon(int value) {
    return '聲望: $value';
  }

  @override
  String get score => '分數';

  @override
  String nCards(String count) {
    return '$count 張';
  }

  @override
  String nPoints(String count) {
    return '$count 點';
  }

  @override
  String get createRoom => '創建房間';

  @override
  String get joinRoom => '加入房間';

  @override
  String get roomCode => '房間代碼';

  @override
  String get roomCodeHint => '輸入 6 位房間代碼';

  @override
  String get roomName => '房間名稱';

  @override
  String get roomNameHint => '輸入房間名稱';

  @override
  String get maxPlayers => '最大玩家數：';

  @override
  String nPlayers(int count) {
    return '$count 人';
  }

  @override
  String get privateRoom => '私人房間';

  @override
  String get privateRoomDesc => '需要密碼才能加入';

  @override
  String get roomPassword => '房間密碼';

  @override
  String get roomPasswordHint => '輸入房間密碼';

  @override
  String get passwordOptional => '密碼（如需要）';

  @override
  String get create => '創建';

  @override
  String get join => '加入';

  @override
  String get statusFilter => '狀態篩選';

  @override
  String get filterStatusAll => '全部';

  @override
  String get filterStatusWaiting => '等待中';

  @override
  String get filterStatusPlaying => '遊戲中';

  @override
  String get searchRoom => '搜尋房間';

  @override
  String get noRoomsAvailable => '尚無可用房間';

  @override
  String get createRoomPrompt => '創建一個新房間開始遊戲吧！';

  @override
  String get roomCodeCopied => '房間代碼已複製到剪貼簿';

  @override
  String cannotJoin(String status) {
    return '無法加入：$status';
  }

  @override
  String get roomFull => '房間已滿';

  @override
  String get roomCreateComingSoon => '房間創建功能將在後續版本實現';

  @override
  String get roomSettingsComingSoon => '房間設定功能將在後續版本實現';

  @override
  String get kickPlayerComingSoon => '踢出玩家功能將在後續版本實現';

  @override
  String get readyComingSoon => '準備功能將在後續版本實現';

  @override
  String get players => '玩家';

  @override
  String get playerList => '玩家列表';

  @override
  String get inviteFriend => '邀請好友';

  @override
  String get inviteShareCode => '分享房間代碼給好友：';

  @override
  String get leaveRoom => '離開房間';

  @override
  String get leaveRoomConfirm => '確定要離開房間嗎？';

  @override
  String get startGame => '開始遊戲';

  @override
  String get canStartGame => '可以開始遊戲';

  @override
  String get ready => '準備';

  @override
  String get cancelReady => '取消準備';

  @override
  String get isReady => '已準備';

  @override
  String get notReady => '未準備';

  @override
  String get roomSettings => '房間設定';

  @override
  String get kickPlayer => '踢出玩家';

  @override
  String kickPlayerConfirm(String name) {
    return '確定要踢出 $name 嗎？';
  }

  @override
  String get kick => '踢出';

  @override
  String get host => '房主';

  @override
  String get noCharacterSelected => '未選角色';

  @override
  String characterSelected(String name) {
    return '選擇了角色：$name';
  }

  @override
  String get alreadyTaken => '已被選擇';

  @override
  String get characterThomas => '湯瑪斯';

  @override
  String get characterThomasFull => '工人湯瑪斯';

  @override
  String get characterThomasDesc => '工人領袖\n團結技能：盟友越多，防禦越強';

  @override
  String get characterRichard => '理查';

  @override
  String get characterRichardFull => '工廠主理查';

  @override
  String get characterRichardDesc => '工廠主\n收買技能：用金幣讓對手沉默';

  @override
  String get characterEdward => '愛德華';

  @override
  String get characterEdwardFull => '記者愛德華';

  @override
  String get characterEdwardDesc => '記者\n爆料技能：揭露對手秘密';

  @override
  String get characterGeorge => '喬治';

  @override
  String get characterGeorgeFull => '盧德派喬治';

  @override
  String get characterGeorgeDesc => '盧德派\n怒火技能：造成雙倍傷害';

  @override
  String get unknownCharacter => '未知';

  @override
  String get unknownRole => '未知角色';

  @override
  String get tutorialIntroTitle => '遊戲簡介';

  @override
  String get tutorialIntroContent =>
      '1812 國會風雲是一款以英國國會為背景的卡牌策略遊戲。4 名玩家分別扮演不同陣營的角色，透過質詢、辯論、結盟與投票，爭奪政治影響力。';

  @override
  String get tutorialFlowTitle => '遊戲流程';

  @override
  String get tutorialFlowContent =>
      '每回合分為三個階段：\n\n🤝 密謀階段（120秒）\n私下協商，決定結盟或背叛。\n\n⚔️ 辯論階段（300秒）\n出卡攻擊、防禦、使用技能。消耗影響力和金幣。\n\n🗳️ 投票階段（60秒）\n對當回合議案投支持或反對票。';

  @override
  String get tutorialCardsTitle => '卡牌系統';

  @override
  String get tutorialCardsContent =>
      '開局發 6 張手牌，每回合自動抽 1 張。\n\n🗡️ 攻擊卡 — 對目標造成聲望傷害\n🛡️ 防禦卡 — 抵消攻擊\n🔧 功能卡 — 恢復聲望或特殊效果\n⭐ 專屬卡 — 角色獨有的強力卡牌';

  @override
  String get tutorialCharactersTitle => '角色介紹';

  @override
  String get tutorialCharactersContent =>
      '🔨 工人湯瑪斯 — 初始聲望 70，技能：團結\n🏭 工廠主理查 — 初始聲望 60，技能：收買\n📰 記者愛德華 — 初始聲望 50，技能：爆料\n🔥 盧德派喬治 — 初始聲望 80，技能：怒火';

  @override
  String get tutorialVictoryTitle => '勝利條件';

  @override
  String get tutorialVictoryContent =>
      '聲望歸零 = 政治死亡（淘汰）。\n存活到最後、聲望最高的玩家獲勝。\n投票結果會影響所有人的聲望和資源。';

  @override
  String get cardTypeAttack => '攻擊';

  @override
  String get cardTypeDefense => '防禦';

  @override
  String get cardTypeUtility => '功能';

  @override
  String get cardTypeSignature => '專屬';

  @override
  String get addFriend => '新增好友';

  @override
  String get friendIdHint => '輸入好友 ID';

  @override
  String get sendRequest => '發送邀請';

  @override
  String get friendRequestSent => '已發送';

  @override
  String get removeFriend => '移除好友';

  @override
  String removeFriendConfirm(String name) {
    return '確定要移除好友 $name 嗎？';
  }

  @override
  String get online => '線上';

  @override
  String get offline => '離線';

  @override
  String get inGame => '遊戲中';

  @override
  String get noFriendsYet => '還沒有好友';

  @override
  String get addFriendPrompt => '新增好友開始社交吧！';

  @override
  String get connectionConnected => '已連線';

  @override
  String get connectionDisconnected => '已斷線';

  @override
  String get connectionConnecting => '連線中...';
}
