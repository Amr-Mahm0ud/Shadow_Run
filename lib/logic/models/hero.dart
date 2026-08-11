class HeroCharacter {
  final List<String> runImages = const [
    'assets/images/run1.png',
    'assets/images/run4.png',
    'assets/images/run2.png',
    'assets/images/run3.png',
  ];
  final String jumpImage = 'assets/images/jump.png';
  final String attackImage = 'assets/images/attack.png';
  final List<String> dieImages = const [
    'assets/images/die1.png',
    'assets/images/die2.png',
    'assets/images/die3.png',
  ];
  String status = 'run';
  int lives = 3;

  void attack() {
    status = 'attack';
  }

  void run() {
    status = 'run';
  }

  void die() {
    if (status == 'attack') return;
    if (lives > 0) lives--;
    status = 'die';
  }
}
