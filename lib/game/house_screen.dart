import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../models/components/player.dart';
import 'hard1.dart';
import 'hard2.dart';
import 'hard3.dart'; // Linked import for Hard 3 Screen (Missing Letter Challenge)

class SpeechBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path();
    double radius = 16.0;
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height - 10);
    RRect rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    path.addRRect(rRect);
    path.moveTo(size.width * 0.25, size.height - 10);
    path.lineTo(size.width * 0.15, size.height);
    path.lineTo(size.width * 0.35, size.height - 10);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------
// BATTLE SELECTION SCREEN (battleg.png background with battle.mp3 audio)
// ---------------------------------------------------------
class BattleSelectionScreen extends StatefulWidget {
  final int characterIndex;
  const BattleSelectionScreen({super.key, required this.characterIndex});

  @override
  State<BattleSelectionScreen> createState() => _BattleSelectionScreenState();
}

class _BattleSelectionScreenState extends State<BattleSelectionScreen> {
  final AudioPlayer _battleBgmPlayer = AudioPlayer();
  final double _bgmVolume = 1.0;

  @override
  void initState() {
    super.initState();
    _battleBgmPlayer.setReleaseMode(ReleaseMode.loop);
    _startBattleMusicWithFadeIn();
  }

  Future<void> _startBattleMusicWithFadeIn() async {
    try {
      await _battleBgmPlayer.setVolume(0.0);
      await _battleBgmPlayer.play(AssetSource('audio/battle.mp3'));
      for (double vol = 0.1; vol <= _bgmVolume; vol += 0.1) {
        if (!mounted) break;
        await _battleBgmPlayer.setVolume(vol > _bgmVolume ? _bgmVolume : vol);
        await Future.delayed(const Duration(milliseconds: 40));
      }
      await _battleBgmPlayer.setVolume(_bgmVolume);
    } catch (e) {
      debugPrint("Battle background music error: $e");
    }
  }

  Future<void> _fadeOutBattleBgm() async {
    try {
      for (double vol = _bgmVolume; vol >= 0.0; vol -= 0.1) {
        await _battleBgmPlayer.setVolume(vol < 0 ? 0 : vol);
        await Future.delayed(const Duration(milliseconds: 40));
      }
      await _battleBgmPlayer.stop();
    } catch (e) {
      debugPrint("Battle fade out error: $e");
    }
  }

