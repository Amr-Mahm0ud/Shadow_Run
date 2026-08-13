import 'package:flutter/material.dart';

import '../../core/branding/brand_logo.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/repositories/progress_repository.dart';
import '../../game/player/characters.dart';
import '../../services/service_locator.dart';

class CharactersScreen extends StatefulWidget {
  const CharactersScreen({super.key});

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  late var _progress = AppServices.progress.read();
  late String _previewId;

  @override
  void initState() {
    super.initState();
    _previewId =
        CharacterCatalog.migrateSelectedId(_progress.selectedCharacterId);
    if (_previewId != _progress.selectedCharacterId) {
      _progress.selectedCharacterId = _previewId;
      AppServices.progress.save(_progress);
    }
  }

  CharacterDefinition get _selected => CharacterCatalog.byId(_previewId);

  Future<void> _select(String id) async {
    await AppServices.feedback.uiTap();
    _progress.selectedCharacterId = id;
    await AppServices.progress.save(_progress);
    setState(() {
      _previewId = id;
      _progress = AppServices.progress.read();
    });
  }

  Future<void> _unlock(CharacterDefinition character) async {
    if (_progress.coins < character.unlockCostCoins) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notEnoughCoins)),
      );
      return;
    }
    _progress.coins -= character.unlockCostCoins;
    _progress.unlockedCharacterIds = {
      ..._progress.unlockedCharacterIds.map(CharacterCatalog.migrateSelectedId),
      character.id,
    }.toList();
    _progress.selectedCharacterId = character.id;
    await AppServices.progress.save(_progress);
    setState(() {
      _previewId = character.id;
      _progress = AppServices.progress.read();
    });
  }

  bool _unlocked(CharacterDefinition c) {
    final ids = _progress.unlockedCharacterIds
        .map(CharacterCatalog.migrateSelectedId)
        .toSet();
    return ids.contains(c.id) || c.unlockCostCoins == 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final responsive = Responsive.of(context);
    final character = _selected;
    final unlocked = _unlocked(character);
    final equipped = CharacterCatalog.migrateSelectedId(
          _progress.selectedCharacterId,
        ) ==
        character.id;

    return Scaffold(
      backgroundColor: CharacterCatalog.brandBg,
      appBar: AppBar(
        title: Row(
          children: [
            BrandLogo(
              variant: BrandLogoVariant.symbol,
              height: 28,
            ),
            const SizedBox(width: 10),
            Text(l10n.operatives),
          ],
        ),
        backgroundColor: Colors.transparent,
        toolbarHeight: responsive.isLandscape ? 44 : kToolbarHeight,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            responsive.scale(12),
            responsive.scale(4),
            responsive.scale(12),
            responsive.scale(8),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Landscape / short height: side-by-side so fixed rows never
              // starve the preview (was overflowing by ~27px on iPhone).
              final split = constraints.maxHeight < 520 ||
                  responsive.isLandscape;

              if (split) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _CharacterPreview(
                        character: character,
                        responsive: responsive,
                        compact: true,
                      ),
                    ),
                    SizedBox(width: responsive.scale(12)),
                    Expanded(
                      flex: 6,
                      child: _DetailsPanel(
                        character: character,
                        progress: _progress,
                        responsive: responsive,
                        previewId: _previewId,
                        unlocked: unlocked,
                        equipped: equipped,
                        isUnlocked: _unlocked,
                        onPreview: (id) => setState(() => _previewId = id),
                        onUnlock: () => _unlock(character),
                        onSelect: () => _select(character.id),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: _CharacterPreview(
                      character: character,
                      responsive: responsive,
                    ),
                  ),
                  SizedBox(height: responsive.scale(8)),
                  _DetailsPanel(
                    character: character,
                    progress: _progress,
                    responsive: responsive,
                    previewId: _previewId,
                    unlocked: unlocked,
                    equipped: equipped,
                    isUnlocked: _unlocked,
                    onPreview: (id) => setState(() => _previewId = id),
                    onUnlock: () => _unlock(character),
                    onSelect: () => _select(character.id),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.character,
    required this.progress,
    required this.responsive,
    required this.previewId,
    required this.unlocked,
    required this.equipped,
    required this.isUnlocked,
    required this.onPreview,
    required this.onUnlock,
    required this.onSelect,
  });

  final CharacterDefinition character;
  final PlayerProgress progress;
  final Responsive responsive;
  final String previewId;
  final bool unlocked;
  final bool equipped;
  final bool Function(CharacterDefinition) isUnlocked;
  final ValueChanged<String> onPreview;
  final VoidCallback onUnlock;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final thumbH = responsive.scale(68).clamp(52.0, 80.0);

    final thumbs = SizedBox(
      height: thumbH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CharacterCatalog.all.length,
        separatorBuilder: (_, __) => SizedBox(width: responsive.scale(8)),
        itemBuilder: (context, index) {
          final c = CharacterCatalog.all[index];
          return _CharThumb(
            character: c,
            selected: c.id == previewId,
            locked: !isUnlocked(c),
            height: thumbH,
            onTap: () => onPreview(c.id),
          );
        },
      ),
    );

    final actions = Row(
      children: [
        Expanded(
          child: Text(
            '${progress.coins} ${l10n.coins}'.toUpperCase(),
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
              fontSize: responsive.sp(13),
            ),
          ),
        ),
        if (!unlocked)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: character.accent,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.scale(14),
                vertical: responsive.scale(8),
              ),
              minimumSize: Size(0, responsive.scale(36)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onUnlock,
            child: Text(l10n.unlock(character.unlockCostCoins)),
          )
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: equipped ? AppColors.panel : character.accent,
              foregroundColor: equipped ? AppColors.mist : Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.scale(14),
                vertical: responsive.scale(8),
              ),
              minimumSize: Size(0, responsive.scale(36)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: equipped ? null : onSelect,
            child: Text(equipped ? l10n.equipped : l10n.select),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite &&
            constraints.maxHeight < double.infinity;

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            thumbs,
            SizedBox(height: responsive.scale(6)),
            _StatBars(character: character, compact: true),
            SizedBox(height: responsive.scale(6)),
            _KitRow(character: character, compact: true),
            SizedBox(height: responsive.scale(8)),
            actions,
          ],
        );

        if (!hasBoundedHeight) return body;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: body,
        );
      },
    );
  }
}

