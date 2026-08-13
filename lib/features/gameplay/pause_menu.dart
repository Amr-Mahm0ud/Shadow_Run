import 'package:flutter/material.dart';

import '../../core/branding/brand_logo.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

class PauseMenu extends StatelessWidget {
  const PauseMenu({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onSettings,
    required this.onHome,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onSettings;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final l10n = AppLocalizations.of(context);
    final gap = responsive.scale(6).clamp(4.0, 8.0);
    final btnH = responsive.scale(40).clamp(36.0, 44.0);

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: responsive.scale(360).clamp(240.0, 400.0),
                  maxHeight: constraints.maxHeight,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.scale(16),
                    vertical: responsive.scale(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandLogo(
                        variant: BrandLogoVariant.symbol,
                        height: responsive.scale(28).clamp(24.0, 32.0),
                      ),
                      SizedBox(height: gap),
                      Text(
                        l10n.paused,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: responsive.sp(24),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                      ),
                      SizedBox(height: gap * 1.5),
                      _PauseButton(
                        label: l10n.resume,
                        height: btnH,
                        onPressed: onResume,
                      ),
                      SizedBox(height: gap),
                      _PauseButton(
                        label: l10n.restart,
                        height: btnH,
                        onPressed: onRestart,
                      ),
                      SizedBox(height: gap),
                      Row(
                        children: [
                          Expanded(
                            child: _PauseButton(
                              label: l10n.settings,
                              height: btnH,
                              onPressed: onSettings,
                            ),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child: _PauseButton(
                              label: l10n.home,
                              height: btnH,
                              onPressed: onHome,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({
    required this.label,
    required this.onPressed,
    required this.height,
  });

  final String label;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.panel,
          foregroundColor: Colors.white,
          minimumSize: Size.fromHeight(height),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          overflow: TextOverflow.visible,
          softWrap: false,
        ),
      ),
    );
  }
}
