enum Difficulty { easy, medium, hard }

class DifficultySettings {
  final Difficulty level;
  final int playerHp;
  final double enemyDamageMultiplier;
  final int durationSeconds;
  final String label;
  final String description;

  const DifficultySettings({
    required this.level,
    required this.playerHp,
    required this.enemyDamageMultiplier,
    required this.durationSeconds,
    required this.label,
    required this.description,
  });

  static const easy = DifficultySettings(
    level: Difficulty.easy,
    playerHp: 100,
    enemyDamageMultiplier: 0.6,
    durationSeconds: 120,
    label: "Easy",
    description: "High HP. Enemies deal less damage. Beginner-friendly.",
  );

  static const medium = DifficultySettings(
    level: Difficulty.medium,
    playerHp: 60,
    enemyDamageMultiplier: 1.0,
    durationSeconds: 90,
    label: "Medium",
    description: "Lower HP. Balanced enemy damage. Moderate challenge.",
  );

  static const hard = DifficultySettings(
    level: Difficulty.hard,
    playerHp: 1,
    enemyDamageMultiplier: 1.0,
    durationSeconds: 60,
    label: "Hard",
    description: "One hit defeats you. No room for mistakes.",
  );

  static const all = [easy, medium, hard];

  String get difficultyKey {
    switch (level) {
      case Difficulty.easy:
        return 'easy';
      case Difficulty.medium:
        return 'medium';
      case Difficulty.hard:
        return 'hard';
    }
  }
}