class _CharacterPreview extends StatelessWidget {
  const _CharacterPreview({
    required this.character,
    required this.responsive,
    this.compact = false,
  });

  final CharacterDefinition character;
  final Responsive responsive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: character.accent,
          letterSpacing: 2,
          fontSize: responsive.sp(compact ? 22 : 28),
        );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            character.accent.withValues(alpha: 0.18),
            const Color(0xFF0A0E17),
            Colors.black,
          ],
        ),
        border: Border.all(color: character.accent.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.scale(8),
                responsive.scale(8),
                responsive.scale(8),
                responsive.scale(compact ? 52 : 64),
              ),
              child: Image.asset(
                character.portraitArt,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  character.portrait,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.person,
                    size: responsive.scale(72),
                    color: character.accent,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: responsive.scale(12),
            right: responsive.scale(12),
            bottom: responsive.scale(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  character.codename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
                Text(
                  character.tagline.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mist,
                    letterSpacing: 1.2,
                    fontSize: responsive.sp(compact ? 11 : 13),
                  ),
                ),
                Text(
                  character.role.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: character.accentSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: responsive.sp(compact ? 10 : 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CharThumb extends StatelessWidget {
  const _CharThumb({
    required this.character,
    required this.selected,
    required this.locked,
    required this.onTap,
    required this.height,
  });

  final CharacterDefinition character;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final width = (height * 0.85).clamp(56.0, 78.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.panel,
          border: Border.all(
            color: selected ? character.accent : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Expanded(
              child: Opacity(
                opacity: locked ? 0.45 : 1,
                child: Image.asset(
                  character.portrait,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.person,
                    color: character.accent,
                    size: 22,
                  ),
                ),
              ),
            ),
            Text(
              character.codename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: character.accent,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBars extends StatelessWidget {
  const _StatBars({required this.character, this.compact = false});
  final CharacterDefinition character;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = character.baseStats;
    final gap = compact ? 1.0 : 2.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _bar('HEALTH', s.maxHealth / 5, character.accent, gap),
        _bar('SPEED', s.speed / 1.5, character.accent, gap),
        _bar('MELEE', character.meleeMul / 1.7, character.accent, gap),
        _bar('RANGED', character.rangedMul / 1.7, character.accent, gap),
      ],
    );
  }

  Widget _bar(String label, double value, Color color, double gap) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: gap),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.mist,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value.clamp(0.08, 1),
                minHeight: compact ? 6 : 8,
                backgroundColor: Colors.white10,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KitRow extends StatelessWidget {
  const _KitRow({required this.character, this.compact = false});
  final CharacterDefinition character;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final weaponSize = compact ? 44.0 : 56.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _kitCard(
            'ABILITY',
            character.abilityName,
            character.abilityDescription,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _kitCard(
            'ULTIMATE',
            character.ultimateName,
            character.ultimateDescription,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: weaponSize,
          height: weaponSize,
          child: Image.asset(
            character.weaponArt,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset(
              character.weapon,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _kitCard(String label, String title, String body) {
    return Container(
      padding: EdgeInsets.all(compact ? 6 : 8),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: character.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: character.accent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          Text(
            body,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.mist, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
