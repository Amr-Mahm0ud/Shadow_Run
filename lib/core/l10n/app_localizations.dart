import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Lightweight real localizations for SHADOW//RUN (EN + AR).
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  bool get isArabic => locale.languageCode == 'ar';

  static final Map<String, Map<String, String>> _map = {
    'en': {
      'play': 'PLAY',
      'characters': 'Characters',
      'upgrades': 'Upgrades',
      'missions': 'Missions',
      'highScores': 'High Scores',
      'settings': 'Settings',
      'coins': 'Coins',
      'gems': 'Gems',
      'best': 'Best',
      'levelShort': 'LVL {level}',
      'tagline': 'SURVIVE THE NIGHT.',
      'taglineSecondary': 'Grow stronger each run.',
      'operatives': 'OPERATIVES',
      'unlock': 'UNLOCK {cost}',
      'select': 'SELECT',
      'equipped': 'EQUIPPED',
      'notEnoughCoins': 'Not enough coins',
      'upgradesTitle': 'Upgrades · {coins} coins',
      'levelProgress': 'Level {level} / {max}',
      'max': 'MAX',
      'daily': 'Daily',
      'permanent': 'Permanent',
      'missionsHint': 'Resets daily · Claim rewards when complete',
      'claim': 'CLAIM',
      'claimed': 'CLAIMED',
      'missionReward': '{current} / {target}  ·  +{coins} coins  ·  +{xp} XP',
      'claimedSnack': 'Claimed +{coins} coins, +{xp} XP{gems}',
      'gemsPart': ', +{gems} gems',
      'highScoresEmpty':
          'No runs recorded yet.\nFinish a run to set your first score.',
      'place1': '1st',
      'place2': '2nd',
      'place3': '3rd',
      'music': 'Music',
      'musicSubtitle': 'Cyberpunk soundtrack',
      'sfx': 'Sound Effects',
      'sfxSubtitle': 'UI & combat sounds',
      'musicVolume': 'Music Volume',
      'sfxVolume': 'SFX Volume',
      'uiVolume': 'UI Volume',
      'muteAll': 'Mute All',
      'muteAllSubtitle': 'Silence music, SFX, and UI',
      'vibration': 'Vibration',
      'vibrationSubtitle': 'Haptics on hits, claims, and taps',
      'language': 'Language',
      'privacy': 'Privacy Policy',
      'privacySubtitle': 'How SHADOW//RUN handles your data',
      'about': 'About',
      'close': 'CLOSE',
      'privacyBody':
          'SHADOW//RUN stores progress, settings, and high scores locally on your device. We do not collect personal accounts, precise location, or contact lists.\n\nOptional analytics and crash reports (when enabled in a store build) only include anonymous gameplay events such as run started, score, and session length.\n\nYou can reset local data by clearing the app storage from your device settings.\n\nContact: support@shadowrun.game',
      'aboutBody':
          'Survive the night. Grow stronger each run.\nFour operatives. Endless cyberpunk streets.',
      'paused': 'PAUSED',
      'resume': 'RESUME',
      'restart': 'RESTART',
      'home': 'HOME',
      'runComplete': 'RUN COMPLETE',
      'gameOver': 'GAME OVER',
      'newHighScore': 'NEW HIGH SCORE',
      'score': 'Score',
      'distance': 'Distance',
      'enemies': 'Enemies',
      'bestCombo': 'Best combo',
      'menu': 'MENU',
      'retry': 'RETRY',
      'ability': 'ABLI',
      'ult': 'ULT',
      'hintControls':
          '↑ jump  ↓ slide  ←→ dodge   TAP melee   HOLD ranged   DOUBLE-TAP ability/ult',
      'musicCredit':
          'Music: SHADOW//RUN main theme loop (assets/audio/shadow_run_main_theme.mp3)',
    },
    'ar': {
      'play': 'إلعب',
      'characters': 'الشخصيات',
      'upgrades': 'الترقيات',
      'missions': 'المهام',
      'highScores': 'أعلى النتائج',
      'settings': 'الإعدادات',
      'coins': 'عملات',
      'gems': 'جواهر',
      'best': 'الأفضل',
      'levelShort': 'المستوى {level}',
      'tagline': 'انجُ من الليل.',
      'taglineSecondary': 'ازدد قوة في كل جولة.',
      'operatives': 'العملاء',
      'unlock': 'افتح {cost}',
      'select': 'اختيار',
      'equipped': 'مُجهَّز',
      'notEnoughCoins': 'لا توجد عملات كافية',
      'upgradesTitle': 'الترقيات · {coins} عملة',
      'levelProgress': 'المستوى {level} / {max}',
      'max': 'الحد',
      'daily': 'يومية',
      'permanent': 'دائمة',
      'missionsHint': 'تُعاد يوميًا · استلم المكافآت عند الإكمال',
      'claim': 'استلام',
      'claimed': 'تم الاستلام',
      'missionReward':
          '{current} / {target}  ·  +{coins} عملة  ·  +{xp} خبرة',
      'claimedSnack': 'تم الاستلام +{coins} عملة، +{xp} خبرة{gems}',
      'gemsPart': '، +{gems} جواهر',
      'highScoresEmpty':
          'لا توجد جولات بعد.\nأنهِ جولة لتسجيل أول نتيجة.',
      'place1': 'الأول',
      'place2': 'الثاني',
      'place3': 'الثالث',
      'music': 'الموسيقى',
      'musicSubtitle': 'موسيقى سايبربانك',
      'sfx': 'المؤثرات الصوتية',
      'sfxSubtitle': 'أصوات الواجهة والقتال',
      'musicVolume': 'مستوى الموسيقى',
      'sfxVolume': 'مستوى المؤثرات',
      'uiVolume': 'مستوى الواجهة',
      'muteAll': 'كتم الكل',
      'muteAllSubtitle': 'إيقاف الموسيقى والمؤثرات والواجهة',
      'vibration': 'الاهتزاز',
      'vibrationSubtitle': 'اهتزاز عند الضربات والاستلام والضغط',
      'language': 'اللغة',
      'privacy': 'سياسة الخصوصية',
      'privacySubtitle': 'كيف يتعامل SHADOW//RUN مع بياناتك',
      'about': 'حول التطبيق',
      'close': 'إغلاق',
      'privacyBody':
          'يخزّن SHADOW//RUN التقدّم والإعدادات وأعلى النتائج محليًا على جهازك. لا نجمع حسابات شخصية أو موقعًا دقيقًا أو قوائم جهات اتصال.\n\nالتحليلات وتقارير الأعطال الاختيارية (عند تفعيلها في نسخة المتجر) تتضمن فقط أحداث لعب مجهولة مثل بدء الجولة والنتيجة ومدة الجلسة.\n\nيمكنك إعادة ضبط البيانات المحلية بمسح مساحة التطبيق من إعدادات جهازك.\n\nالتواصل: support@shadowrun.game',
      'aboutBody':
          'انجُ من الليل. ازدد قوة في كل جولة.\nأربعة عملاء. شوارع سايبربانك لا تنتهي.',
      'paused': 'إيقاف مؤقت',
      'resume': 'متابعة',
      'restart': 'إعادة',
      'home': 'الرئيسية',
      'runComplete': 'انتهت الجولة',
      'gameOver': 'انتهت اللعبة',
      'newHighScore': 'رقم قياسي جديد',
      'score': 'النتيجة',
      'distance': 'المسافة',
      'enemies': 'الأعداء',
      'bestCombo': 'أفضل سلسلة',
      'menu': 'القائمة',
      'retry': 'إعادة',
      'ability': 'قدرة',
      'ult': 'نهائية',
      'hintControls':
          '↑ قفز  ↓ انزلاق  ←→ مراوغة   نقرة هجوم   مطوّلة رمي   نقرتان قدرة/نهائية',
      'musicCredit':
          'الموسيقى: ثيم SHADOW//RUN الرئيسي (assets/audio/shadow_run_main_theme.mp3)',
    },
  };

  String _t(String key) {
    final lang = isArabic ? 'ar' : 'en';
    return _map[lang]![key] ?? _map['en']![key] ?? key;
  }

  String _fmt(String key, Map<String, String> args) {
    var s = _t(key);
    args.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  String get play => _t('play');
  String get characters => _t('characters');
  String get upgrades => _t('upgrades');
  String get missions => _t('missions');
  String get highScores => _t('highScores');
  String get settings => _t('settings');
  String get coins => _t('coins');
  String get gems => _t('gems');
  String get best => _t('best');
  String levelShort(int level) => _fmt('levelShort', {'level': '$level'});
  String get tagline => _t('tagline');
  String get taglineSecondary => _t('taglineSecondary');
  String get operatives => _t('operatives');
  String unlock(int cost) => _fmt('unlock', {'cost': '$cost'});
  String get select => _t('select');
  String get equipped => _t('equipped');
  String get notEnoughCoins => _t('notEnoughCoins');
  String upgradesTitle(int coins) => _fmt('upgradesTitle', {'coins': '$coins'});
  String levelProgress(int level, int max) =>
      _fmt('levelProgress', {'level': '$level', 'max': '$max'});
  String get max => _t('max');
  String get daily => _t('daily');
  String get permanent => _t('permanent');
  String get missionsHint => _t('missionsHint');
  String get claim => _t('claim');
  String get claimed => _t('claimed');
  String missionReward(int current, int target, int coins, int xp) => _fmt(
        'missionReward',
        {
          'current': '$current',
          'target': '$target',
          'coins': '$coins',
          'xp': '$xp',
        },
      );
  String claimedSnack(int coins, int xp, int gems) => _fmt(
        'claimedSnack',
        {
          'coins': '$coins',
          'xp': '$xp',
          'gems': gems > 0 ? _fmt('gemsPart', {'gems': '$gems'}) : '',
        },
      );
  String get highScoresEmpty => _t('highScoresEmpty');
  String place(int index) => _t('place${index + 1}');
  String get music => _t('music');
  String get musicSubtitle => _t('musicSubtitle');
  String get sfx => _t('sfx');
  String get sfxSubtitle => _t('sfxSubtitle');
  String get musicVolume => _t('musicVolume');
  String get sfxVolume => _t('sfxVolume');
  String get uiVolume => _t('uiVolume');
  String get muteAll => _t('muteAll');
  String get muteAllSubtitle => _t('muteAllSubtitle');
  String get vibration => _t('vibration');
  String get vibrationSubtitle => _t('vibrationSubtitle');
  String get language => _t('language');
  String get privacy => _t('privacy');
  String get privacySubtitle => _t('privacySubtitle');
  String get about => _t('about');
  String get close => _t('close');
  String get privacyBody => _t('privacyBody');
  String get aboutBody => _t('aboutBody');
  String get paused => _t('paused');
  String get resume => _t('resume');
  String get restart => _t('restart');
  String get home => _t('home');
  String get runComplete => _t('runComplete');
  String get gameOver => _t('gameOver');
  String get newHighScore => _t('newHighScore');
  String get score => _t('score');
  String get distance => _t('distance');
  String get enemies => _t('enemies');
  String get bestCombo => _t('bestCombo');
  String get menu => _t('menu');
  String get retry => _t('retry');
  String get ability => _t('ability');
  String get ult => _t('ult');
  String get hintControls => _t('hintControls');
  String get musicCredit => _t('musicCredit');

  String missionTitle(String id) {
    const en = {
      'daily_kill_50': 'Defeat 50 enemies',
      'daily_score_1000': 'Reach score 1,000',
      'daily_survive_90': 'Survive 90 seconds',
      'daily_coins_80': 'Collect 80 coins in a run',
      'perm_kill_1000': 'Defeat 1,000 enemies',
      'perm_level_10': 'Reach player level 10',
    };
    const ar = {
      'daily_kill_50': 'اهزم 50 عدوًا',
      'daily_score_1000': 'صل إلى نتيجة 1000',
      'daily_survive_90': 'ابقَ 90 ثانية',
      'daily_coins_80': 'اجمع 80 عملة في جولة',
      'perm_kill_1000': 'اهزم 1000 عدو',
      'perm_level_10': 'صل إلى المستوى 10',
    };
    return (isArabic ? ar : en)[id] ?? id;
  }

  String upgradeName(String id) {
    const en = {
      'damage': 'Damage',
      'health': 'Health',
      'speed': 'Speed',
      'attack_speed': 'Attack Speed',
      'crit_chance': 'Critical Chance',
      'crit_damage': 'Critical Damage',
      'coin_mul': 'Coin Multiplier',
      'ranged_reload': 'Ranged Reload',
      'xp_mul': 'XP Multiplier',
    };
    const ar = {
      'damage': 'الضرر',
      'health': 'الصحة',
      'speed': 'السرعة',
      'attack_speed': 'سرعة الهجوم',
      'crit_chance': 'فرصة الضربة الحرجة',
      'crit_damage': 'ضرر الضربة الحرجة',
      'coin_mul': 'مضاعف العملات',
      'ranged_reload': 'إعادة تعبئة الرمي',
      'xp_mul': 'مضاعف الخبرة',
    };
    return (isArabic ? ar : en)[id] ?? id;
  }

  String upgradeDescription(String id) {
    const en = {
      'damage': '+8% melee & ranged damage per level',
      'health': '+1 max HP per level',
      'speed': '+5% move speed & jump per level',
      'attack_speed': '+5% melee swing speed per level',
      'crit_chance': '+2% crit chance per level',
      'crit_damage': '+10% crit multiplier per level',
      'coin_mul': '+8% coins from kills per level',
      'ranged_reload': '+8% plasma reload speed per level',
      'xp_mul': '+8% XP from kills per level',
    };
    const ar = {
      'damage': '+8% ضرر هجوم ورمي لكل مستوى',
      'health': '+1 نقطة صحة قصوى لكل مستوى',
      'speed': '+5% سرعة حركة وقفز لكل مستوى',
      'attack_speed': '+5% سرعة ضربات قريبة لكل مستوى',
      'crit_chance': '+2% فرصة حرجة لكل مستوى',
      'crit_damage': '+10% مضاعف حرج لكل مستوى',
      'coin_mul': '+8% عملات من القتل لكل مستوى',
      'ranged_reload': '+8% سرعة إعادة تعبئة الرمي لكل مستوى',
      'xp_mul': '+8% خبرة من القتل لكل مستوى',
    };
    return (isArabic ? ar : en)[id] ?? id;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
