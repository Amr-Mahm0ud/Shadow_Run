import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../services/service_locator.dart';

class HighScoresScreen extends StatelessWidget {
  const HighScoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scores = AppServices.highScores
        .readTopScores()
        .where((s) => s > 0)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.highScores)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: scores.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.highScoresEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.mist,
                        ),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < scores.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.panel,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: i == 0
                                  ? AppColors.gold
                                  : AppColors.neonCyan.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            '${l10n.place(i)}  —  ${scores[i]}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
