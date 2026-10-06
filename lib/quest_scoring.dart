class QuestScoring {
  /// Points awarded for completing this round of a 3-round quest chain.
  static int roundBonus(int roundNumber) {
    switch (roundNumber) {
      case 1:
        return 100;
      case 2:
        return 200;
      case 3:
        return 300;
      default:
        return 0;
    }
  }
}
