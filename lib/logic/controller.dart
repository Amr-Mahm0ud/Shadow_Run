import 'package:get_storage/get_storage.dart';

class HighScore {
  final String key1 = 'first';
  final String key2 = 'second';
  final String key3 = 'third';
  final box = GetStorage();

  saveScore(first, second, third) {
    box.write(key1, first);
    box.write(key2, second);
    box.write(key3, third);
  }

  readScores() {
    return [
      box.read(key1) ?? 0,
      box.read(key2) ?? 0,
      box.read(key3) ?? 0,
    ];
  }

  updateScore(score) {
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
