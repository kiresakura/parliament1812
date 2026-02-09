import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'1812 國會風雲'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'國會風雲'**
  String get appSubtitle;

  /// No description provided for @appTagline.
  ///
  /// In zh_TW, this message translates to:
  /// **'政治角力與卡牌策略'**
  String get appTagline;

  /// No description provided for @appVersion.
  ///
  /// In zh_TW, this message translates to:
  /// **'Parliament 1812 v1.0.0 — M6'**
  String get appVersion;

  /// No description provided for @splashSubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'PARLIAMENT CRISIS'**
  String get splashSubtitle;

  /// No description provided for @splashTagline.
  ///
  /// In zh_TW, this message translates to:
  /// **'卡牌與謊言的政治遊戲'**
  String get splashTagline;

  /// No description provided for @login.
  ///
  /// In zh_TW, this message translates to:
  /// **'登入'**
  String get login;

  /// No description provided for @register.
  ///
  /// In zh_TW, this message translates to:
  /// **'註冊'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In zh_TW, this message translates to:
  /// **'登出'**
  String get logout;

  /// No description provided for @emailOrUsername.
  ///
  /// In zh_TW, this message translates to:
  /// **'Email 或使用者名稱'**
  String get emailOrUsername;

  /// No description provided for @password.
  ///
  /// In zh_TW, this message translates to:
  /// **'密碼'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In zh_TW, this message translates to:
  /// **'確認密碼'**
  String get confirmPassword;

  /// No description provided for @email.
  ///
  /// In zh_TW, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @username.
  ///
  /// In zh_TW, this message translates to:
  /// **'使用者名稱'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'3-20 個字元'**
  String get usernameHint;

  /// No description provided for @passwordHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'至少 8 個字元'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In zh_TW, this message translates to:
  /// **'忘記密碼？'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In zh_TW, this message translates to:
  /// **'沒有帳號？'**
  String get noAccount;

  /// No description provided for @hasAccount.
  ///
  /// In zh_TW, this message translates to:
  /// **'已有帳號？'**
  String get hasAccount;

  /// No description provided for @registerNow.
  ///
  /// In zh_TW, this message translates to:
  /// **'立即註冊'**
  String get registerNow;

  /// No description provided for @loginNow.
  ///
  /// In zh_TW, this message translates to:
  /// **'立即登入'**
  String get loginNow;

  /// No description provided for @guestMode.
  ///
  /// In zh_TW, this message translates to:
  /// **'以訪客身份進入'**
  String get guestMode;

  /// No description provided for @googleLogin.
  ///
  /// In zh_TW, this message translates to:
  /// **'使用 Google 登入'**
  String get googleLogin;

  /// No description provided for @appleLogin.
  ///
  /// In zh_TW, this message translates to:
  /// **'使用 Apple 登入'**
  String get appleLogin;

  /// No description provided for @or.
  ///
  /// In zh_TW, this message translates to:
  /// **'或'**
  String get or;

  /// No description provided for @createAccount.
  ///
  /// In zh_TW, this message translates to:
  /// **'建立帳號'**
  String get createAccount;

  /// No description provided for @joinParliament.
  ///
  /// In zh_TW, this message translates to:
  /// **'加入國會'**
  String get joinParliament;

  /// No description provided for @createIdentity.
  ///
  /// In zh_TW, this message translates to:
  /// **'建立你的議員身份'**
  String get createIdentity;

  /// No description provided for @resetPassword.
  ///
  /// In zh_TW, this message translates to:
  /// **'重設密碼'**
  String get resetPassword;

  /// No description provided for @resetPasswordDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'輸入您的 Email，我們將寄送密碼重設連結。'**
  String get resetPasswordDesc;

  /// No description provided for @sendResetLink.
  ///
  /// In zh_TW, this message translates to:
  /// **'寄送重設連結'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In zh_TW, this message translates to:
  /// **'已寄出重設連結'**
  String get resetLinkSent;

  /// No description provided for @resetLinkSentDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'如果該 Email 已註冊，您將收到密碼重設指示。請檢查您的收件匣。'**
  String get resetLinkSentDesc;

  /// No description provided for @backToLogin.
  ///
  /// In zh_TW, this message translates to:
  /// **'返回登入'**
  String get backToLogin;

  /// No description provided for @requestFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'請求失敗，請稍後再試'**
  String get requestFailed;

  /// No description provided for @validationEmailRequired.
  ///
  /// In zh_TW, this message translates to:
  /// **'請輸入 Email 或使用者名稱'**
  String get validationEmailRequired;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In zh_TW, this message translates to:
  /// **'請輸入密碼'**
  String get validationPasswordRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In zh_TW, this message translates to:
  /// **'Email 格式無效'**
  String get validationEmailInvalid;

  /// No description provided for @validationUsernameRequired.
  ///
  /// In zh_TW, this message translates to:
  /// **'請輸入使用者名稱'**
  String get validationUsernameRequired;

  /// No description provided for @validationUsernameMinLength.
  ///
  /// In zh_TW, this message translates to:
  /// **'使用者名稱至少 3 個字元'**
  String get validationUsernameMinLength;

  /// No description provided for @validationUsernameMaxLength.
  ///
  /// In zh_TW, this message translates to:
  /// **'使用者名稱最多 20 個字元'**
  String get validationUsernameMaxLength;

  /// No description provided for @validationPasswordMinLength.
  ///
  /// In zh_TW, this message translates to:
  /// **'密碼至少 8 個字元'**
  String get validationPasswordMinLength;

  /// No description provided for @validationConfirmPasswordRequired.
  ///
  /// In zh_TW, this message translates to:
  /// **'請再次輸入密碼'**
  String get validationConfirmPasswordRequired;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In zh_TW, this message translates to:
  /// **'密碼不一致'**
  String get validationPasswordMismatch;

  /// No description provided for @validationEmailFieldRequired.
  ///
  /// In zh_TW, this message translates to:
  /// **'請輸入 Email'**
  String get validationEmailFieldRequired;

  /// No description provided for @quickMatch.
  ///
  /// In zh_TW, this message translates to:
  /// **'快速匹配'**
  String get quickMatch;

  /// No description provided for @quickMatchDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'立即開始一局遊戲'**
  String get quickMatchDesc;

  /// No description provided for @roomList.
  ///
  /// In zh_TW, this message translates to:
  /// **'房間列表'**
  String get roomList;

  /// No description provided for @roomListDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'加入或創建房間'**
  String get roomListDesc;

  /// No description provided for @leaderboard.
  ///
  /// In zh_TW, this message translates to:
  /// **'排行榜'**
  String get leaderboard;

  /// No description provided for @leaderboardDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'查看全球排名與 ELO 評分'**
  String get leaderboardDesc;

  /// No description provided for @dailyQuests.
  ///
  /// In zh_TW, this message translates to:
  /// **'每日任務'**
  String get dailyQuests;

  /// No description provided for @dailyQuestsDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'完成任務獲取獎勵'**
  String get dailyQuestsDesc;

  /// No description provided for @cardCodex.
  ///
  /// In zh_TW, this message translates to:
  /// **'卡牌圖鑑'**
  String get cardCodex;

  /// No description provided for @cardCodexDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'收藏圖鑑與成就系統'**
  String get cardCodexDesc;

  /// No description provided for @tutorial.
  ///
  /// In zh_TW, this message translates to:
  /// **'遊戲教學'**
  String get tutorial;

  /// No description provided for @tutorialDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'學習遊戲規則與策略'**
  String get tutorialDesc;

  /// No description provided for @friends.
  ///
  /// In zh_TW, this message translates to:
  /// **'好友'**
  String get friends;

  /// No description provided for @friendsDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'管理好友與社交'**
  String get friendsDesc;

  /// No description provided for @settings.
  ///
  /// In zh_TW, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @settingsComingSoon.
  ///
  /// In zh_TW, this message translates to:
  /// **'設定功能將在後續版本推出'**
  String get settingsComingSoon;

  /// No description provided for @settingsTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'設定'**
  String get settingsTitle;

  /// No description provided for @languageSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'語言設定'**
  String get languageSettings;

  /// No description provided for @language.
  ///
  /// In zh_TW, this message translates to:
  /// **'語言'**
  String get language;

  /// No description provided for @languageZhTW.
  ///
  /// In zh_TW, this message translates to:
  /// **'繁體中文'**
  String get languageZhTW;

  /// No description provided for @languageEn.
  ///
  /// In zh_TW, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageZhCN.
  ///
  /// In zh_TW, this message translates to:
  /// **'简体中文'**
  String get languageZhCN;

  /// No description provided for @audioSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'音效設定'**
  String get audioSettings;

  /// No description provided for @soundEffects.
  ///
  /// In zh_TW, this message translates to:
  /// **'音效'**
  String get soundEffects;

  /// No description provided for @backgroundMusic.
  ///
  /// In zh_TW, this message translates to:
  /// **'背景音樂'**
  String get backgroundMusic;

  /// No description provided for @accountSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'帳號管理'**
  String get accountSettings;

  /// No description provided for @deleteAccount.
  ///
  /// In zh_TW, this message translates to:
  /// **'刪除帳號'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'確定要刪除帳號嗎？此操作無法撤銷。'**
  String get deleteAccountConfirm;

  /// No description provided for @aboutApp.
  ///
  /// In zh_TW, this message translates to:
  /// **'關於'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In zh_TW, this message translates to:
  /// **'版本'**
  String get version;

  /// No description provided for @globalRanking.
  ///
  /// In zh_TW, this message translates to:
  /// **'全球排行'**
  String get globalRanking;

  /// No description provided for @myRanking.
  ///
  /// In zh_TW, this message translates to:
  /// **'我的排名'**
  String get myRanking;

  /// No description provided for @season.
  ///
  /// In zh_TW, this message translates to:
  /// **'賽季'**
  String get season;

  /// No description provided for @switchSeason.
  ///
  /// In zh_TW, this message translates to:
  /// **'切換賽季'**
  String get switchSeason;

  /// No description provided for @gamesPlayed.
  ///
  /// In zh_TW, this message translates to:
  /// **'場次'**
  String get gamesPlayed;

  /// No description provided for @wins.
  ///
  /// In zh_TW, this message translates to:
  /// **'勝場'**
  String get wins;

  /// No description provided for @winRate.
  ///
  /// In zh_TW, this message translates to:
  /// **'勝率'**
  String get winRate;

  /// No description provided for @eloRating.
  ///
  /// In zh_TW, this message translates to:
  /// **'ELO'**
  String get eloRating;

  /// No description provided for @noRankingData.
  ///
  /// In zh_TW, this message translates to:
  /// **'本賽季尚無排名資料'**
  String get noRankingData;

  /// No description provided for @notRankedYet.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚未參與排名賽'**
  String get notRankedYet;

  /// No description provided for @playRankedToGetRank.
  ///
  /// In zh_TW, this message translates to:
  /// **'完成一場排名賽以獲得排名'**
  String get playRankedToGetRank;

  /// No description provided for @totalRanked.
  ///
  /// In zh_TW, this message translates to:
  /// **'/ {count} 人'**
  String totalRanked(int count);

  /// No description provided for @unranked.
  ///
  /// In zh_TW, this message translates to:
  /// **'未上榜'**
  String get unranked;

  /// No description provided for @matchCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 場'**
  String matchCount(int count);

  /// No description provided for @winRatePercent.
  ///
  /// In zh_TW, this message translates to:
  /// **'勝率 {rate}%'**
  String winRatePercent(String rate);

  /// No description provided for @allCards.
  ///
  /// In zh_TW, this message translates to:
  /// **'全部卡牌'**
  String get allCards;

  /// No description provided for @myCollection.
  ///
  /// In zh_TW, this message translates to:
  /// **'我的收藏'**
  String get myCollection;

  /// No description provided for @achievements.
  ///
  /// In zh_TW, this message translates to:
  /// **'成就'**
  String get achievements;

  /// No description provided for @collectionProgress.
  ///
  /// In zh_TW, this message translates to:
  /// **'{collected}/{total}'**
  String collectionProgress(int collected, int total);

  /// No description provided for @filterAll.
  ///
  /// In zh_TW, this message translates to:
  /// **'全部'**
  String get filterAll;

  /// No description provided for @filterCommon.
  ///
  /// In zh_TW, this message translates to:
  /// **'普通'**
  String get filterCommon;

  /// No description provided for @filterUncommon.
  ///
  /// In zh_TW, this message translates to:
  /// **'稀有'**
  String get filterUncommon;

  /// No description provided for @filterRare.
  ///
  /// In zh_TW, this message translates to:
  /// **'史詩'**
  String get filterRare;

  /// No description provided for @filterLegendary.
  ///
  /// In zh_TW, this message translates to:
  /// **'傳說'**
  String get filterLegendary;

  /// No description provided for @noCardsCollected.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚未收藏任何卡牌'**
  String get noCardsCollected;

  /// No description provided for @playToCollect.
  ///
  /// In zh_TW, this message translates to:
  /// **'完成對局即可獲得卡牌！'**
  String get playToCollect;

  /// No description provided for @noAchievementData.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚無成就資料'**
  String get noAchievementData;

  /// No description provided for @achievementsCompleted.
  ///
  /// In zh_TW, this message translates to:
  /// **'{completed}/{total} 已完成'**
  String achievementsCompleted(int completed, int total);

  /// No description provided for @pendingClaim.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 待領取'**
  String pendingClaim(int count);

  /// No description provided for @claim.
  ///
  /// In zh_TW, this message translates to:
  /// **'領取'**
  String get claim;

  /// No description provided for @claimReward.
  ///
  /// In zh_TW, this message translates to:
  /// **'領取獎勵'**
  String get claimReward;

  /// No description provided for @claimed.
  ///
  /// In zh_TW, this message translates to:
  /// **'已領取'**
  String get claimed;

  /// No description provided for @claimable.
  ///
  /// In zh_TW, this message translates to:
  /// **'可領取'**
  String get claimable;

  /// No description provided for @hiddenAchievement.
  ///
  /// In zh_TW, this message translates to:
  /// **'🏆 ???'**
  String get hiddenAchievement;

  /// No description provided for @hiddenAchievementDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'隱藏成就 — 達成特殊條件解鎖'**
  String get hiddenAchievementDesc;

  /// No description provided for @rewards.
  ///
  /// In zh_TW, this message translates to:
  /// **'獎勵'**
  String get rewards;

  /// No description provided for @difficultyEasy.
  ///
  /// In zh_TW, this message translates to:
  /// **'🟢 簡單'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In zh_TW, this message translates to:
  /// **'🟡 中等'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In zh_TW, this message translates to:
  /// **'🔴 困難'**
  String get difficultyHard;

  /// No description provided for @difficultyHidden.
  ///
  /// In zh_TW, this message translates to:
  /// **'🟣 隱藏'**
  String get difficultyHidden;

  /// No description provided for @unlockCondition.
  ///
  /// In zh_TW, this message translates to:
  /// **'解鎖條件'**
  String get unlockCondition;

  /// No description provided for @influenceCost.
  ///
  /// In zh_TW, this message translates to:
  /// **'影響力消耗：{cost}'**
  String influenceCost(int cost);

  /// No description provided for @effectValue.
  ///
  /// In zh_TW, this message translates to:
  /// **'效果值：{value}'**
  String effectValue(int value);

  /// No description provided for @exclusiveRole.
  ///
  /// In zh_TW, this message translates to:
  /// **'專屬角色：{role}'**
  String exclusiveRole(String role);

  /// No description provided for @questResetCountdown.
  ///
  /// In zh_TW, this message translates to:
  /// **'重置倒數'**
  String get questResetCountdown;

  /// No description provided for @resetSoon.
  ///
  /// In zh_TW, this message translates to:
  /// **'即將重置...'**
  String get resetSoon;

  /// No description provided for @retry.
  ///
  /// In zh_TW, this message translates to:
  /// **'重試'**
  String get retry;

  /// No description provided for @streakDays.
  ///
  /// In zh_TW, this message translates to:
  /// **'連續 {days} 天'**
  String streakDays(int days);

  /// No description provided for @longestStreak.
  ///
  /// In zh_TW, this message translates to:
  /// **'最長紀錄：{days} 天'**
  String longestStreak(int days);

  /// No description provided for @streakMilestone.
  ///
  /// In zh_TW, this message translates to:
  /// **'🎉 {count}x7 天'**
  String streakMilestone(int count);

  /// No description provided for @allCompletedBonus.
  ///
  /// In zh_TW, this message translates to:
  /// **'全完成獎勵'**
  String get allCompletedBonus;

  /// No description provided for @allCompletedBonusDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'完成所有任務！領取任務即可獲得額外 10 寶石'**
  String get allCompletedBonusDesc;

  /// No description provided for @allCompletedBonusProgress.
  ///
  /// In zh_TW, this message translates to:
  /// **'完成所有 {total} 個任務可額外獲得 10 寶石（{completed}/{total}）'**
  String allCompletedBonusProgress(int completed, int total);

  /// No description provided for @roundN.
  ///
  /// In zh_TW, this message translates to:
  /// **'第{round}回合'**
  String roundN(int round);

  /// No description provided for @handCards.
  ///
  /// In zh_TW, this message translates to:
  /// **'手牌: {count}'**
  String handCards(int count);

  /// No description provided for @noHandCards.
  ///
  /// In zh_TW, this message translates to:
  /// **'暫無手牌'**
  String get noHandCards;

  /// No description provided for @phaseConspiracy.
  ///
  /// In zh_TW, this message translates to:
  /// **'密謀階段'**
  String get phaseConspiracy;

  /// No description provided for @phaseDebate.
  ///
  /// In zh_TW, this message translates to:
  /// **'辯論階段'**
  String get phaseDebate;

  /// No description provided for @phaseVoting.
  ///
  /// In zh_TW, this message translates to:
  /// **'投票階段'**
  String get phaseVoting;

  /// No description provided for @phaseResult.
  ///
  /// In zh_TW, this message translates to:
  /// **'結果階段'**
  String get phaseResult;

  /// No description provided for @phasePreparing.
  ///
  /// In zh_TW, this message translates to:
  /// **'準備中'**
  String get phasePreparing;

  /// No description provided for @conspiracySubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'策劃你的行動'**
  String get conspiracySubtitle;

  /// No description provided for @debateSubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'展開激烈的政治攻防'**
  String get debateSubtitle;

  /// No description provided for @votingSubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'決定議案的命運'**
  String get votingSubtitle;

  /// No description provided for @resultSubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'統計投票結果'**
  String get resultSubtitle;

  /// No description provided for @gameInProgress.
  ///
  /// In zh_TW, this message translates to:
  /// **'遊戲進行中'**
  String get gameInProgress;

  /// No description provided for @loadingGame.
  ///
  /// In zh_TW, this message translates to:
  /// **'載入遊戲中...'**
  String get loadingGame;

  /// No description provided for @currentBill.
  ///
  /// In zh_TW, this message translates to:
  /// **'當前議案'**
  String get currentBill;

  /// No description provided for @noBill.
  ///
  /// In zh_TW, this message translates to:
  /// **'暫無議案'**
  String get noBill;

  /// No description provided for @waitingForBill.
  ///
  /// In zh_TW, this message translates to:
  /// **'等待議案'**
  String get waitingForBill;

  /// No description provided for @eventLog.
  ///
  /// In zh_TW, this message translates to:
  /// **'事件日誌'**
  String get eventLog;

  /// No description provided for @chat.
  ///
  /// In zh_TW, this message translates to:
  /// **'聊天'**
  String get chat;

  /// No description provided for @chatInputHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'輸入訊息...'**
  String get chatInputHint;

  /// No description provided for @investigate.
  ///
  /// In zh_TW, this message translates to:
  /// **'調查'**
  String get investigate;

  /// No description provided for @formAlliance.
  ///
  /// In zh_TW, this message translates to:
  /// **'結盟'**
  String get formAlliance;

  /// No description provided for @bribe.
  ///
  /// In zh_TW, this message translates to:
  /// **'賄賂'**
  String get bribe;

  /// No description provided for @interrogate.
  ///
  /// In zh_TW, this message translates to:
  /// **'質詢'**
  String get interrogate;

  /// No description provided for @rebut.
  ///
  /// In zh_TW, this message translates to:
  /// **'反駁'**
  String get rebut;

  /// No description provided for @skill.
  ///
  /// In zh_TW, this message translates to:
  /// **'技能'**
  String get skill;

  /// No description provided for @support.
  ///
  /// In zh_TW, this message translates to:
  /// **'支持'**
  String get support;

  /// No description provided for @oppose.
  ///
  /// In zh_TW, this message translates to:
  /// **'反對'**
  String get oppose;

  /// No description provided for @abstain.
  ///
  /// In zh_TW, this message translates to:
  /// **'棄權'**
  String get abstain;

  /// No description provided for @waiting.
  ///
  /// In zh_TW, this message translates to:
  /// **'等待中'**
  String get waiting;

  /// No description provided for @useCard.
  ///
  /// In zh_TW, this message translates to:
  /// **'使用卡牌: {name}'**
  String useCard(String name);

  /// No description provided for @gameSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'遊戲設定'**
  String get gameSettings;

  /// No description provided for @soundEffect.
  ///
  /// In zh_TW, this message translates to:
  /// **'音效'**
  String get soundEffect;

  /// No description provided for @gameRules.
  ///
  /// In zh_TW, this message translates to:
  /// **'遊戲規則'**
  String get gameRules;

  /// No description provided for @leaveGame.
  ///
  /// In zh_TW, this message translates to:
  /// **'離開遊戲'**
  String get leaveGame;

  /// No description provided for @leaveGameConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'確定要離開遊戲嗎？遊戲進度將會遺失。'**
  String get leaveGameConfirm;

  /// No description provided for @cancel.
  ///
  /// In zh_TW, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @leave.
  ///
  /// In zh_TW, this message translates to:
  /// **'離開'**
  String get leave;

  /// No description provided for @close.
  ///
  /// In zh_TW, this message translates to:
  /// **'關閉'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'確定'**
  String get confirm;

  /// No description provided for @copy.
  ///
  /// In zh_TW, this message translates to:
  /// **'複製'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In zh_TW, this message translates to:
  /// **'分享'**
  String get share;

  /// No description provided for @quickMessage1.
  ///
  /// In zh_TW, this message translates to:
  /// **'好手段！'**
  String get quickMessage1;

  /// No description provided for @quickMessage2.
  ///
  /// In zh_TW, this message translates to:
  /// **'結盟？'**
  String get quickMessage2;

  /// No description provided for @quickMessage3.
  ///
  /// In zh_TW, this message translates to:
  /// **'你完了。'**
  String get quickMessage3;

  /// No description provided for @quickMessage4.
  ///
  /// In zh_TW, this message translates to:
  /// **'投我一票'**
  String get quickMessage4;

  /// No description provided for @quickMessage5.
  ///
  /// In zh_TW, this message translates to:
  /// **'有意思...'**
  String get quickMessage5;

  /// No description provided for @quickMessage6.
  ///
  /// In zh_TW, this message translates to:
  /// **'我同意。'**
  String get quickMessage6;

  /// No description provided for @billEffectPreview.
  ///
  /// In zh_TW, this message translates to:
  /// **'投票效果預覽'**
  String get billEffectPreview;

  /// No description provided for @billEffectPending.
  ///
  /// In zh_TW, this message translates to:
  /// **'投票效果將在議案確定後顯示'**
  String get billEffectPending;

  /// No description provided for @billFactoryAct.
  ///
  /// In zh_TW, this message translates to:
  /// **'《工廠法案》'**
  String get billFactoryAct;

  /// No description provided for @billFactoryActDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'限制工廠工時，改善勞工待遇。'**
  String get billFactoryActDesc;

  /// No description provided for @billPressLaw.
  ///
  /// In zh_TW, this message translates to:
  /// **'《新聞審查法》'**
  String get billPressLaw;

  /// No description provided for @billPressLawDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'限制新聞自由，控制輿論傳播。'**
  String get billPressLawDesc;

  /// No description provided for @billCornLaw.
  ///
  /// In zh_TW, this message translates to:
  /// **'《穀物法廢除》'**
  String get billCornLaw;

  /// No description provided for @billCornLawDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'廢除穀物進口關稅，降低糧食價格。'**
  String get billCornLawDesc;

  /// No description provided for @billAssemblyLaw.
  ///
  /// In zh_TW, this message translates to:
  /// **'《結社自由法》'**
  String get billAssemblyLaw;

  /// No description provided for @billAssemblyLawDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'允許工人組織工會和政治團體。'**
  String get billAssemblyLawDesc;

  /// No description provided for @billReformAct.
  ///
  /// In zh_TW, this message translates to:
  /// **'《選舉改革法》'**
  String get billReformAct;

  /// No description provided for @billReformActDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'擴大選舉權，改革議會選舉制度。'**
  String get billReformActDesc;

  /// No description provided for @billDetailPending.
  ///
  /// In zh_TW, this message translates to:
  /// **'議案詳情待定...'**
  String get billDetailPending;

  /// No description provided for @victory.
  ///
  /// In zh_TW, this message translates to:
  /// **'大獲全勝！'**
  String get victory;

  /// No description provided for @defeat.
  ///
  /// In zh_TW, this message translates to:
  /// **'政治失敗'**
  String get defeat;

  /// No description provided for @victorySubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'在這場政治角力中表現卓越！'**
  String get victorySubtitle;

  /// No description provided for @defeatSubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'政治是一門藝術，下次會更好。'**
  String get defeatSubtitle;

  /// No description provided for @finalRanking.
  ///
  /// In zh_TW, this message translates to:
  /// **'最終排名'**
  String get finalRanking;

  /// No description provided for @mvp.
  ///
  /// In zh_TW, this message translates to:
  /// **'MVP'**
  String get mvp;

  /// No description provided for @gameStats.
  ///
  /// In zh_TW, this message translates to:
  /// **'遊戲統計'**
  String get gameStats;

  /// No description provided for @cardsUsed.
  ///
  /// In zh_TW, this message translates to:
  /// **'使用卡牌數'**
  String get cardsUsed;

  /// No description provided for @damageDealt.
  ///
  /// In zh_TW, this message translates to:
  /// **'造成傷害'**
  String get damageDealt;

  /// No description provided for @damageTaken.
  ///
  /// In zh_TW, this message translates to:
  /// **'受到傷害'**
  String get damageTaken;

  /// No description provided for @voteWinRate.
  ///
  /// In zh_TW, this message translates to:
  /// **'投票勝率'**
  String get voteWinRate;

  /// No description provided for @gameDuration.
  ///
  /// In zh_TW, this message translates to:
  /// **'遊戲時長'**
  String get gameDuration;

  /// No description provided for @playAgain.
  ///
  /// In zh_TW, this message translates to:
  /// **'再來一局'**
  String get playAgain;

  /// No description provided for @backToMenu.
  ///
  /// In zh_TW, this message translates to:
  /// **'返回主選單'**
  String get backToMenu;

  /// No description provided for @reputation.
  ///
  /// In zh_TW, this message translates to:
  /// **'聲望'**
  String get reputation;

  /// No description provided for @reputationColon.
  ///
  /// In zh_TW, this message translates to:
  /// **'聲望: {value}'**
  String reputationColon(int value);

  /// No description provided for @score.
  ///
  /// In zh_TW, this message translates to:
  /// **'分數'**
  String get score;

  /// No description provided for @nCards.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 張'**
  String nCards(String count);

  /// No description provided for @nPoints.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 點'**
  String nPoints(String count);

  /// No description provided for @createRoom.
  ///
  /// In zh_TW, this message translates to:
  /// **'創建房間'**
  String get createRoom;

  /// No description provided for @joinRoom.
  ///
  /// In zh_TW, this message translates to:
  /// **'加入房間'**
  String get joinRoom;

  /// No description provided for @roomCode.
  ///
  /// In zh_TW, this message translates to:
  /// **'房間代碼'**
  String get roomCode;

  /// No description provided for @roomCodeHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'輸入 6 位房間代碼'**
  String get roomCodeHint;

  /// No description provided for @roomName.
  ///
  /// In zh_TW, this message translates to:
  /// **'房間名稱'**
  String get roomName;

  /// No description provided for @roomNameHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'輸入房間名稱'**
  String get roomNameHint;

  /// No description provided for @maxPlayers.
  ///
  /// In zh_TW, this message translates to:
  /// **'最大玩家數：'**
  String get maxPlayers;

  /// No description provided for @nPlayers.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 人'**
  String nPlayers(int count);

  /// No description provided for @privateRoom.
  ///
  /// In zh_TW, this message translates to:
  /// **'私人房間'**
  String get privateRoom;

  /// No description provided for @privateRoomDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'需要密碼才能加入'**
  String get privateRoomDesc;

  /// No description provided for @roomPassword.
  ///
  /// In zh_TW, this message translates to:
  /// **'房間密碼'**
  String get roomPassword;

  /// No description provided for @roomPasswordHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'輸入房間密碼'**
  String get roomPasswordHint;

  /// No description provided for @passwordOptional.
  ///
  /// In zh_TW, this message translates to:
  /// **'密碼（如需要）'**
  String get passwordOptional;

  /// No description provided for @create.
  ///
  /// In zh_TW, this message translates to:
  /// **'創建'**
  String get create;

  /// No description provided for @join.
  ///
  /// In zh_TW, this message translates to:
  /// **'加入'**
  String get join;

  /// No description provided for @statusFilter.
  ///
  /// In zh_TW, this message translates to:
  /// **'狀態篩選'**
  String get statusFilter;

  /// No description provided for @filterStatusAll.
  ///
  /// In zh_TW, this message translates to:
  /// **'全部'**
  String get filterStatusAll;

  /// No description provided for @filterStatusWaiting.
  ///
  /// In zh_TW, this message translates to:
  /// **'等待中'**
  String get filterStatusWaiting;

  /// No description provided for @filterStatusPlaying.
  ///
  /// In zh_TW, this message translates to:
  /// **'遊戲中'**
  String get filterStatusPlaying;

  /// No description provided for @searchRoom.
  ///
  /// In zh_TW, this message translates to:
  /// **'搜尋房間'**
  String get searchRoom;

  /// No description provided for @noRoomsAvailable.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚無可用房間'**
  String get noRoomsAvailable;

  /// No description provided for @createRoomPrompt.
  ///
  /// In zh_TW, this message translates to:
  /// **'創建一個新房間開始遊戲吧！'**
  String get createRoomPrompt;

  /// No description provided for @roomCodeCopied.
  ///
  /// In zh_TW, this message translates to:
  /// **'房間代碼已複製到剪貼簿'**
  String get roomCodeCopied;

  /// No description provided for @cannotJoin.
  ///
  /// In zh_TW, this message translates to:
  /// **'無法加入：{status}'**
  String cannotJoin(String status);

  /// No description provided for @roomFull.
  ///
  /// In zh_TW, this message translates to:
  /// **'房間已滿'**
  String get roomFull;

  /// No description provided for @roomCreateComingSoon.
  ///
  /// In zh_TW, this message translates to:
  /// **'房間創建功能將在後續版本實現'**
  String get roomCreateComingSoon;

  /// No description provided for @roomSettingsComingSoon.
  ///
  /// In zh_TW, this message translates to:
  /// **'房間設定功能將在後續版本實現'**
  String get roomSettingsComingSoon;

  /// No description provided for @kickPlayerComingSoon.
  ///
  /// In zh_TW, this message translates to:
  /// **'踢出玩家功能將在後續版本實現'**
  String get kickPlayerComingSoon;

  /// No description provided for @readyComingSoon.
  ///
  /// In zh_TW, this message translates to:
  /// **'準備功能將在後續版本實現'**
  String get readyComingSoon;

  /// No description provided for @players.
  ///
  /// In zh_TW, this message translates to:
  /// **'玩家'**
  String get players;

  /// No description provided for @playerList.
  ///
  /// In zh_TW, this message translates to:
  /// **'玩家列表'**
  String get playerList;

  /// No description provided for @inviteFriend.
  ///
  /// In zh_TW, this message translates to:
  /// **'邀請好友'**
  String get inviteFriend;

  /// No description provided for @inviteShareCode.
  ///
  /// In zh_TW, this message translates to:
  /// **'分享房間代碼給好友：'**
  String get inviteShareCode;

  /// No description provided for @leaveRoom.
  ///
  /// In zh_TW, this message translates to:
  /// **'離開房間'**
  String get leaveRoom;

  /// No description provided for @leaveRoomConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'確定要離開房間嗎？'**
  String get leaveRoomConfirm;

  /// No description provided for @startGame.
  ///
  /// In zh_TW, this message translates to:
  /// **'開始遊戲'**
  String get startGame;

  /// No description provided for @canStartGame.
  ///
  /// In zh_TW, this message translates to:
  /// **'可以開始遊戲'**
  String get canStartGame;

  /// No description provided for @ready.
  ///
  /// In zh_TW, this message translates to:
  /// **'準備'**
  String get ready;

  /// No description provided for @cancelReady.
  ///
  /// In zh_TW, this message translates to:
  /// **'取消準備'**
  String get cancelReady;

  /// No description provided for @isReady.
  ///
  /// In zh_TW, this message translates to:
  /// **'已準備'**
  String get isReady;

  /// No description provided for @notReady.
  ///
  /// In zh_TW, this message translates to:
  /// **'未準備'**
  String get notReady;

  /// No description provided for @roomSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'房間設定'**
  String get roomSettings;

  /// No description provided for @kickPlayer.
  ///
  /// In zh_TW, this message translates to:
  /// **'踢出玩家'**
  String get kickPlayer;

  /// No description provided for @kickPlayerConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'確定要踢出 {name} 嗎？'**
  String kickPlayerConfirm(String name);

  /// No description provided for @kick.
  ///
  /// In zh_TW, this message translates to:
  /// **'踢出'**
  String get kick;

  /// No description provided for @host.
  ///
  /// In zh_TW, this message translates to:
  /// **'房主'**
  String get host;

  /// No description provided for @noCharacterSelected.
  ///
  /// In zh_TW, this message translates to:
  /// **'未選角色'**
  String get noCharacterSelected;

  /// No description provided for @characterSelected.
  ///
  /// In zh_TW, this message translates to:
  /// **'選擇了角色：{name}'**
  String characterSelected(String name);

  /// No description provided for @alreadyTaken.
  ///
  /// In zh_TW, this message translates to:
  /// **'已被選擇'**
  String get alreadyTaken;

  /// No description provided for @characterThomas.
  ///
  /// In zh_TW, this message translates to:
  /// **'湯瑪斯'**
  String get characterThomas;

  /// No description provided for @characterThomasFull.
  ///
  /// In zh_TW, this message translates to:
  /// **'工人湯瑪斯'**
  String get characterThomasFull;

  /// No description provided for @characterThomasDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'工人領袖\n團結技能：盟友越多，防禦越強'**
  String get characterThomasDesc;

  /// No description provided for @characterRichard.
  ///
  /// In zh_TW, this message translates to:
  /// **'理查'**
  String get characterRichard;

  /// No description provided for @characterRichardFull.
  ///
  /// In zh_TW, this message translates to:
  /// **'工廠主理查'**
  String get characterRichardFull;

  /// No description provided for @characterRichardDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'工廠主\n收買技能：用金幣讓對手沉默'**
  String get characterRichardDesc;

  /// No description provided for @characterEdward.
  ///
  /// In zh_TW, this message translates to:
  /// **'愛德華'**
  String get characterEdward;

  /// No description provided for @characterEdwardFull.
  ///
  /// In zh_TW, this message translates to:
  /// **'記者愛德華'**
  String get characterEdwardFull;

  /// No description provided for @characterEdwardDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'記者\n爆料技能：揭露對手秘密'**
  String get characterEdwardDesc;

  /// No description provided for @characterGeorge.
  ///
  /// In zh_TW, this message translates to:
  /// **'喬治'**
  String get characterGeorge;

  /// No description provided for @characterGeorgeFull.
  ///
  /// In zh_TW, this message translates to:
  /// **'盧德派喬治'**
  String get characterGeorgeFull;

  /// No description provided for @characterGeorgeDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'盧德派\n怒火技能：造成雙倍傷害'**
  String get characterGeorgeDesc;

  /// No description provided for @unknownCharacter.
  ///
  /// In zh_TW, this message translates to:
  /// **'未知'**
  String get unknownCharacter;

  /// No description provided for @unknownRole.
  ///
  /// In zh_TW, this message translates to:
  /// **'未知角色'**
  String get unknownRole;

  /// No description provided for @tutorialIntroTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'遊戲簡介'**
  String get tutorialIntroTitle;

  /// No description provided for @tutorialIntroContent.
  ///
  /// In zh_TW, this message translates to:
  /// **'1812 國會風雲是一款以英國國會為背景的卡牌策略遊戲。4 名玩家分別扮演不同陣營的角色，透過質詢、辯論、結盟與投票，爭奪政治影響力。'**
  String get tutorialIntroContent;

  /// No description provided for @tutorialFlowTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'遊戲流程'**
  String get tutorialFlowTitle;

  /// No description provided for @tutorialFlowContent.
  ///
  /// In zh_TW, this message translates to:
  /// **'每回合分為三個階段：\n\n🤝 密謀階段（120秒）\n私下協商，決定結盟或背叛。\n\n⚔️ 辯論階段（300秒）\n出卡攻擊、防禦、使用技能。消耗影響力和金幣。\n\n🗳️ 投票階段（60秒）\n對當回合議案投支持或反對票。'**
  String get tutorialFlowContent;

  /// No description provided for @tutorialCardsTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'卡牌系統'**
  String get tutorialCardsTitle;

  /// No description provided for @tutorialCardsContent.
  ///
  /// In zh_TW, this message translates to:
  /// **'開局發 6 張手牌，每回合自動抽 1 張。\n\n🗡️ 攻擊卡 — 對目標造成聲望傷害\n🛡️ 防禦卡 — 抵消攻擊\n🔧 功能卡 — 恢復聲望或特殊效果\n⭐ 專屬卡 — 角色獨有的強力卡牌'**
  String get tutorialCardsContent;

  /// No description provided for @tutorialCharactersTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'角色介紹'**
  String get tutorialCharactersTitle;

  /// No description provided for @tutorialCharactersContent.
  ///
  /// In zh_TW, this message translates to:
  /// **'🔨 工人湯瑪斯 — 初始聲望 70，技能：團結\n🏭 工廠主理查 — 初始聲望 60，技能：收買\n📰 記者愛德華 — 初始聲望 50，技能：爆料\n🔥 盧德派喬治 — 初始聲望 80，技能：怒火'**
  String get tutorialCharactersContent;

  /// No description provided for @tutorialVictoryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'勝利條件'**
  String get tutorialVictoryTitle;

  /// No description provided for @tutorialVictoryContent.
  ///
  /// In zh_TW, this message translates to:
  /// **'聲望歸零 = 政治死亡（淘汰）。\n存活到最後、聲望最高的玩家獲勝。\n投票結果會影響所有人的聲望和資源。'**
  String get tutorialVictoryContent;

  /// No description provided for @cardTypeAttack.
  ///
  /// In zh_TW, this message translates to:
  /// **'攻擊'**
  String get cardTypeAttack;

  /// No description provided for @cardTypeDefense.
  ///
  /// In zh_TW, this message translates to:
  /// **'防禦'**
  String get cardTypeDefense;

  /// No description provided for @cardTypeUtility.
  ///
  /// In zh_TW, this message translates to:
  /// **'功能'**
  String get cardTypeUtility;

  /// No description provided for @cardTypeSignature.
  ///
  /// In zh_TW, this message translates to:
  /// **'專屬'**
  String get cardTypeSignature;

  /// No description provided for @addFriend.
  ///
  /// In zh_TW, this message translates to:
  /// **'新增好友'**
  String get addFriend;

  /// No description provided for @friendIdHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'輸入好友 ID'**
  String get friendIdHint;

  /// No description provided for @sendRequest.
  ///
  /// In zh_TW, this message translates to:
  /// **'發送邀請'**
  String get sendRequest;

  /// No description provided for @friendRequestSent.
  ///
  /// In zh_TW, this message translates to:
  /// **'已發送'**
  String get friendRequestSent;

  /// No description provided for @removeFriend.
  ///
  /// In zh_TW, this message translates to:
  /// **'移除好友'**
  String get removeFriend;

  /// No description provided for @removeFriendConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'確定要移除好友 {name} 嗎？'**
  String removeFriendConfirm(String name);

  /// No description provided for @online.
  ///
  /// In zh_TW, this message translates to:
  /// **'線上'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In zh_TW, this message translates to:
  /// **'離線'**
  String get offline;

  /// No description provided for @inGame.
  ///
  /// In zh_TW, this message translates to:
  /// **'遊戲中'**
  String get inGame;

  /// No description provided for @noFriendsYet.
  ///
  /// In zh_TW, this message translates to:
  /// **'還沒有好友'**
  String get noFriendsYet;

  /// No description provided for @addFriendPrompt.
  ///
  /// In zh_TW, this message translates to:
  /// **'新增好友開始社交吧！'**
  String get addFriendPrompt;

  /// No description provided for @connectionConnected.
  ///
  /// In zh_TW, this message translates to:
  /// **'已連線'**
  String get connectionConnected;

  /// No description provided for @connectionDisconnected.
  ///
  /// In zh_TW, this message translates to:
  /// **'已斷線'**
  String get connectionDisconnected;

  /// No description provided for @connectionConnecting.
  ///
  /// In zh_TW, this message translates to:
  /// **'連線中...'**
  String get connectionConnecting;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