  @override
  void dispose() {
    _battleBgmPlayer.dispose();
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

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/battleg.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.3),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Text(
                  "DEFEAT THE OGRE",
                  style: TextStyle(
                    color: Color(0xFFFFCDD2),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Choose a challenge to defeat the Ogre and save the village!",
                  style: TextStyle(
                    color: Color(0xFFCFD8DC),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBattleChoiceCard(
                        context,
                        title: "Flipcard",
                        subtitle: "Memory Challenge",
                        color: const Color(0xFF1565C0),
                        borderColor: const Color(0xFF64B5F6),
                        onTap: () async {
                          await _fadeOutBattleBgm();
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Hard1Screen(characterIndex: widget.characterIndex),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildBattleChoiceCard(
                        context,
                        title: "Caesar Matrix",
                        subtitle: "Cipher Puzzle",
                        color: const Color(0xFF4A148C),
                        borderColor: const Color(0xFFBA68C8),
                        onTap: () async {
                          await _fadeOutBattleBgm();
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Hard2Screen(characterIndex: widget.characterIndex),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildBattleChoiceCard(
                        context,
                        title: "Missing Letter",
                        subtitle: "Word Completion",
                        color: const Color(0xFFB71C1C),
                        borderColor: const Color(0xFFEF5350),
                        onTap: () async {
                          await _fadeOutBattleBgm();
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Hard3Screen(characterIndex: widget.characterIndex),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: screenWidth * 0.05,
            top: screenHeight * 0.44,
            child: SizedBox(
              width: 400,
              height: 400,
              child: Image.asset(
                _getCharacterAsset(),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            left: screenWidth * 0.52,
            top: (screenHeight * 0.28) - 70,
            child: SizedBox(
              width: 420,
              height: 420,
              child: Transform.scale(
                scaleX: -1.0,
                scaleY: 1.0,
                child: Image.asset(
                  'assets/images/ogre.gif',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: FloatingActionButton.small(
              backgroundColor: Colors.black54,
              child: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {
                await _fadeOutBattleBgm();
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleChoiceCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required Color color,
        required Color borderColor,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 190,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 36, color: Colors.amber),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Play",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// ROOM SCREEN
// ---------------------------------------------------------
class RoomScreen extends StatefulWidget {
  final int characterIndex;
  const RoomScreen({super.key, required this.characterIndex});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  late Player player = Player(
    x: 0,
    y: 0,
    characterIndex: widget.characterIndex,
  );
  final AudioPlayer _footstepPlayer = AudioPlayer();
  bool _isWalkingSoundPlaying = false;
  Timer? _footstepStopTimer;
  bool _isInitialized = false;
  double _broX = 0;
  double _broY = 0;
  bool _canTalkToBro = false;

  @override
  void initState() {
    super.initState();
    _footstepPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _footstepStopTimer?.cancel();
    _footstepPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleFootstepInput() async {
    _footstepStopTimer?.cancel();
    try {
      if (!_isWalkingSoundPlaying) {
        _isWalkingSoundPlaying = true;
        await _footstepPlayer.play(AssetSource('audio/walk.mp3'));
      } else {
        await _footstepPlayer.seek(Duration.zero);
      }
    } catch (e) {
      debugPrint("Footstep audio error: $e");
    }
    _footstepStopTimer = Timer(const Duration(milliseconds: 250), () async {
      if (_isWalkingSoundPlaying) {
        _isWalkingSoundPlaying = false;
        try {
          await _footstepPlayer.stop();
        } catch (e) {
          debugPrint("Stop footstep audio error: $e");
        }
      }
    });
  }

  void _stopFootstepsImmediate() {
    _footstepStopTimer?.cancel();
    if (_isWalkingSoundPlaying) {
      _isWalkingSoundPlaying = false;
      _footstepPlayer.stop();
    }
  }

  void _movePlayer(double dx, double dy, double screenWidth, double screenHeight) {
    _handleFootstepInput();
    setState(() {
      double nextX = player.x + dx;
      double nextY = player.y + dy;
      double minX = screenWidth * 0.15;
      double maxX = screenWidth * 0.80;
      double minY = screenHeight * 0.65;
      double maxY = screenHeight * 0.88;
      nextX = nextX.clamp(minX, maxX);
      nextY = nextY.clamp(minY, maxY);
      player.x = nextX;
      player.y = nextY;
      if (dx < 0) {
        player.isFacingLeft = true;
      } else if (dx > 0) {
        player.isFacingLeft = false;
      }
      double distance = ((player.x - _broX) * (player.x - _broX) + (player.y - _broY) * (player.y - _broY));
      _canTalkToBro = distance < 25000.0;
    });
  }

  void _showBroDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF281A1A).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBC8F8F), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Help",
                  style: TextStyle(color: Color(0xFFFFEBEE), fontWeight: FontWeight.bold, fontSize: 14, decoration: TextDecoration.none),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1111),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4C2C2C), width: 1),
                  ),
                  child: const Text(
                    "Please help! An ogre is attacking our village and destroying everything!",
                    style: TextStyle(color: Color(0xFFCFD8DC), fontSize: 11, decoration: TextDecoration.none),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BattleSelectionScreen(characterIndex: widget.characterIndex),
                        ),
                      );
                    },
                    child: const Text(
                      "I'll help you",
                      style: TextStyle(color: Color(0xFFFFF9C4), fontWeight: FontWeight.bold, fontSize: 11, decoration: TextDecoration.none),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;
          if (!_isInitialized) {
            _broX = screenWidth * 0.44 + 80 + 24;
            _broY = (screenHeight * 0.86 - 24 - 24) - 35;
            player.x = screenWidth * 0.58;
            player.y = (screenHeight * 0.77) - 12;
            player.isFacingLeft = true;
            _isInitialized = true;
          }
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/pc1.gif',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                left: _broX,
                top: _broY - 20,
                child: SizedBox(
                  width: 156,
                  height: 156,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(1.0, 1.0, 1.0),
                    child: Image.asset(
                      'assets/images/bro.gif',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: _broX + 60,
                top: _broY - 30,
                child: CustomPaint(
                  painter: SpeechBubblePainter(),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                    child: const Text(
                      "Can you help me",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: player.x,
                top: player.y - 15,
                child: Transform.scale(
                  scale: 1.82,
                  child: player.render(),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.black54,
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    _stopFootstepsImmediate();
                    Navigator.pop(context);
                  },
                ),
              ),
              if (_canTalkToBro)
                Positioned(
                  bottom: 30,
                  right: 30,
                  child: GestureDetector(
                    onTap: () => _showBroDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white38, width: 2),
                      ),
                      child: const Text(
                        "Talk",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 20,
                left: 20,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _movePlayer(0, -12, screenWidth, screenHeight),
                          child: const SizedBox(width: 40, height: 40, child: Icon(Icons.arrow_drop_up, size: 32, color: Colors.white)),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _movePlayer(0, 12, screenWidth, screenHeight),
                          child: const SizedBox(width: 40, height: 40, child: Icon(Icons.arrow_drop_down, size: 32, color: Colors.white)),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _movePlayer(-12, 0, screenWidth, screenHeight),
                          child: const SizedBox(width: 40, height: 40, child: Icon(Icons.arrow_left, size: 32, color: Colors.white)),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _movePlayer(12, 0, screenWidth, screenHeight),
                          child: const SizedBox(width: 40, height: 40, child: Icon(Icons.arrow_right, size: 32, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// HOUSE SCREEN
// ---------------------------------------------------------
class HouseScreen extends StatefulWidget {
  final int characterIndex;
  const HouseScreen({super.key, required this.characterIndex});

  @override
  State<HouseScreen> createState() => _HouseScreenState();
}

class _HouseScreenState extends State<HouseScreen> {
  late Player player = Player(
    x: 0,
    y: 0,
    characterIndex: widget.characterIndex,
  );
  final AudioPlayer _footstepPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _isWalkingSoundPlaying = false;
  Timer? _footstepStopTimer;
  bool _isInitialized = false;
  bool _canTalkToKnight = false;
  final double _bgmVolume = 1.0;

  @override
  void initState() {
    super.initState();
    _footstepPlayer.setReleaseMode(ReleaseMode.loop);
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _startBackgroundMusicWithFadeIn();
  }

  Future<void> _startBackgroundMusicWithFadeIn() async {
    try {
      await _bgmPlayer.setVolume(0.0);
      await _bgmPlayer.play(AssetSource('audio/haru.mp3'));
      for (double vol = 0.1; vol <= _bgmVolume; vol += 0.1) {
        if (!mounted) break;
        await _bgmPlayer.setVolume(vol > _bgmVolume ? _bgmVolume : vol);
        await Future.delayed(const Duration(milliseconds: 40));
      }
      await _bgmPlayer.setVolume(_bgmVolume);
    } catch (e) {
      debugPrint("House background music fade-in error: $e");
    }
  }

  Future<void> _fadeOutBgm() async {
    try {
      for (double vol = _bgmVolume; vol >= 0.0; vol -= 0.1) {
        await _bgmPlayer.setVolume(vol < 0 ? 0 : vol);
        await Future.delayed(const Duration(milliseconds: 40));
      }
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint("House fade out error: $e");
    }
  }

  @override
  void dispose() {
    _footstepStopTimer?.cancel();
    _footstepPlayer.dispose();
    _bgmPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleFootstepInput() async {
    _footstepStopTimer?.cancel();
    try {
      if (!_isWalkingSoundPlaying) {
        _isWalkingSoundPlaying = true;
        await _footstepPlayer.play(AssetSource('audio/walk.mp3'));
      } else {
        await _footstepPlayer.seek(Duration.zero);
      }
    } catch (e) {
      debugPrint("Footstep audio error: $e");
    }
    _footstepStopTimer = Timer(const Duration(milliseconds: 250), () async {
      if (_isWalkingSoundPlaying) {
        _isWalkingSoundPlaying = false;
        try {
          await _footstepPlayer.stop();
        } catch (e) {
          debugPrint("Stop footstep audio error: $e");
        }
      }
    });
  }

  void _stopFootstepsImmediate() {
    _footstepStopTimer?.cancel();
    if (_isWalkingSoundPlaying) {
      _isWalkingSoundPlaying = false;
      _footstepPlayer.stop();
    }
  }

  void _movePlayer(double dx, double dy, double screenWidth, double screenHeight) {
    _handleFootstepInput();
    setState(() {
      double nextX = player.x + dx;
      double nextY = player.y + dy;
      double minX = screenWidth * 0.20;
      double maxX = screenWidth * 0.75;
      double minY = screenHeight * 0.70;
      double maxY = screenHeight * 0.88;
      nextX = nextX.clamp(minX, maxX);
      nextY = nextY.clamp(minY, maxY);
      player.x = nextX;
      player.y = nextY;
      if (dx < 0) {
        player.isFacingLeft = true;
      } else if (dx > 0) {
        player.isFacingLeft = false;
      }
      double knightX = screenWidth * 0.44;
      double knightY = screenHeight * 0.83;
      double distance = ((player.x - knightX) * (player.x - knightX) + (player.y - knightY) * (player.y - knightY));
      _canTalkToKnight = distance < 18000.0;
    });
  }

  void _showKnightDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E281A).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF8FBC8F), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "House Guard",
                  style: TextStyle(color: Color(0xFFE8F5E9), fontWeight: FontWeight.bold, fontSize: 14, decoration: TextDecoration.none),
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
                  child: const Text(
                    "Ah, you have the key! You are fully verified and permitted to enter the inner room.",
                    style: TextStyle(color: Color(0xFFCFD8DC), fontSize: 11, decoration: TextDecoration.none),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomScreen(characterIndex: widget.characterIndex),
                        ),
                      );
                    },
                    child: const Text(
                      "Enter",
                      style: TextStyle(color: Color(0xFFFFF9C4), fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.none),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;
          if (!_isInitialized) {
            player.x = screenWidth * 0.65;
            player.y = (screenHeight * 0.80) - 12;
            player.isFacingLeft = true;
            _isInitialized = true;
          }
          double knightX = screenWidth * 0.44;
          double knightY = screenHeight * 0.83;
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bahay.gif',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                left: knightX,
                top: knightY,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.asset(
                    'assets/images/knights.gif',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                left: knightX + 40,
                top: knightY + 5,
                child: CustomPaint(
                  painter: SpeechBubblePainter(),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: const Text(
                      "Guard",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ),
              ),
              player.render(),
              Positioned(
                top: 20,
                right: 20,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.black54,
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () async {
                    _stopFootstepsImmediate();
                    await _fadeOutBgm();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                ),
              ),
              if (_canTalkToKnight)
                Positioned(
                  bottom: 30,
                  right: 30,
                  child: GestureDetector(
                    onTap: () => _showKnightDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white38, width: 2),
                      ),
                      child: const Text(
                        "Talk",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 20,
                left: 20,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _movePlayer(0, -12, screenWidth, screenHeight),
                          child: const SizedBox(width: 40, height: 40, child: Icon(Icons.arrow_drop_up, size: 32, color: Colors.white)),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _movePlayer(0, 12, screenWidth, screenHeight),
                          child: const SizedBox(width: 40, height: 40, child: Icon(Icons.arrow_drop_down, size: 32, color: Colors.white)),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _movePlayer(-12, 0, screenWidth, screenHeight),
                          child: const SizedBox(width: 40, height: 40, child: Icon(Icons.arrow_left, size: 32, color: Colors.white)),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _movePlayer(12, 0, screenWidth, screenHeight),
                          child: const SizedBox(width: 40, height: 40, child: Icon(Icons.arrow_right, size: 32, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}