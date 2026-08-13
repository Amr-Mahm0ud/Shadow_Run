import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_run/data/local/key_value_store.dart';
import 'package:shadow_run/data/repositories/mission_repository.dart';
import 'package:shadow_run/game/systems/missions.dart';

void main() {
  test('missions track run progress and grant claim rewards once', () async {
    final store = MemoryStore();
    final repo = MissionRepository(store);
    final day = DateTime.utc(2030, 1, 15);

    await repo.recordRun(
      runKills: 20,
      totalKills: 20,
      score: 800,
      surviveSeconds: 40,
      coinsEarned: 40,
      playerLevel: 2,
      now: day,
    );
    await repo.recordRun(
      runKills: 30,
      totalKills: 50,
      score: 1200,
      surviveSeconds: 95,
      coinsEarned: 90,
      playerLevel: 3,
      now: day,
    );

    final after = repo.read(now: day);
    final killDaily =
        MissionCatalog.daily.firstWhere((m) => m.id == 'daily_kill_50');
    final scoreDaily =
        MissionCatalog.daily.firstWhere((m) => m.id == 'daily_score_1000');
    final surviveDaily =
        MissionCatalog.daily.firstWhere((m) => m.id == 'daily_survive_90');

    expect(repo.progressFor(killDaily, after), 50);
    expect(repo.progressFor(scoreDaily, after), 1000);
    expect(repo.progressFor(surviveDaily, after), 90);
    expect(repo.isComplete(killDaily, after), isTrue);

    final reward = await repo.claim(killDaily, now: day);
    expect(reward, isNotNull);
    expect(reward!.coins, killDaily.rewardCoins);
    expect(reward.gems, greaterThan(0));

    final again = await repo.claim(killDaily, now: day);
    expect(again, isNull);
  });
}
