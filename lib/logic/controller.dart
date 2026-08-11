import 'package:get_storage/get_storage.dart';

class HighScore {
  static const String _key1 = 'first';
  static const String _key2 = 'second';
  static const String _key3 = 'third';

  final GetStorage _box = GetStorage();

  void saveScore(int first, int second, int third) {
    _box.write(_key1, first);
    _box.write(_key2, second);
    _box.write(_key3, third);
  }

  List<int> readScores() {
    return [
      _box.read(_key1) ?? 0,
      _box.read(_key2) ?? 0,
      _box.read(_key3) ?? 0,
    ];
  }

  void updateScore(int score) {
    final scores = readScores();
    final first = scores[0];
    final second = scores[1];
    final third = scores[2];
    if (first == 0 || first < score) {
      saveScore(score, first, second);
    } else if (second == 0 || second < score) {
      saveScore(first, score, second);
    } else if (third == 0 || third < score) {
      saveScore(first, second, score);
    }
  }
}
