// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Parliament 1812';

  @override
  String get appSubtitle => 'Parliament Crisis';

  @override
  String get appTagline => 'Political Card Strategy';

  @override
  String get appVersion => 'Parliament 1812 v1.0.0 — M6';

  @override
  String get splashSubtitle => 'PARLIAMENT CRISIS';

  @override
  String get splashTagline => 'A Game of Cards and Lies';

  @override
  String get login => 'Log In';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Log Out';

  @override
  String get emailOrUsername => 'Email or Username';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get email => 'Email';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => '3-20 characters';

  @override
  String get passwordHint => 'At least 8 characters';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccount => 'No account?';

  @override
  String get hasAccount => 'Already have an account?';

  @override
  String get registerNow => 'Register Now';

  @override
  String get loginNow => 'Log In Now';

  @override
  String get guestMode => 'Enter as Guest';

  @override
  String get googleLogin => 'Sign in with Google';

  @override
  String get appleLogin => 'Sign in with Apple';

  @override
  String get or => 'or';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinParliament => 'Join Parliament';

  @override
  String get createIdentity => 'Create your MP identity';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordDesc =>
      'Enter your email and we\'ll send you a password reset link.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetLinkSent => 'Reset Link Sent';

  @override
  String get resetLinkSentDesc =>
      'If this email is registered, you\'ll receive password reset instructions. Please check your inbox.';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get requestFailed => 'Request failed. Please try again later.';

  @override
  String get validationEmailRequired => 'Please enter your email or username';

  @override
  String get validationPasswordRequired => 'Please enter your password';

  @override
  String get validationEmailInvalid => 'Invalid email format';

  @override
  String get validationUsernameRequired => 'Please enter a username';

  @override
  String get validationUsernameMinLength =>
      'Username must be at least 3 characters';

  @override
  String get validationUsernameMaxLength =>
      'Username must be 20 characters or less';

  @override
  String get validationPasswordMinLength =>
      'Password must be at least 8 characters';

  @override
  String get validationConfirmPasswordRequired =>
      'Please confirm your password';

  @override
  String get validationPasswordMismatch => 'Passwords do not match';

  @override
  String get validationEmailFieldRequired => 'Please enter your email';

  @override
  String get quickMatch => 'Quick Match';

  @override
  String get quickMatchDesc => 'Start a game right away';

  @override
  String get roomList => 'Room List';

  @override
  String get roomListDesc => 'Join or create rooms';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get leaderboardDesc => 'View global rankings & ELO ratings';

  @override
  String get dailyQuests => 'Daily Quests';

  @override
  String get dailyQuestsDesc => 'Complete quests for rewards';

  @override
  String get cardCodex => 'Card Codex';

  @override
  String get cardCodexDesc => 'Collection & Achievements';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get tutorialDesc => 'Learn game rules & strategies';

  @override
  String get friends => 'Friends';

  @override
  String get friendsDesc => 'Manage friends & social';

  @override
  String get settings => 'Settings';

  @override
  String get settingsComingSoon => 'Settings coming in a future update';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get language => 'Language';

  @override
  String get languageZhTW => '繁體中文';

  @override
  String get languageEn => 'English';

  @override
  String get languageZhCN => '简体中文';

  @override
  String get audioSettings => 'Audio Settings';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get backgroundMusic => 'Background Music';

  @override
  String get accountSettings => 'Account';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirm =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get aboutApp => 'About';

  @override
  String get version => 'Version';

  @override
  String get globalRanking => 'Global Ranking';

  @override
  String get myRanking => 'My Ranking';

  @override
  String get season => 'Season';

  @override
  String get switchSeason => 'Switch Season';

  @override
  String get gamesPlayed => 'Games';

  @override
  String get wins => 'Wins';

  @override
  String get winRate => 'Win Rate';

  @override
  String get eloRating => 'ELO';

  @override
  String get noRankingData => 'No ranking data for this season';

  @override
  String get notRankedYet => 'Not yet ranked';

  @override
  String get playRankedToGetRank => 'Complete a ranked match to get ranked';

  @override
  String totalRanked(int count) {
    return '/ $count players';
  }

  @override
  String get unranked => 'Unranked';

  @override
  String matchCount(int count) {
    return '$count games';
  }

  @override
  String winRatePercent(String rate) {
    return 'Win rate $rate%';
  }

  @override
  String get allCards => 'All Cards';

  @override
  String get myCollection => 'My Collection';

  @override
  String get achievements => 'Achievements';

  @override
  String collectionProgress(int collected, int total) {
    return '$collected/$total';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterCommon => 'Common';

  @override
  String get filterUncommon => 'Uncommon';

  @override
  String get filterRare => 'Rare';

  @override
  String get filterLegendary => 'Legendary';

  @override
  String get noCardsCollected => 'No cards collected yet';

  @override
  String get playToCollect => 'Play matches to collect cards!';

  @override
  String get noAchievementData => 'No achievement data';

  @override
  String achievementsCompleted(int completed, int total) {
    return '$completed/$total completed';
  }

  @override
  String pendingClaim(int count) {
    return '$count to claim';
  }

  @override
  String get claim => 'Claim';

  @override
  String get claimReward => 'Claim Reward';

  @override
  String get claimed => 'Claimed';

  @override
  String get claimable => 'Claimable';

  @override
  String get hiddenAchievement => '🏆 ???';

  @override
  String get hiddenAchievementDesc =>
      'Hidden Achievement — Complete special conditions to unlock';

  @override
  String get rewards => 'Rewards';

  @override
  String get difficultyEasy => '🟢 Easy';

  @override
  String get difficultyMedium => '🟡 Medium';

  @override
  String get difficultyHard => '🔴 Hard';

  @override
  String get difficultyHidden => '🟣 Hidden';

  @override
  String get unlockCondition => 'Unlock Condition';

  @override
  String influenceCost(int cost) {
    return 'Influence cost: $cost';
  }

  @override
  String effectValue(int value) {
    return 'Effect value: $value';
  }

  @override
  String exclusiveRole(String role) {
    return 'Exclusive to: $role';
  }

  @override
  String get questResetCountdown => 'Reset countdown';

  @override
  String get resetSoon => 'Resetting soon...';

  @override
  String get retry => 'Retry';

  @override
  String streakDays(int days) {
    return '$days-day streak';
  }

  @override
  String longestStreak(int days) {
    return 'Longest: $days days';
  }

  @override
  String streakMilestone(int count) {
    return '🎉 ${count}x7 days';
  }

  @override
  String get allCompletedBonus => 'All-Complete Bonus';

  @override
  String get allCompletedBonusDesc =>
      'All quests completed! Claim rewards for 10 bonus gems';

  @override
  String allCompletedBonusProgress(int completed, int total) {
    return 'Complete all $total quests for 10 bonus gems ($completed/$total)';
  }

  @override
  String roundN(int round) {
    return 'Round $round';
  }

  @override
  String handCards(int count) {
    return 'Hand: $count';
  }

  @override
  String get noHandCards => 'No hand cards';

  @override
  String get phaseConspiracy => 'Conspiracy Phase';

  @override
  String get phaseDebate => 'Debate Phase';

  @override
  String get phaseVoting => 'Voting Phase';

  @override
  String get phaseResult => 'Result Phase';

  @override
  String get phasePreparing => 'Preparing';

  @override
  String get conspiracySubtitle => 'Plan your moves';

  @override
  String get debateSubtitle => 'Engage in fierce political combat';

  @override
  String get votingSubtitle => 'Decide the fate of the bill';

  @override
  String get resultSubtitle => 'Tallying the votes';

  @override
  String get gameInProgress => 'Game in Progress';

  @override
  String get loadingGame => 'Loading game...';

  @override
  String get currentBill => 'Current Bill';

  @override
  String get noBill => 'No bill';

  @override
  String get waitingForBill => 'Waiting for bill';

  @override
  String get eventLog => 'Event Log';

  @override
  String get chat => 'Chat';

  @override
  String get chatInputHint => 'Type a message...';

  @override
  String get investigate => 'Investigate';

  @override
  String get formAlliance => 'Ally';

  @override
  String get bribe => 'Bribe';

  @override
  String get interrogate => 'Interrogate';

  @override
  String get rebut => 'Rebut';

  @override
  String get skill => 'Skill';

  @override
  String get support => 'Support';

  @override
  String get oppose => 'Oppose';

  @override
  String get abstain => 'Abstain';

  @override
  String get waiting => 'Waiting';

  @override
  String useCard(String name) {
    return 'Use card: $name';
  }

  @override
  String get gameSettings => 'Game Settings';

  @override
  String get soundEffect => 'Sound Effects';

  @override
  String get gameRules => 'Game Rules';

  @override
  String get leaveGame => 'Leave Game';

  @override
  String get leaveGameConfirm =>
      'Are you sure you want to leave? Game progress will be lost.';

  @override
  String get cancel => 'Cancel';

  @override
  String get leave => 'Leave';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'OK';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String get quickMessage1 => 'Well played!';

  @override
  String get quickMessage2 => 'Alliance?';

  @override
  String get quickMessage3 => 'You\'re done.';

  @override
  String get quickMessage4 => 'Vote for me';

  @override
  String get quickMessage5 => 'Interesting...';

  @override
  String get quickMessage6 => 'I agree.';

  @override
  String get billEffectPreview => 'Vote Effect Preview';

  @override
  String get billEffectPending =>
      'Effects will be shown when the bill is decided';

  @override
  String get billFactoryAct => 'The Factory Act';

  @override
  String get billFactoryActDesc =>
      'Limit factory working hours and improve worker conditions.';

  @override
  String get billPressLaw => 'The Press Censorship Act';

  @override
  String get billPressLawDesc =>
      'Restrict press freedom and control public opinion.';

  @override
  String get billCornLaw => 'Corn Law Repeal';

  @override
  String get billCornLawDesc =>
      'Abolish grain import tariffs and lower food prices.';

  @override
  String get billAssemblyLaw => 'The Freedom of Assembly Act';

  @override
  String get billAssemblyLawDesc =>
      'Allow workers to organize unions and political groups.';

  @override
  String get billReformAct => 'The Electoral Reform Act';

  @override
  String get billReformActDesc =>
      'Expand suffrage and reform the parliamentary election system.';

  @override
  String get billDetailPending => 'Bill details to be determined...';

  @override
  String get victory => 'Victory!';

  @override
  String get defeat => 'Political Defeat';

  @override
  String get victorySubtitle =>
      'Outstanding performance in this political battle!';

  @override
  String get defeatSubtitle =>
      'Politics is an art. You\'ll do better next time.';

  @override
  String get finalRanking => 'Final Ranking';

  @override
  String get mvp => 'MVP';

  @override
  String get gameStats => 'Game Statistics';

  @override
  String get cardsUsed => 'Cards Used';

  @override
  String get damageDealt => 'Damage Dealt';

  @override
  String get damageTaken => 'Damage Taken';

  @override
  String get voteWinRate => 'Vote Win Rate';

  @override
  String get gameDuration => 'Game Duration';

  @override
  String get playAgain => 'Play Again';

  @override
  String get backToMenu => 'Back to Menu';

  @override
  String get reputation => 'Reputation';

  @override
  String reputationColon(int value) {
    return 'Rep: $value';
  }

  @override
  String get score => 'Score';

  @override
  String nCards(String count) {
    return '$count cards';
  }

  @override
  String nPoints(String count) {
    return '$count pts';
  }

  @override
  String get createRoom => 'Create Room';

  @override
  String get joinRoom => 'Join Room';

  @override
  String get roomCode => 'Room Code';

  @override
  String get roomCodeHint => 'Enter 6-digit room code';

  @override
  String get roomName => 'Room Name';

  @override
  String get roomNameHint => 'Enter room name';

  @override
  String get maxPlayers => 'Max Players:';

  @override
  String nPlayers(int count) {
    return '$count players';
  }

  @override
  String get privateRoom => 'Private Room';

  @override
  String get privateRoomDesc => 'Requires password to join';

  @override
  String get roomPassword => 'Room Password';

  @override
  String get roomPasswordHint => 'Enter room password';

  @override
  String get passwordOptional => 'Password (if required)';

  @override
  String get create => 'Create';

  @override
  String get join => 'Join';

  @override
  String get statusFilter => 'Status Filter';

  @override
  String get filterStatusAll => 'All';

  @override
  String get filterStatusWaiting => 'Waiting';

  @override
  String get filterStatusPlaying => 'In Game';

  @override
  String get searchRoom => 'Search Rooms';

  @override
  String get noRoomsAvailable => 'No rooms available';

  @override
  String get createRoomPrompt => 'Create a room to start playing!';

  @override
  String get roomCodeCopied => 'Room code copied to clipboard';

  @override
  String cannotJoin(String status) {
    return 'Cannot join: $status';
  }

  @override
  String get roomFull => 'Room is full';

  @override
  String get roomCreateComingSoon => 'Room creation coming in a future update';

  @override
  String get roomSettingsComingSoon =>
      'Room settings coming in a future update';

  @override
  String get kickPlayerComingSoon => 'Kick player coming in a future update';

  @override
  String get readyComingSoon => 'Ready feature coming in a future update';

  @override
  String get players => 'Players';

  @override
  String get playerList => 'Player List';

  @override
  String get inviteFriend => 'Invite Friend';

  @override
  String get inviteShareCode => 'Share the room code with friends:';

  @override
  String get leaveRoom => 'Leave Room';

  @override
  String get leaveRoomConfirm => 'Are you sure you want to leave the room?';

  @override
  String get startGame => 'Start Game';

  @override
  String get canStartGame => 'Ready to start';

  @override
  String get ready => 'Ready';

  @override
  String get cancelReady => 'Cancel Ready';

  @override
  String get isReady => 'Ready';

  @override
  String get notReady => 'Not Ready';

  @override
  String get roomSettings => 'Room Settings';

  @override
  String get kickPlayer => 'Kick Player';

  @override
  String kickPlayerConfirm(String name) {
    return 'Are you sure you want to kick $name?';
  }

  @override
  String get kick => 'Kick';

  @override
  String get host => 'Host';

  @override
  String get noCharacterSelected => 'No character';

  @override
  String characterSelected(String name) {
    return 'Selected: $name';
  }

  @override
  String get alreadyTaken => 'Already taken';

  @override
  String get characterThomas => 'Thomas';

  @override
  String get characterThomasFull => 'Thomas the Worker';

  @override
  String get characterThomasDesc =>
      'Worker Leader\nUnity Skill: More allies, stronger defense';

  @override
  String get characterRichard => 'Richard';

  @override
  String get characterRichardFull => 'Richard the Factory Owner';

  @override
  String get characterRichardDesc =>
      'Factory Owner\nBribery Skill: Silence opponents with gold';

  @override
  String get characterEdward => 'Edward';

  @override
  String get characterEdwardFull => 'Edward the Journalist';

  @override
  String get characterEdwardDesc =>
      'Journalist\nScoop Skill: Expose opponents\' secrets';

  @override
  String get characterGeorge => 'George';

  @override
  String get characterGeorgeFull => 'George the Luddite';

  @override
  String get characterGeorgeDesc => 'Luddite\nFury Skill: Deal double damage';

  @override
  String get unknownCharacter => 'Unknown';

  @override
  String get unknownRole => 'Unknown role';

  @override
  String get tutorialIntroTitle => 'Introduction';

  @override
  String get tutorialIntroContent =>
      'Parliament 1812 is a political card strategy game set in the British Parliament. 4 players take on different roles, competing for political influence through interrogation, debate, alliances, and voting.';

  @override
  String get tutorialFlowTitle => 'Game Flow';

  @override
  String get tutorialFlowContent =>
      'Each round has three phases:\n\n🤝 Conspiracy Phase (120s)\nNegotiate in private, decide alliances or betrayals.\n\n⚔️ Debate Phase (300s)\nPlay cards to attack, defend, and use skills. Spend influence and gold.\n\n🗳️ Voting Phase (60s)\nVote for or against the current bill.';

  @override
  String get tutorialCardsTitle => 'Card System';

  @override
  String get tutorialCardsContent =>
      'Start with 6 hand cards, draw 1 each turn.\n\n🗡️ Attack Cards — Deal reputation damage\n🛡️ Defense Cards — Negate attacks\n🔧 Utility Cards — Restore reputation or special effects\n⭐ Signature Cards — Powerful character-exclusive cards';

  @override
  String get tutorialCharactersTitle => 'Characters';

  @override
  String get tutorialCharactersContent =>
      '🔨 Thomas the Worker — Starting Rep 70, Skill: Unity\n🏭 Richard the Factory Owner — Starting Rep 60, Skill: Bribery\n📰 Edward the Journalist — Starting Rep 50, Skill: Scoop\n🔥 George the Luddite — Starting Rep 80, Skill: Fury';

  @override
  String get tutorialVictoryTitle => 'Victory Conditions';

  @override
  String get tutorialVictoryContent =>
      'Reputation reaches zero = Political Death (eliminated).\nThe last player standing with the highest reputation wins.\nVote outcomes affect everyone\'s reputation and resources.';

  @override
  String get cardTypeAttack => 'Attack';

  @override
  String get cardTypeDefense => 'Defense';

  @override
  String get cardTypeUtility => 'Utility';

  @override
  String get cardTypeSignature => 'Signature';

  @override
  String get addFriend => 'Add Friend';

  @override
  String get friendIdHint => 'Enter friend ID';

  @override
  String get sendRequest => 'Send Request';

  @override
  String get friendRequestSent => 'Sent';

  @override
  String get removeFriend => 'Remove Friend';

  @override
  String removeFriendConfirm(String name) {
    return 'Are you sure you want to remove $name?';
  }

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get inGame => 'In Game';

  @override
  String get noFriendsYet => 'No friends yet';

  @override
  String get addFriendPrompt => 'Add friends to get started!';

  @override
  String get connectionConnected => 'Connected';

  @override
  String get connectionDisconnected => 'Disconnected';

  @override
  String get connectionConnecting => 'Connecting...';
}
