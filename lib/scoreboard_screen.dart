import 'package:flutter/material.dart';
import 'scoreboard_service.dart';

class ScoreboardDialog extends StatefulWidget {
  const ScoreboardDialog({super.key});

  @override
  State<ScoreboardDialog> createState() => _ScoreboardDialogState();
}

class _ScoreboardDialogState extends State<ScoreboardDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String?>> _tabs = [
    {'label': 'Overall', 'value': null},
    {'label': 'Easy', 'value': 'easy'},
    {'label': 'Medium', 'value': 'medium'},
    {'label': 'Hard', 'value': 'hard'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: 420,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E281A).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8FBC8F), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "SCOREBOARD",
                    style: TextStyle(
                      color: Color(0xFFE8F5E9),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF81C784),
              labelColor: const Color(0xFF81C784),
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontSize: 12),
              tabs: _tabs.map((t) => Tab(text: t['label'])).toList(),
            ),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: _tabs
                    .map((t) => _ScoreList(difficulty: t['value']))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreList extends StatelessWidget {
  final String? difficulty;
  const _ScoreList({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final Future<List<ScoreEntry>> future = difficulty == null
        ? ScoreboardService().fetchOverallScores()
        : ScoreboardService().fetchScores(difficulty: difficulty);

    return FutureBuilder<List<ScoreEntry>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: Color(0xFF81C784)),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "Failed to load scores.",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
        final scores = snapshot.data ?? [];
        if (scores.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "No scores yet.",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: scores.length,
          itemBuilder: (context, index) {
            final entry = scores[index];
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF2E7D32),
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(
                entry.username,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              subtitle: entry.timeTakenSeconds != null
                  ? Text(
                      "${entry.timeTakenSeconds}s",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    )
                  : null,
              trailing: Text(
                "${entry.score} pts",
                style: const TextStyle(
                  color: Color(0xFF81C784),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
