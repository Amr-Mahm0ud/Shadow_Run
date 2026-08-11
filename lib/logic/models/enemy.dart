class Enemy {
  final String image = 'assets/images/enemy.png';
  String status = 'run';

  void die(String heroStatus) {
    if (heroStatus == 'attack') {
      status = 'die';
    }
  }

  void run() {
    status = 'run';
  }
}
