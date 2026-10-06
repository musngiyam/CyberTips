import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class CipherDecodeWidget extends StatefulWidget {
  final VoidCallback onWinBattle;
  final VoidCallback onLoseBattle;

  const CipherDecodeWidget({
    super.key,
    required this.onWinBattle,
    required this.onLoseBattle,
  });

  @override
  State<CipherDecodeWidget> createState() => _CipherDecodeWidgetState();
}

class _CipherDecodeWidgetState extends State<CipherDecodeWidget> {
  // 10 Random Cybersecurity Cipher Challenges (Plaintext & Ciphertext)
  final List<Map<String, String>> _challenges = [
    {"plain": "ACCESS", "cipher": "EDFNXS"}, // Shift +3
    {"plain": "FIREWALL", "cipher": "ILVHUDOO"}, // Shift +3
    {"plain": "SECURE", "cipher": "VHFXUH"}, // Shift +3
    {"plain": "CIPHER", "cipher": "FLSKHU"}, // Shift +3
    {"plain": "CLIENT", "cipher": "FLOENT"}, // Shift +3
    {"plain": "SERVER", "cipher": "VIYHUX"}, // Shift +3
    {"plain": "TOKENZ", "cipher": "WRKHQC"}, // Shift +3
    {"plain": "HASHED", "cipher": "KDVKHG"}, // Shift +3
    {"plain": "SOCKET", "cipher": "VRFNHW"}, // Shift +3
    {"plain": "PACKET", "cipher": "SDFKHW"}, // Shift +3
  ];

  late Map<String, String> _currentChallenge;
  late String _targetWord;
  late String _cipherWord;
  late List<String> _userLetters;

  // 2 Minutes Timer
  static const int _totalTimeSeconds = 120;
  int _timeLeft = _totalTimeSeconds;
  Timer? _timer;
  Timer? _tipTimer;
  bool _gameOver = false;

  int _currentTipIndex = 0;

  // 10 Security Cipher & Encryption Tips
  final List<String> _securityTips = [
    "Caesar cipher shifts letters by a fixed number. Here, the alphabet is shifted by +3 positions.",
    "Always use strong cryptographic protocols like AES-256 for securing sensitive data at rest.",
    "Never hardcode encryption keys or database credentials directly into your source code repository.",
    "Transport Layer Security (TLS) ensures that data sent between clients and servers remains encrypted.",
    "Hashing algorithms like SHA-256 turn data into a fixed-size string for secure password verification.",
    "Salting passwords adds random data before hashing to protect against precomputed rainbow table attacks.",
    "Symmetric encryption uses the same secret key for both encryption and decryption operations.",
    "Asymmetric encryption utilizes public and private key pairs for secure data exchange and signing.",
    "Regularly audit your cryptographic libraries and dependencies to mitigate known vulnerabilities.",
    "Zero-trust architecture assumes breach and verifies every user request regardless of network location."
  ];

  @override
  void initState() {
    super.initState();
    // Randomly select one of the 10 cybersecurity words
    _currentChallenge = _challenges[Random().nextInt(_challenges.length)];
    _targetWord = _currentChallenge["plain"]!;
    _cipherWord = _currentChallenge["cipher"]!;
    _userLetters = List.filled(_targetWord.length, "");

    _startTimer();
    _startTipCycler();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        if (!_gameOver) {
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

  void _onKeyPress(String letter) {
    if (_gameOver) return;
    setState(() {
      for (int i = 0; i < _userLetters.length; i++) {
        if (_userLetters[i].isEmpty) {
          _userLetters[i] = letter;
          break;
        }
      }
    });
  }

  void _onDelete() {
    if (_gameOver) return;
    setState(() {
      for (int i = _userLetters.length - 1; i >= 0; i--) {
        if (_userLetters[i].isNotEmpty) {
          _userLetters[i] = "";
          break;
        }
      }
    });
  }

  void _checkAnswer() {
    if (_gameOver) return;
    String currentAttempt = _userLetters.join();
    if (currentAttempt == _targetWord) {
      _timer?.cancel();
      _tipTimer?.cancel();
      _gameOver = true;
      widget.onWinBattle();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incorrect decryption! Check the shift scheme above.", style: TextStyle(color: Colors.white, decoration: TextDecoration.none)),
          backgroundColor: Color(0xFFD32F2F),
          duration: Duration(milliseconds: 1000),
        ),
      );
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
      width: 380,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header row with title and timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "DECRYPT: Cipher Matrix Shift",
                  style: TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                    decoration: TextDecoration.none,
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
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Cipher Matrix Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF131A11),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF324C2C), width: 1),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("PLAIN:  ", style: TextStyle(color: Colors.grey, fontSize: 8, decoration: TextDecoration.none)),
                        Text("A B C D E F G H I J K L M N O P Q R S T U V W X Y Z", style: TextStyle(color: Color(0xFF81C784), fontSize: 7, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("CIPHER: ", style: TextStyle(color: Colors.grey, fontSize: 8, decoration: TextDecoration.none)),
                        Text("D E F G H I J K L M N O P Q R S T U V W X Y Z A B C", style: TextStyle(color: Color(0xFF81C784), fontSize: 7, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Tips Section
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
                    "SECURITY TIP",
                    style: TextStyle(
                      color: Color(0xFF81C784),
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      letterSpacing: 0.6,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Tip ${_currentTipIndex + 1}/10: ${_securityTips[_currentTipIndex]}",
                    style: const TextStyle(
                      color: Color(0xFFCFD8DC),
                      fontSize: 7.5,
                      height: 1.15,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Cipherword label & Cipherword display
            const Text(
              "DECRYPT THIS CIPHERWORD:",
              style: TextStyle(color: Colors.grey, fontSize: 8.5, letterSpacing: 0.5, decoration: TextDecoration.none),
            ),
            const SizedBox(height: 2),
            Text(
              _cipherWord,
              style: const TextStyle(
                color: Color(0xFF80DEEA),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 6),

            // User Input Slots (Dynamic length matching target word securely within bounds)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_targetWord.length, (index) {
                return Container(
                  width: 33,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A11),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF00ACC1), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      _userLetters[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            // On-screen compact keyboard rows
            _buildKeyboardRow(["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]),
            const SizedBox(height: 3),
            _buildKeyboardRow(["A", "S", "D", "F", "G", "H", "J", "K", "L"]),
            const SizedBox(height: 3),
            _buildKeyboardRow(["Z", "X", "C", "V", "B", "N", "M"]),

            const SizedBox(height: 8),

            // Action Buttons (Delete & Check Answer)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 30,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD32F2F), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        backgroundColor: const Color(0xFF261A1A),
                      ),
                      onPressed: _onDelete,
                      child: const Text(
                        "DELETE",
                        style: TextStyle(color: Color(0xFFFF8A80), fontSize: 9, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: _checkAnswer,
                      child: const Text(
                        "CHECK ANSWER",
                        style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> letters) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: letters.map((letter) {
        return Container(
          width: 30,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 1.2),
          child: Material(
            color: const Color(0xFF162214),
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _onKeyPress(letter),
              child: Center(
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}