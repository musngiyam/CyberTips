import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'cipher_decode_widget.dart';

class QuestTwoScreen extends StatefulWidget {
  final int characterIndex;

  const QuestTwoScreen({super.key, required this.characterIndex});

  @override
  State<QuestTwoScreen> createState() => _QuestTwoScreenState();
}

class _QuestTwoScreenState extends State<QuestTwoScreen> {
  int _currentSlide = 0;
  bool _isBattling = false;
  bool _battleEnded = false;
  double _heroOpacity = 1.0;
  double _enemyOpacity = 1.0;
  late final AudioPlayer _battleAudioPlayer;

  final List<Map<String, String>> _dialogueSlides = [
    {"speaker": "Rival", "text": "You made it through the forest, but this encrypted gateway is locked!"},
    {"speaker": "Hero", "text": "A cipher lock? Watch me decode this instantly."},
    {"speaker": "Rival", "text": "Prove your cryptographic skills then!"},
  ];

  @override
  void initState() {
    super.initState();
    _playBattleMusic();
  }

  Future<void> _playBattleMusic() async {
    _battleAudioPlayer = AudioPlayer();
    try {
      // Start at 0 volume to smoothly fade in battle.mp3
      await _battleAudioPlayer.setVolume(0.0);
      await _battleAudioPlayer.setReleaseMode(ReleaseMode.loop);
      await _battleAudioPlayer.play(AssetSource('audio/battle.mp3'));

      // Smooth fade in
      for (double vol = 0.0; vol <= 1.0; vol += 0.1) {
        if (!mounted) break;
        await _battleAudioPlayer.setVolume(vol);
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      debugPrint("Error playing battle audio: $e");
    }
  }

  Future<void> _fadeOutAndExit() async {
    try {
      // Smooth fade out of battle.mp3 before leaving
      for (double vol = 1.0; vol >= 0.0; vol -= 0.1) {
        await _battleAudioPlayer.setVolume(vol);
        await Future.delayed(const Duration(milliseconds: 40));
      }
      await _battleAudioPlayer.stop();
      await _battleAudioPlayer.dispose();
    } catch (e) {
      debugPrint("Error stopping battle audio: $e");
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _battleAudioPlayer.dispose();
    super.dispose();
  }

  String _getCharacterAsset() {
    switch (widget.characterIndex) {
      case 0:
        return 'assets/images/char1.gif';
      case 1:
        return 'assets/images/char2.gif';
      case 2:
      default:
        return 'assets/images/char3.gif';
    }
  }

  void _advanceOrStartBattle() {
    if (_currentSlide < _dialogueSlides.length - 1) {
      setState(() {
        _currentSlide++;
      });
    } else {
      setState(() {
        _isBattling = true;
      });
    }
  }

  void _showCustomForestDialog({
    required String title,
    required Color titleColor,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A11),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF324C2C), width: 1),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFCFD8DC),
                    fontSize: 11,
                    height: 1.3,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF263322),
                    side: const BorderSide(color: Color(0xFF558B2F), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext); // Close dialog box cleanly
                    onPressed();
                  },
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Color(0xFFFFF9C4),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleWinBattle() async {
    setState(() {
      _enemyOpacity = 0.0;
      _battleEnded = true;
    });

    // Fade out audio before showing win dialog
    try {
      for (double vol = 1.0; vol >= 0.0; vol -= 0.2) {
        await _battleAudioPlayer.setVolume(vol);
        await Future.delayed(const Duration(milliseconds: 40));
      }
      await _battleAudioPlayer.stop();
    } catch (_) {}

    if (mounted) {
      _showCustomForestDialog(
        title: "VICTORY!",
        titleColor: const Color(0xFF81C784),
        message: "You successfully decrypted the cipher and bypassed the barrier!",
        buttonText: "Continue",
        onPressed: () {
          Navigator.pop(context); // Exit Quest 2 screen
        },
      );
    }
  }

  void _handleLoseBattle() async {
    setState(() {
      _heroOpacity = 0.0;
      _battleEnded = true;
    });

    // Fade out audio before showing lose dialog
    try {
      for (double vol = 1.0; vol >= 0.0; vol -= 0.2) {
        await _battleAudioPlayer.setVolume(vol);
        await Future.delayed(const Duration(milliseconds: 40));
      }
      await _battleAudioPlayer.stop();
    } catch (_) {}

    if (mounted) {
      _showCustomForestDialog(
        title: "TIME'S UP!",
        titleColor: const Color(0xFFFF8A80),
        message: "You ran out of time and failed to crack the cipher code!",
        buttonText: "Exit",
        onPressed: () {
          Navigator.pop(context); // Exit Quest 2 screen
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final currentDialogue = _dialogueSlides[_currentSlide];
    final bool isHeroSpeaking = currentDialogue['speaker'] == "Hero";

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _fadeOutAndExit();
      },
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isBattling ? null : _advanceOrStartBattle,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/battleg.png',
                  fit: BoxFit.cover,
                ),
              ),

              // Hero Character with slow fade-out transition when losing
              Positioned(
                left: screenWidth * 0.05,
                top: screenHeight * 0.44,
                child: AnimatedOpacity(
                  opacity: _heroOpacity,
                  duration: const Duration(milliseconds: 1200),
                  child: SizedBox(
                    width: 400,
                    height: 400,
                    child: Image.asset(
                      _getCharacterAsset(),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Enemy Character with slow fade-out transition when winning
              Positioned(
                left: screenWidth * 0.52,
                top: screenHeight * 0.28,
                child: AnimatedOpacity(
                  opacity: _enemyOpacity,
                  duration: const Duration(milliseconds: 1200),
                  child: SizedBox(
                    width: 420,
                    height: 420,
                    child: Transform.scale(
                      scaleX: -1.0,
                      scaleY: 1.0,
                      child: Image.asset(
                        'assets/images/enemy1.gif',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 15,
                right: 20,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.black54,
                  onPressed: _fadeOutAndExit,
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),

              if (!_isBattling) ...[
                if (isHeroSpeaking)
                  Positioned(
                    left: screenWidth * 0.15,
                    top: screenHeight * 0.53,
                    child: CustomPaint(
                      painter: SpeechBubblePainter(tailAlignLeft: true),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 240),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        child: Text(
                          currentDialogue['text']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (!isHeroSpeaking)
                  Positioned(
                    left: screenWidth * 0.62,
                    top: screenHeight * 0.37,
                    child: CustomPaint(
                      painter: SpeechBubblePainter(tailAlignLeft: true),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 240),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        child: Text(
                          currentDialogue['text']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],

              // Cipher decode widget disappears completely right when battle ends, leaving only the notification popup
              if (_isBattling && !_battleEnded)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CipherDecodeWidget(
                      onWinBattle: _handleWinBattle,
                      onLoseBattle: _handleLoseBattle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpeechBubblePainter extends CustomPainter {
  final bool tailAlignLeft;

  SpeechBubblePainter({required this.tailAlignLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    double radius = 22.0;

    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height - 8);
    path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    double tailX = tailAlignLeft ? 30.0 : size.width - 30.0;
    path.moveTo(tailX - 8, size.height - 8);
    path.lineTo(tailX, size.height);
    path.lineTo(tailX + 8, size.height - 8);

    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}