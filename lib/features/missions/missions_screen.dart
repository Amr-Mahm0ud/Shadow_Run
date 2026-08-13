import 'package:flutter/material.dart';

import '../../core/config/game_config.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/mission_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../game/systems/missions.dart';
import '../../services/service_locator.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  late MissionProgressState _missions;
  late PlayerProgress _progress;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _missions = AppServices.missions.read();
    _progress = AppServices.progress.read();
  }

  Future<void> _claim(MissionDefinition mission) async {
    final reward = await AppServices.missions.claim(mission);
    if (reward == null) return;
    _progress.coins += reward.coins;
    _progress.xp += reward.xp;
    _progress.gems += reward.gems;
    while (_progress.xp >= GameConfig.xpForLevel(_progress.level)) {
      _progress.xp -= GameConfig.xpForLevel(_progress.level);
      _progress.level += 1;
    }
    await AppServices.progress.save(_progress);
    await AppServices.feedback.success();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.claimedSnack(reward.coins, reward.xp, reward.gems),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.missions)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.daily, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            l10n.missionsHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mist,
                ),
          ),
          const SizedBox(height: 8),
          for (final mission in MissionCatalog.daily)
            _MissionTile(
              mission: mission,
              progressValue:
                  AppServices.missions.progressFor(mission, _missions),
              claimed: AppServices.missions.isClaimed(mission, _missions),
              onClaim: () => _claim(mission),
            ),
          const SizedBox(height: 20),
          Text(l10n.permanent, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          for (final mission in MissionCatalog.permanent)
            _MissionTile(
              mission: mission,
              progressValue:
                  AppServices.missions.progressFor(mission, _missions),
              claimed: AppServices.missions.isClaimed(mission, _missions),
              onClaim: () => _claim(mission),
            ),
        ],
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({
    required this.mission,
    required this.progressValue,
    required this.claimed,
    required this.onClaim,
  });

  final MissionDefinition mission;
  final int progressValue;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clamped = progressValue.clamp(0, mission.target);
    final done = clamped >= mission.target;
    final canClaim = done && !claimed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: claimed
              ? AppColors.gold.withValues(alpha: 0.5)
              : done
                  ? AppColors.neonCyan
                  : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).missionTitle(mission.id),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
              if (canClaim)
                ElevatedButton(
                  onPressed: onClaim,
                  child: Text(l10n.claim),
                )
              else if (claimed)
                Text(
                  l10n.claimed,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.gold,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: mission.target == 0 ? 0 : clamped / mission.target,
            color: AppColors.neonCyan,
            backgroundColor: Colors.white12,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.missionReward(
              clamped,
              mission.target,
              mission.rewardCoins,
              mission.rewardXp,
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mist,
                ),
          ),
        ],
      ),
    );
  }
}
