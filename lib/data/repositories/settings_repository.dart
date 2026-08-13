import '../../core/constants/app_constants.dart';
import '../local/key_value_store.dart';

class AppSettings {
  AppSettings({
    this.masterVolume = 1.0,
    this.musicVolume = 0.32,
    this.sfxVolume = 0.80,
    this.uiVolume = 0.45,
    this.muteAll = false,
    this.musicEnabled = true,
    this.sfxEnabled = true,
    this.vibrationEnabled = true,
    this.localeCode = 'en',
  });

  double masterVolume;
  double musicVolume;
  double sfxVolume;
  double uiVolume;
  bool muteAll;

  /// Legacy toggles — kept for migration; volumes + muteAll are authoritative.
  bool musicEnabled;
  bool sfxEnabled;
  bool vibrationEnabled;
  String localeCode;

  Map<String, dynamic> toJson() => {
        'masterVolume': masterVolume,
        'musicVolume': musicVolume,
        'sfxVolume': sfxVolume,
        'uiVolume': uiVolume,
        'muteAll': muteAll,
        'musicEnabled': musicEnabled,
        'sfxEnabled': sfxEnabled,
        'vibrationEnabled': vibrationEnabled,
        'localeCode': localeCode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final musicEnabled = json['musicEnabled'] as bool? ?? true;
    final sfxEnabled = json['sfxEnabled'] as bool? ?? true;
    final muteAll = json['muteAll'] as bool? ?? false;

    double musicVol = (json['musicVolume'] as num?)?.toDouble() ?? 0.32;
    double sfxVol = (json['sfxVolume'] as num?)?.toDouble() ?? 0.80;
    // Migrate old bool-only settings into volumes once.
    if (json['musicVolume'] == null && !musicEnabled) musicVol = 0;
    if (json['sfxVolume'] == null && !sfxEnabled) sfxVol = 0;

    return AppSettings(
      masterVolume: (json['masterVolume'] as num?)?.toDouble() ?? 1.0,
      musicVolume: musicVol,
      sfxVolume: sfxVol,
      uiVolume: (json['uiVolume'] as num?)?.toDouble() ?? 0.45,
      muteAll: muteAll,
      musicEnabled: musicEnabled,
      sfxEnabled: sfxEnabled,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      localeCode: json['localeCode'] as String? ?? 'en',
    );
  }
}

class SettingsRepository {
  SettingsRepository(this._storage);

  final KeyValueStore _storage;

  AppSettings read() {
    final raw = _storage.read<Map<String, dynamic>>(AppConstants.storageSettings);
    if (raw == null) return AppSettings();
    return AppSettings.fromJson(raw);
  }

  Future<void> save(AppSettings settings) async {
    await _storage.write(AppConstants.storageSettings, settings.toJson());
  }
}
