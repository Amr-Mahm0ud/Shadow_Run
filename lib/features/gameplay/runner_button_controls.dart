import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../game/runner/runner_entities.dart';
import 'runner_gesture_layer.dart';

/// On-screen arcade pad: movement left, combat right.
class RunnerButtonControls extends StatelessWidget {
  const RunnerButtonControls({
    super.key,
    required this.onInput,
    required this.abilityReady,
    required this.ultimateReady,
    required this.dodgeReady,
    required this.rangedCharges,
  });

  final RunnerGestureHandler onInput;
  final bool abilityReady;
  final bool ultimateReady;
  final bool dodgeReady;
  final int rangedCharges;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final responsive = Responsive.of(context);
    final size = responsive.scale(58).clamp(54.0, 68.0);
    final combatSize = responsive.scale(64).clamp(58.0, 74.0);
    final gap = responsive.scale(10).clamp(8.0, 14.0);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            responsive.scale(12).clamp(10.0, 18.0),
            0,
            responsive.scale(12).clamp(10.0, 18.0),
            responsive.scale(10).clamp(8.0, 16.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MoveCluster(
                size: size,
                gap: gap,
                dodgeReady: dodgeReady,
                jumpLabel: l10n.btnJump,
                slideLabel: l10n.btnSlide,
                dodgeLabel: l10n.btnDodge,
                onInput: onInput,
              ),
              const Spacer(),
              _CombatCluster(
                size: combatSize,
                gap: gap,
                abilityReady: abilityReady,
                ultimateReady: ultimateReady,
                rangedCharges: rangedCharges,
                meleeLabel: l10n.btnMelee,
                rangedLabel: l10n.btnRanged,
                abilityLabel: l10n.btnAbility,
                onInput: onInput,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoveCluster extends StatelessWidget {
  const _MoveCluster({
    required this.size,
    required this.gap,
    required this.dodgeReady,
    required this.jumpLabel,
    required this.slideLabel,
    required this.dodgeLabel,
    required this.onInput,
  });

  final double size;
  final double gap;
  final bool dodgeReady;
  final String jumpLabel;
  final String slideLabel;
  final String dodgeLabel;
  final RunnerGestureHandler onInput;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PadButton(
          size: size,
          icon: Icons.keyboard_arrow_up_rounded,
          label: jumpLabel,
          color: AppColors.neonCyan,
          onTap: () => onInput(RunnerInput.jump, power: 1),
        ),
        SizedBox(height: gap),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PadButton(
              size: size,
              icon: Icons.swap_horiz_rounded,
              label: dodgeLabel,
              color: AppColors.gold,
              enabled: dodgeReady,
              onTap: () => onInput(RunnerInput.dodgeRight, power: 1),
            ),
            SizedBox(width: gap),
            _PadButton(
              size: size,
              icon: Icons.keyboard_arrow_down_rounded,
              label: slideLabel,
              color: AppColors.neonMagenta,
              onTap: () => onInput(RunnerInput.slide, power: 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _CombatCluster extends StatelessWidget {
  const _CombatCluster({
    required this.size,
    required this.gap,
    required this.abilityReady,
    required this.ultimateReady,
    required this.rangedCharges,
    required this.meleeLabel,
    required this.rangedLabel,
    required this.abilityLabel,
    required this.onInput,
  });

  final double size;
  final double gap;
  final bool abilityReady;
  final bool ultimateReady;
  final int rangedCharges;
  final String meleeLabel;
  final String rangedLabel;
  final String abilityLabel;
  final RunnerGestureHandler onInput;

  @override
  Widget build(BuildContext context) {
    final abilityLit = abilityReady || ultimateReady;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _PadButton(
          size: size * 0.92,
          icon: ultimateReady ? Icons.auto_awesome : Icons.bolt_rounded,
          label: abilityLabel,
          color: ultimateReady ? AppColors.gold : AppColors.neonCyan,
          enabled: abilityLit,
          onTap: () => onInput(
            ultimateReady ? RunnerInput.ultimate : RunnerInput.ability,
            power: 1,
          ),
        ),
        SizedBox(height: gap),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PadButton(
              size: size,
              icon: Icons.flash_on_rounded,
              label: meleeLabel,
              color: AppColors.ember,
              onTap: () => onInput(RunnerInput.melee, power: 1),
            ),
            SizedBox(width: gap),
            _PadButton(
              size: size,
              icon: Icons.adjust_rounded,
              label: rangedLabel,
              color: AppColors.neonCyan,
              enabled: rangedCharges > 0,
              onTap: () => onInput(RunnerInput.ranged, power: 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({
    required this.size,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final double size;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent = enabled ? color : AppColors.mist;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.panel.withValues(alpha: 0.7),
                border: Border.all(
                  color: accent.withValues(alpha: 0.85),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.28),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: accent, size: size * 0.38),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: (size * 0.16).clamp(8.0, 11.0),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
