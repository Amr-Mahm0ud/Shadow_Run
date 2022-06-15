class Enemy {
  String image = 'assets/images/enemy.png';

  String status = 'run';

  die(heroStatus) {
    //end game when x = 0.5 to -0.2
    if (heroStatus == 'attack') {
      status = 'die';
    }
  }

  run() {
    status = 'run';
  }
}
