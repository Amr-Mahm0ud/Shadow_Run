enum GamePhase {
  idle,
  countdown,
  playing,
  paused,
  levelUp,
  boss,
  gameOver,
  reward,
  restarting,
}

extension GamePhaseX on GamePhase {
  bool get isInteractive =>
      this == GamePhase.playing || this == GamePhase.boss;

  bool get allowsAttack => this == GamePhase.playing || this == GamePhase.boss;
}
