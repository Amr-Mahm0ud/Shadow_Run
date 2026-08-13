import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_repository.dart';
import '../../services/service_locator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = AppServices.settings.read();
  }

  Future<void> _persist() async {
    await AppServices.settings.save(_settings);
    await AppServices.feedback.applyVolumes();
    await AppServices.feedback.syncMusic();
    if (!mounted) return;
    setState(() {});
    SettingsScope.maybeOf(context)?.notifyChanged();
  }

  Future<void> _update(void Function(AppSettings s) edit) async {
    edit(_settings);
    await _persist();
    await AppServices.feedback.uiTap();
  }

  Future<void> _showPrivacy() async {
    final l10n = AppLocalizations.of(context);
    await AppServices.feedback.uiTap();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.privacy,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.privacyBody,
                    style: const TextStyle(color: AppColors.mist, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.close),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAbout() async {
    final l10n = AppLocalizations.of(context);
    await AppServices.feedback.uiTap();
    if (!mounted) return;
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationLegalese: AppConstants.aboutLine,
      children: [
        const SizedBox(height: 12),
        Text(
          l10n.aboutBody,
          style: const TextStyle(color: AppColors.mist),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.musicCredit,
          style: const TextStyle(color: AppColors.mist, fontSize: 12),
        ),
      ],
    );
  }

  Widget _volumeTile({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(color: AppColors.mist, fontSize: 13),
              ),
            ],
          ),
          Slider(
            value: value.clamp(0, 1),
            onChanged: _settings.muteAll
                ? null
                : (v) async {
                    setState(() => onChanged(v));
                    await AppServices.settings.save(_settings);
                    await AppServices.feedback.applyVolumes();
                  },
            onChangeEnd: (_) => _persist(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            title: Text(l10n.muteAll),
            subtitle: Text(l10n.muteAllSubtitle),
            value: _settings.muteAll,
            onChanged: (v) => _update((s) {
              s.muteAll = v;
              s.musicEnabled = !v;
              s.sfxEnabled = !v;
            }),
          ),
          _volumeTile(
            title: l10n.musicVolume,
            value: _settings.musicVolume,
            onChanged: (v) {
              _settings.musicVolume = v;
              _settings.musicEnabled = v > 0.001;
            },
          ),
          _volumeTile(
            title: l10n.sfxVolume,
            value: _settings.sfxVolume,
            onChanged: (v) {
              _settings.sfxVolume = v;
              _settings.sfxEnabled = v > 0.001;
            },
          ),
          _volumeTile(
            title: l10n.uiVolume,
            value: _settings.uiVolume,
            onChanged: (v) => _settings.uiVolume = v,
          ),
          SwitchListTile(
            title: Text(l10n.vibration),
            subtitle: Text(l10n.vibrationSubtitle),
            value: _settings.vibrationEnabled,
            onChanged: (v) => _update((s) => s.vibrationEnabled = v),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.language,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('English')),
                    ButtonSegment(value: 'ar', label: Text('العربية')),
                  ],
                  selected: {_settings.localeCode},
                  onSelectionChanged: (selected) {
                    final code = selected.first;
                    _update((s) => s.localeCode = code);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.privacy),
            subtitle: Text(l10n.privacySubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPrivacy,
          ),
          ListTile(
            title: Text(l10n.about),
            subtitle:
                Text('${AppConstants.aboutLine} · v${AppConstants.appVersion}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAbout,
          ),
        ],
      ),
    );
  }
}

class SettingsScope extends InheritedNotifier<ValueNotifier<int>> {
  const SettingsScope({
    super.key,
    required ValueNotifier<int> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static SettingsScope? maybeOf(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<SettingsScope>();
    return element?.widget as SettingsScope?;
  }

  void notifyChanged() => notifier?.value++;
}
