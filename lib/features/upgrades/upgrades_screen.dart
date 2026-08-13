import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../game/systems/upgrades.dart';
import '../../services/service_locator.dart';

class UpgradesScreen extends StatefulWidget {
  const UpgradesScreen({super.key});

  @override
  State<UpgradesScreen> createState() => _UpgradesScreenState();
}

class _UpgradesScreenState extends State<UpgradesScreen> {
  final _progress = AppServices.progress.read();

  Future<void> _buy(UpgradeDefinition upgrade) async {
    final level = _progress.upgradeLevels[upgrade.id] ?? 0;
    if (level >= upgrade.maxLevel) return;
    final cost = upgrade.costForLevel(level);
    if (_progress.coins < cost) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notEnoughCoins)),
      );
      return;
    }
    _progress.coins -= cost;
    final next = Map<String, int>.from(_progress.upgradeLevels);
    next[upgrade.id] = level + 1;
    _progress.upgradeLevels = next;
    await AppServices.progress.save(_progress);
    await AppServices.feedback.success();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.upgradesTitle(_progress.coins)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: UpgradeCatalog.all.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final upgrade = UpgradeCatalog.all[index];
          final level = _progress.upgradeLevels[upgrade.id] ?? 0;
          final maxed = level >= upgrade.maxLevel;
          final cost = upgrade.costForLevel(level);
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).upgradeName(upgrade.id),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      Text(
                        AppLocalizations.of(context)
                            .upgradeDescription(upgrade.id),
                      ),
                      Text(l10n.levelProgress(level, upgrade.maxLevel)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: maxed ? null : () => _buy(upgrade),
                  child: Text(maxed ? l10n.max : '$cost'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
