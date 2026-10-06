import 'dart:async';
import 'package:flutter/material.dart';

class MemoryMatchWidget extends StatefulWidget {
  final VoidCallback onWinBattle;
  final VoidCallback onLoseBattle;

  const MemoryMatchWidget({
    super.key,
    required this.onWinBattle,
    required this.onLoseBattle,
  });

  @override
  State<MemoryMatchWidget> createState() => _MemoryMatchWidgetState();
}

class _MemoryMatchWidgetState extends State<MemoryMatchWidget> {
  late List<Map<String, dynamic>> _cards;
  int? _firstSelectedIdx;
  bool _isChecking = false;
  int _matchesFound = 0;

  // 2 Minutes Timer
  static const int _totalTimeSeconds = 120;
  int _timeLeft = _totalTimeSeconds;
  Timer? _timer;
  Timer? _tipTimer;
  bool _gameOver = false;

  int _currentTipIndex = 0;

  // 10 Security Tips Pool
  final List<String> _securityTips = [
    "Always lock your operating system terminal (Win + L) when leaving your physical workstation unattended.",
    "Use strong, unique passwords or passphrases for every single account you own.",
    "Enable Multi-Factor Authentication (MFA) everywhere it is supported to protect against credential theft.",
    "Never click links or download attachments from unknown or unexpected email senders.",
    "Keep your operating systems, browsers, and security software updated with the latest patches.",
    "Verify website URLs carefully before entering sensitive credentials to avoid phishing traps.",
    "Regularly back up critical data offline or to a secure, encrypted cloud environment.",
    "Avoid using public, unsecured Wi-Fi networks without activating a trusted Virtual Private Network (VPN).",
    "Review app permissions on your mobile devices and revoke access for tools you no longer use.",
    "Report suspicious emails or potential security anomalies to your IT security team immediately."
  ];

  // Pool of 10 cybersecurity card items to randomize from
  final List<Map<String, dynamic>> _masterCardPool = [
    {"name": "AUTH KEY", "icon": Icons.vpn_key, "color": Colors.amber},
    {"name": "MALWARE", "icon": Icons.bug_report, "color": Colors.orangeAccent},
    {"name": "SPAM", "icon": Icons.mark_email_read, "color": Colors.lightGreenAccent},
    {"name": "PHISHING", "icon": Icons.phishing, "color": Colors.cyanAccent},
    {"name": "ZERO-TRUST", "icon": Icons.admin_panel_settings, "color": Colors.amberAccent},
    {"name": "BRUTEFORCE", "icon": Icons.password, "color": Colors.deepOrangeAccent},
    {"name": "FIREWALL", "icon": Icons.local_fire_department, "color": Colors.redAccent},
    {"name": "ENCRYPT", "icon": Icons.lock, "color": Colors.yellowAccent},
    {"name": "VPN TUNNEL", "icon": Icons.security, "color": Colors.greenAccent},
    {"name": "MFA CODE", "icon": Icons.verified_user, "color": Colors.limeAccent},
  ];

  @override
  void initState() {
    super.initState();
    _initializeRandomCards();
    _startTimer();
    _startTipCycler();
  }

  void _initializeRandomCards() {
    List<Map<String, dynamic>> shuffledPool = List.from(_masterCardPool)..shuffle();
    List<Map<String, dynamic>> selectedTypes = shuffledPool.take(6).toList();

    List<Map<String, dynamic>> tempCards = [];
    for (var type in selectedTypes) {
      tempCards.add({...type, "id": type["name"]});
      tempCards.add({...type, "id": type["name"]});
    }
    tempCards.shuffle();

    _cards = tempCards.map((card) => {
      ...card,
      "isFlipped": false,
      "isMatched": false,
    }).toList();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        if (!_gameOver && _matchesFound < 6) {
          _gameOver = true;
          widget.onLoseBattle();
        }
      }
    });
  }

  void _startTipCycler() {
    _tipTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _securityTips.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tipTimer?.cancel();
    super.dispose();
  }

  void _onCardTap(int index) {
    if (_isChecking || _gameOver) return;
    if (_cards[index]["isFlipped"] || _cards[index]["isMatched"]) return;

    setState(() {
      _cards[index]["isFlipped"] = true;
    });

    if (_firstSelectedIdx == null) {
      _firstSelectedIdx = index;
    } else {
      int firstIdx = _firstSelectedIdx!;
      _firstSelectedIdx = null;

      if (_cards[firstIdx]["id"] == _cards[index]["id"]) {
        setState(() {
          _cards[firstIdx]["isMatched"] = true;
          _cards[index]["isMatched"] = true;
          _matchesFound++;
        });

        if (_matchesFound == 6) {
          _timer?.cancel();
          _tipTimer?.cancel();
          _gameOver = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            widget.onWinBattle();
          });
        }
      } else {
        _isChecking = true;
        Timer(const Duration(milliseconds: 800), () {
          setState(() {
            _cards[firstIdx]["isFlipped"] = false;
            _cards[index]["isFlipped"] = false;
            _isChecking = false;
          });
        });
      }
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E281A).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8FBC8F), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "DEFEAT ENEMY: Match All 6 Pairs",
                style: TextStyle(
                  color: Color(0xFFE8F5E9),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E2723),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD32F2F)),
                ),
                child: Text(
                  "Time: ${_formatTime(_timeLeft)}",
                  style: const TextStyle(
                    color: Color(0xFFFF8A80),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Difficulty: Easy & Tips Section on top left
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF131A11),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF324C2C), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DIFFICULTY: EASY",
                  style: TextStyle(
                    color: Color(0xFF81C784),
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Tip ${_currentTipIndex + 1}/10: ${_securityTips[_currentTipIndex]}",
                  style: const TextStyle(
                    color: Color(0xFFCFD8DC),
                    fontSize: 7.5,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SizedBox(
              height: 175, // Increased height so bottom cards are fully visible
              child: GridView.builder(
                itemCount: _cards.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  childAspectRatio: 1.25, // Adjusted ratio to give better vertical room for icons and text
                ),
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  bool isFlipped = card["isFlipped"] || card["isMatched"];

                  return GestureDetector(
                    onTap: () => _onCardTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: isFlipped ? const Color(0xFF2E3D2A) : const Color(0xFF263322),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isFlipped ? const Color(0xFF81C784) : const Color(0xFF558B2F),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: isFlipped
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(card["icon"], color: card["color"], size: 16),
                            const SizedBox(height: 2),
                            Text(
                              card["name"],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFFF9C4),
                                fontSize: 4.8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                            : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF33442C), Color(0xFF1B2617)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.eco, color: Colors.green.shade700, size: 14),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}