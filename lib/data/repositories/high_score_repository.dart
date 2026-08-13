import '../../core/constants/app_constants.dart';
import '../local/key_value_store.dart';

class HighScoreRepository {
  HighScoreRepository(this._storage);

  final KeyValueStore _storage;

  List<int> readTopScores({int limit = 3}) {
    final stored = _storage.read<List<dynamic>>(AppConstants.storageHighScores);
    if (stored != null && stored.isNotEmpty) {
      final scores = stored.map((e) => (e as num).toInt()).toList()..sort((a, b) => b.compareTo(a));
      return scores.take(limit).toList();
    }

    // Migrate legacy keys from the prototype.
    final legacy = [
      _storage.read<dynamic>(AppConstants.legacyScoreFirst),
      _storage.read<dynamic>(AppConstants.legacyScoreSecond),
      _storage.read<dynamic>(AppConstants.legacyScoreThird),
    ]
        .whereType<num>()
        .map((e) => e.toInt())
        .where((e) => e > 0)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (legacy.isNotEmpty) {
      // Fire-and-forget migration persist.
      _persist(legacy);
    }
    while (legacy.length < limit) {
      legacy.add(0);
    }
    return legacy.take(limit).toList();
  }

  Future<List<int>> submitScore(int score, {int limit = 3}) async {
    final current = readTopScores(limit: limit).where((s) => s > 0).toList();
    if (score > 0) current.add(score);
    current.sort((a, b) => b.compareTo(a));
    final uniqueTop = <int>[];
    for (final s in current) {
      if (uniqueTop.length >= limit) break;
      // Allow duplicate scores across runs.
      uniqueTop.add(s);
    }
    while (uniqueTop.length < limit) {
      uniqueTop.add(0);
    }
    await _persist(uniqueTop);
    return uniqueTop;
  }

  Future<void> _persist(List<int> scores) async {
    await _storage.write(AppConstants.storageHighScores, scores);
    // Keep legacy keys in sync for older builds.
    await _storage.write(AppConstants.legacyScoreFirst, scores.isNotEmpty ? scores[0] : 0);
    await _storage.write(AppConstants.legacyScoreSecond, scores.length > 1 ? scores[1] : 0);
    await _storage.write(AppConstants.legacyScoreThird, scores.length > 2 ? scores[2] : 0);
  }
}
