import 'package:flutter/material.dart';

import '../../core/branding/brand_logo.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/repositories/progress_repository.dart';
import '../../services/service_locator.dart';
import '../characters/characters_screen.dart';
import '../gameplay/action_runner_screen.dart';
import '../high_scores/high_scores_screen.dart';
import '../missions/missions_screen.dart';
import '../settings/settings_screen.dart';
import '../upgrades/upgrades_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PlayerProgress _progress;

  @override
  void initState() {
    super.initState();
    _progress = AppServices.progress.read();
    AppServices.feedback.setGameplayMusic(false);
  }

  void _refresh() => setState(() => _progress = AppServices.progress.read());

  Future<void> _open(Widget page) async {
    await AppServices.feedback.uiTap();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.voidBlack,
              AppColors.deepNavy,
              Color(0xFF1A1030),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: responsive.pagePadding,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final brand = _BrandPanel(
                  progress: _progress,
                  theme: theme,
                  responsive: responsive,
                  onPlay: () async {
                    await AppServices.feedback.uiTap();
                    await Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const ActionRunnerScreen(),
                      ),
                    );
                  },
                );
                final menu = _MenuGrid(
                  responsive: responsive,
                  onOpen: _open,
                );

                if (responsive.useSplitHome) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: brand),
                      SizedBox(width: responsive.scale(20)),
                      Expanded(flex: 4, child: menu),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: brand),
                    SizedBox(height: responsive.scale(12)),
                    Expanded(flex: 6, child: menu),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({
    required this.progress,
    required this.theme,
    required this.responsive,
    required this.onPlay,
  });

  final PlayerProgress progress;
  final ThemeData theme;
  final Responsive responsive;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final logoHeight = responsive.scale(responsive.isTablet ? 72 : 56);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandLogo(
          variant: BrandLogoVariant.full,
          height: logoHeight.clamp(44.0, 88.0),
          width: double.infinity,
          alignment: Alignment.centerLeft,
        ),
        SizedBox(height: responsive.scale(12)),
        Text(
          l10n.tagline,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: responsive.sp(16),
            color: AppColors.neonCyan,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: responsive.scale(4)),
        Text(
          l10n.taglineSecondary,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: responsive.sp(15),
            color: AppColors.mist,
          ),
        ),
        const Spacer(),
        Wrap(
          spacing: responsive.scale(10),
          runSpacing: responsive.scale(10),
          children: [
            _StatChip(
              label: l10n.levelShort(progress.level),
              value: 'XP ${progress.xp}',
              responsive: responsive,
            ),
            _StatChip(
              label: l10n.coins,
              value: '${progress.coins}',
              accent: AppColors.gold,
              responsive: responsive,
            ),
            _StatChip(
              label: l10n.gems,
              value: '${progress.gems}',
              accent: AppColors.neonMagenta,
              responsive: responsive,
            ),
            _StatChip(
              label: l10n.best,
              value: '${progress.bestScore}',
              responsive: responsive,
            ),
          ],
        ),
        const Spacer(),
        SizedBox(
          width: responsive.scale(220).clamp(160, 280),
          child: ElevatedButton(
            onPressed: onPlay,
            child: Text(l10n.play),
          ),
        ),
      ],
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({
    required this.responsive,
    required this.onOpen,
  });

  final Responsive responsive;
  final Future<void> Function(Widget page) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tiles = <(String, Widget)>[
      (l10n.characters, const CharactersScreen()),
      (l10n.upgrades, const UpgradesScreen()),
      (l10n.missions, const MissionsScreen()),
      (l10n.highScores, const HighScoresScreen()),
      (l10n.settings, const SettingsScreen()),
    ];

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsive.homeGridColumns,
        mainAxisSpacing: responsive.scale(12),
        crossAxisSpacing: responsive.scale(12),
        childAspectRatio: responsive.menuTileAspect,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) {
        final tile = tiles[index];
        return _MenuTile(
          label: tile.$1,
          responsive: responsive,
          onTap: () => onOpen(tile.$2),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.responsive,
    this.accent = AppColors.neonCyan,
  });

  final String label;
  final String value;
  final Responsive responsive;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.scale(14),
        vertical: responsive.scale(10),
      ),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: accent,
                  fontSize: responsive.sp(20),
                ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.label,
    required this.onTap,
    required this.responsive,
  });

  final String label;
  final VoidCallback onTap;
  final Responsive responsive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: responsive.scale(8)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: responsive.sp(18),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
