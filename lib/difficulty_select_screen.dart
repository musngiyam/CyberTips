import 'package:flutter/material.dart';
import 'difficulty_settings.dart';
import 'game/cyber_game.dart';

class DifficultySelectScreen extends StatelessWidget {
  final int characterIndex;
  const DifficultySelectScreen({super.key, required this.characterIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.blueGrey],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'SELECT DIFFICULTY',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: DifficultySettings.all
                        .map(
                          (d) => _DifficultyCard(
                            settings: d,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CyberGame(
                                    characterIndex: characterIndex,
                                    difficulty: d,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final DifficultySettings settings;
  final VoidCallback onTap;

  const _DifficultyCard({required this.settings, required this.onTap});

  Color get _color {
    switch (settings.level) {
      case Difficulty.easy:
        return const Color(0xFF2E7D32);
      case Difficulty.medium:
        return const Color(0xFFEF6C00);
      case Difficulty.hard:
        return const Color(0xFFB71C1C);
    }
  }

  String get _durationLabel {
    final mins = settings.durationSeconds ~/ 60;
    final secs = settings.durationSeconds % 60;
    if (secs == 0) return "${mins}m";
    return "${mins}m ${secs}s";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings.label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              settings.description,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  _durationLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
