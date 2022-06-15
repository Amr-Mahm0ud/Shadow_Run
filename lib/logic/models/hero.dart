class HeroCharacter {
  List runImages = [
    'assets/images/run1.png',
    'assets/images/run4.png',
    'assets/images/run2.png',
    'assets/images/run3.png',
  ];
  String jumpImage = 'assets/images/jump.png';
  String attackImage = 'assets/images/attack.png';
  List dieImages = [
    'assets/images/die1.png',
    'assets/images/die2.png',
    'assets/images/die3.png',
  ];
  String status = 'run';
  int lives = 3;

  attack() {
    status = 'attack';
  }

  run() {
    status = 'run';
  }

  die() {
    //end game when x = 0.5 to -0.2

    if (status != 'attack') {
      if (lives == 0) {
        status = 'die';
      } else {
        lives--;
        status = 'die';
      }
    }
  }
}
