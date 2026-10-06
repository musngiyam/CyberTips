import 'package:supabase_flutter/supabase_flutter.dart';

class ScoreEntry {
  final String username;
  final int score;
  final int? timeTakenSeconds;

  ScoreEntry({
    required this.username,
    required this.score,
    this.timeTakenSeconds,
  });
}

class ScoreboardService {
  final _client = Supabase.instance.client;

  /// Fetch top scores for a specific difficulty ('easy', 'medium', 'hard'),
  /// or all difficulties combined when [difficulty] is null (overall).
  /// Returns at most one entry per username: their single best score.
  Future<List<ScoreEntry>> fetchScores({
    String? difficulty,
    int limit = 20,
  }) async {
    var query = _client
        .from('scores')
        .select('username, score, time_taken_seconds');

    if (difficulty != null) {
      query = query.eq('difficulty', difficulty);
    }

    // Fetch a larger pool so we can pick each user's best after grouping.
    final result = await query
        .order('score', ascending: false)
        .limit(limit * 20);

    final Map<String, ScoreEntry> bestByUser = {};
    for (final row in (result as List)) {
      final username = row['username'] as String;
      final score = row['score'] as int;
      final timeTaken = row['time_taken_seconds'] as int?;

      final existing = bestByUser[username];
      if (existing == null || score > existing.score) {
        bestByUser[username] = ScoreEntry(
          username: username,
          score: score,
          timeTakenSeconds: timeTaken,
        );
      }
    }

    final deduped = bestByUser.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return deduped.take(limit).toList();
  }

  /// Overall = each user's best score in Easy + best in Medium + best in Hard.
  Future<List<ScoreEntry>> fetchOverallScores({int limit = 20}) async {
    final result = await _client
        .from('scores')
        .select('username, difficulty, score');

    // best[username][difficulty] = highest score for that user+difficulty
    final Map<String, Map<String, int>> best = {};

    for (final row in (result as List)) {
      final username = row['username'] as String;
      final difficulty = row['difficulty'] as String;
      final score = row['score'] as int;

      best.putIfAbsent(username, () => {});
      final current = best[username]![difficulty] ?? 0;
      if (score > current) {
        best[username]![difficulty] = score;
      }
    }

    final List<ScoreEntry> overall = best.entries.map((entry) {
      final scores = entry.value;
      final total =
          (scores['easy'] ?? 0) +
          (scores['medium'] ?? 0) +
          (scores['hard'] ?? 0);
      return ScoreEntry(username: entry.key, score: total);
    }).toList();

    overall.sort((a, b) => b.score.compareTo(a.score));

    return overall.take(limit).toList();
  }

  /// Returns the single highest score this user has ever achieved,
  /// across all difficulties. Returns 0 if they have no scores yet.
  Future<int> fetchHighestScore(String username) async {
    final result = await _client
        .from('scores')
        .select('score')
        .eq('username', username)
        .order('score', ascending: false)
        .limit(1);

    final rows = result as List;
    if (rows.isEmpty) return 0;
    return rows.first['score'] as int;
  }

  /// Call this after a quest/battle completes to save the result.
  Future<void> submitScore({
    required String username,
    required String difficulty,
    required int score,
    int? timeTakenSeconds,
  }) async {
    await _client.from('scores').insert({
      'username': username,
      'difficulty': difficulty,
      'score': score,
      'time_taken_seconds': timeTakenSeconds,
    });
  }
}
