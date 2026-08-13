import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_run/core/constants/app_constants.dart';
import 'package:shadow_run/data/local/key_value_store.dart';
import 'package:shadow_run/data/repositories/high_score_repository.dart';
import 'package:shadow_run/data/repositories/progress_repository.dart';

void main() {
  late MemoryStore storage;

  setUp(() {
    storage = MemoryStore();
  });

  test('HighScoreRepository ranks submitted scores', () async {
    final repo = HighScoreRepository(storage);
    await repo.submitScore(100);
    await repo.submitScore(250);
    await repo.submitScore(50);
    final top = repo.readTopScores();
    expect(top[0], 250);
    expect(top[1], 100);
    expect(top[2], 50);
  });

  test('ProgressRepository applies run rewards and levels up', () async {
    final repo = ProgressRepository(storage);
    final after = await repo.applyRunRewards(
      score: 40,
      coins: 12,
      xp: 120,
      kills: 4,
    );
    expect(after.coins, 12);
    expect(after.totalKills, 4);
    expect(after.totalRuns, 1);
    expect(after.bestScore, 40);
    expect(after.level, greaterThanOrEqualTo(2));
  });

  test('legacy high score keys migrate', () async {
    await storage.write(AppConstants.legacyScoreFirst, 80);
    await storage.write(AppConstants.legacyScoreSecond, 40);
    await storage.write(AppConstants.legacyScoreThird, 10);
    final repo = HighScoreRepository(storage);
    final top = repo.readTopScores();
    expect(top[0], 80);
    expect(top[1], 40);
    expect(top[2], 10);
  });
}
