import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';
import '../models/components/player.dart';
import '../models/components/obstacle.dart';
import '../models/components/wizard_npc.dart';
import 'hard1.dart';
import 'hard2.dart';
import 'hard3.dart';
import 'teacher_npc_dialog.dart';
import 'teacher_battle_screen.dart';
import '../teacher_quiz_service.dart';
import 'intro_story_screen.dart';
import '../scoreboard_screen.dart';
import '../current_user.dart';
import '../login_screen.dart';
import '../main.dart';
import '../scoreboard_service.dart';
import '../difficulty_settings.dart';

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

class CyberGame extends StatefulWidget {
  final int characterIndex;
  final DifficultySettings? difficulty;
  const CyberGame({super.key, required this.characterIndex, this.difficulty});

  @override
  State<CyberGame> createState() => _CyberGameState();
}

class _CyberGameState extends State<CyberGame> with TickerProviderStateMixin {
  final FocusNode _gameFocusNode = FocusNode();
  late Player player = Player(
    x: 0,
    y: 0,
    characterIndex: widget.characterIndex,
  );
  final AudioPlayer _footstepPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _isWalkingSoundPlaying = false;
  Timer? _footstepStopTimer;
  DateTime _lastMovementTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _movementInterval = Duration(milliseconds: 140);
  bool _isInitialized = false;
  bool _canTalkToGuard = false;
  bool _canTalkToHelpNpc = false;
  bool _canTalkToWizardNpc = false;
  bool _canTalkToErrandNpc = false;
  bool _isCutscenePlaying = false;
  bool _hasHelpMissionCompleted = false;
  bool _hasHelpBeenTriggered = false;
  bool _hasTriggeredStoryIntro = false;
  bool _hasBookInInventory = false;
  bool _hasWizardWalkedToPlayer = false;
  double _bgmVolume = 1.0;
  double _sfxVolume = 1.0;
  double? _helpNpcX;
  double? _helpNpcY;
  double? _wizardNpcX;
  double? _wizardNpcY;
  double? _errandNpcX;
  double? _errandNpcY;

  late AnimationController _cutsceneController1;
  late AnimationController _cutsceneController2;
  late AnimationController _cutsceneController3;
  late AnimationController _wizardCutsceneController1;
  late AnimationController _wizardCutsceneController2;
  late AnimationController _questEntryController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _gameFocusNode.requestFocus();
    });
    _footstepPlayer.setReleaseMode(ReleaseMode.loop);
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _startBackgroundMusicWithFadeIn();
    _cutsceneController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _cutsceneController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _cutsceneController3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _wizardCutsceneController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _wizardCutsceneController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _questEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  Future<void> _startBackgroundMusicWithFadeIn() async {
    try {
      await _bgmPlayer.setVolume(0.0);
      await _bgmPlayer.play(AssetSource('audio/back.mp3'));
      for (double vol = 0.1; vol <= _bgmVolume; vol += 0.1) {
        if (!mounted) break;
        await _bgmPlayer.setVolume(vol > _bgmVolume ? _bgmVolume : vol);
        await Future.delayed(const Duration(milliseconds: 40));
      }
      await _bgmPlayer.setVolume(_bgmVolume);
    } catch (e) {
      debugPrint("Background music fade-in error: $e");
    }
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

  Future<void> _fadeOutBgm() async {
    try {
      for (double vol = _bgmVolume; vol >= 0.0; vol -= 0.1) {
        await _bgmPlayer.setVolume(vol < 0 ? 0 : vol);
        await Future.delayed(const Duration(milliseconds: 40));
      }
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint("Fade out error: $e");
    }
  }

  @override
  void dispose() {
    _gameFocusNode.dispose();
    _footstepStopTimer?.cancel();
    _footstepPlayer.dispose();
    _bgmPlayer.dispose();
    _cutsceneController1.dispose();
    _cutsceneController2.dispose();
    _cutsceneController3.dispose();
    _wizardCutsceneController1.dispose();
    _wizardCutsceneController2.dispose();
    _questEntryController.dispose();
    super.dispose();
  }

  Future<void> _handleFootstepInput() async {
    if (_sfxVolume <= 0.0) return;
    _footstepStopTimer?.cancel();
    try {
      await _footstepPlayer.setVolume(_sfxVolume);
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

  void _startWizardWalkingCutscene(double screenWidth, double screenHeight) {
    setState(() {
      _isCutscenePlaying = true;
      _hasWizardWalkedToPlayer = true;
    });
    double startWizardX = screenWidth * 0.28;
    double startWizardY = screenHeight * 0.17;
    double cornerWizardX = startWizardX;
    double cornerWizardY = player.y;
    double endWizardX = player.x - 70;
    double endWizardY = player.y;

    Animation<double> wX1 = Tween<double>(
      begin: startWizardX,
      end: cornerWizardX,
    ).animate(_wizardCutsceneController1);
    Animation<double> wY1 = Tween<double>(
      begin: startWizardY,
      end: cornerWizardY,
    ).animate(_wizardCutsceneController1);
    Animation<double> wX2 = Tween<double>(
      begin: cornerWizardX,
      end: endWizardX,
    ).animate(_wizardCutsceneController2);
    Animation<double> wY2 = Tween<double>(
      begin: cornerWizardY,
      end: endWizardY,
    ).animate(_wizardCutsceneController2);

    void wizardListener1() {
      setState(() {
        _wizardNpcX = wX1.value;
        _wizardNpcY = wY1.value;
      });
    }

    void wizardListener2() {
      setState(() {
        _wizardNpcX = wX2.value;
        _wizardNpcY = wY2.value;
      });
    }

    _wizardCutsceneController1.reset();
    _wizardCutsceneController2.reset();
    _wizardCutsceneController1.addListener(wizardListener1);
    _wizardCutsceneController1.forward().then((_) {
      _wizardCutsceneController1.removeListener(wizardListener1);
      _wizardCutsceneController2.addListener(wizardListener2);
      _wizardCutsceneController2.forward().then((_) {
        _wizardCutsceneController2.removeListener(wizardListener2);
        setState(() {
          _isCutscenePlaying = false;
          _hasBookInInventory = true;
        });
        _showWizardAutoDialog(context);
      });
    });
  }

  void _startQuestEntryCutscene(
      int questNumber,
      double screenWidth,
      double screenHeight,
      ) {
    _stopFootstepsImmediate();
    setState(() {
      _isCutscenePlaying = true;
    });
    double guardX = screenWidth * 0.79;
    double guardY = screenHeight * 0.73;
    double targetX = guardX + -10;
    double targetY = guardY + 30;
    double startX = player.x;
    double startY = player.y;
    player.isFacingLeft = targetX < startX;

    Animation<double> walkX = Tween<double>(begin: startX, end: targetX)
        .animate(
      CurvedAnimation(
        parent: _questEntryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    Animation<double> walkY = Tween<double>(begin: startY, end: targetY)
        .animate(
      CurvedAnimation(
        parent: _questEntryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    Animation<double> fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _questEntryController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );
    Animation<double> shrink = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(
        parent: _questEntryController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    void listener() {
      setState(() {
        player.x = walkX.value;
        player.y = walkY.value;
        player.opacity = fade.value;
        player.scaleFactor = shrink.value;
      });
    }

    _questEntryController.reset();
    _questEntryController.addListener(listener);
    _questEntryController.forward().then((_) async {
      _questEntryController.removeListener(listener);
      switch (questNumber) {
        case 1:
          await _navigateToQuest1(context);
          break;
        case 2:
          await _navigateToQuest2(context);
          break;
        case 3:
          await _navigateToQuest3(context);
          break;
        case 4:
          await _navigateToRandomQuest(context);
          break;
      }
      if (mounted) {
        setState(() {
          player.opacity = 1.0;
          player.scaleFactor = 1.0;
          player.x = targetX - 60;
          player.y = targetY;
          _isCutscenePlaying = false;
        });
      }
    });
  }

  void _movePlayer(
      double dx,
      double dy,
      double screenWidth,
      double screenHeight,
      List<Rect> obstacleRects,
      ) async {
    if (_isCutscenePlaying) return;
    final DateTime now = DateTime.now();
    if (now.difference(_lastMovementTime) < _movementInterval) return;
    _lastMovementTime = now;
    if (!_hasTriggeredStoryIntro) {
      _hasTriggeredStoryIntro = true;
      _stopFootstepsImmediate();
      await _fadeOutBgm();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              IntroStoryScreen(characterIndex: widget.characterIndex),
        ),
      );
      if (mounted) {
        _startBackgroundMusicWithFadeIn();
        if (!_hasWizardWalkedToPlayer) {
          _startWizardWalkingCutscene(screenWidth, screenHeight);
        }
      }
      return;
    }
    _handleFootstepInput();
    setState(() {
      double nextX = player.x + dx;
      double nextY = player.y + dy;
      double minX = 10.0;
      double maxX = screenWidth - 140.0;
      double minY = screenHeight * 0.12;
      double maxY = screenHeight - 160.0;
      nextX = nextX.clamp(minX, maxX);
      nextY = nextY.clamp(minY, maxY);
      Rect playerFutureRect = Rect.fromLTWH(nextX + 45, nextY + 110, 90, 50);
      bool hasCollided = false;
      for (var obstacle in obstacleRects) {
        if (obstacle.overlaps(playerFutureRect)) {
          hasCollided = true;
          break;
        }
      }
      if (!hasCollided) {
        player.x = nextX;
        player.y = nextY;
      }
      if (dx < 0) {
        player.isFacingLeft = true;
      } else if (dx > 0) {
        player.isFacingLeft = false;
      }
      double guardX = screenWidth * 0.79;
      double guardY = screenHeight * 0.73;
      double questNpcX = guardX - 150;
      double questNpcY = guardY + 10;
      double dxGuard = player.x - questNpcX;
      double dyGuard = player.y - questNpcY;
      double distGuard = dxGuard * dxGuard + dyGuard * dyGuard;
      _canTalkToGuard = distGuard < 9000.0;

      double helpCurrentX = _helpNpcX ?? (screenWidth * 0.52 - 72);
      double helpCurrentY = _helpNpcY ?? (screenHeight * 0.44);
      _canTalkToHelpNpc =
          ((player.x - helpCurrentX) * (player.x - helpCurrentX) +
              (player.y - helpCurrentY) * (player.y - helpCurrentY)) <
              9000.0;

      double wizardCurrentX = _wizardNpcX ?? (screenWidth * 0.28);
      double wizardCurrentY = _wizardNpcY ?? (screenHeight * 0.17);
      _canTalkToWizardNpc =
          ((player.x - wizardCurrentX) * (player.x - wizardCurrentX) +
              (player.y - wizardCurrentY) * (player.y - wizardCurrentY)) <
              9000.0;

      double errandCurrentX = _errandNpcX ?? (screenWidth * 0.22);
      double errandCurrentY = _errandNpcY ?? (screenHeight * 0.43);
      _canTalkToErrandNpc =
          ((player.x - errandCurrentX) * (player.x - errandCurrentX) +
              (player.y - errandCurrentY) * (player.y - errandCurrentY)) <
              9000.0;
    });
  }

  bool _talkToNearbyNpc() {
    if (_isCutscenePlaying) return false;
    if (_canTalkToGuard) {
      _showNpcDialog(context);
    } else if (_canTalkToHelpNpc) {
      _showHelpNpcDialog(context);
    } else if (_canTalkToWizardNpc) {
      _showWizardNpcDialog(context);
    } else if (_canTalkToErrandNpc) {
      _showErrandNpcDialog(context);
    } else {
      return false;
    }
    return true;
  }

  void _showWizardAutoDialog(BuildContext context) {
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
                  "Mystic Wizard",
                  style: TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                    border: Border.all(
                      color: const Color(0xFF324C2C),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    "Ah, traveler! Take this book of knowledge to aid you on your journey. It has been added to your inventory below.",
                    style: TextStyle(
                      color: Color(0xFFCFD8DC),
                      fontSize: 11,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      "Thank you",
                      style: TextStyle(
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
      ),
    );
  }

  void _showWizardNpcDialog(BuildContext context) {
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
                  "Mystic Wizard",
                  style: TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                    border: Border.all(
                      color: const Color(0xFF324C2C),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    "You already possess the book of knowledge. Use its secrets well!",
                    style: TextStyle(
                      color: Color(0xFFCFD8DC),
                      fontSize: 11,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      "Close",
                      style: TextStyle(
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
      ),
    );
  }

  void _showErrandNpcDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => TeacherNpcDialog(
        characterIndex: widget.characterIndex,
        onStartBattle: (quiz) => _navigateToTeacherQuiz(context, quiz),
      ),
    );
  }

  Future<void> _navigateToTeacherQuiz(
      BuildContext context, TeacherQuizModel quiz) async {
    _stopFootstepsImmediate();
    await _fadeOutBgm();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TeacherBattleScreen(
          characterIndex: widget.characterIndex,
          quiz: quiz,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: Container(color: Colors.black, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
    if (mounted) {
      _startBackgroundMusicWithFadeIn();
    }
  }

  void _showHelpNpcDialog(BuildContext context) {
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
                  "Help Guide",
                  style: TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                    border: Border.all(
                      color: const Color(0xFF324C2C),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _hasHelpBeenTriggered
                        ? "You already know the way to the quest guard!"
                        : "Need assistance? Follow me along the path down to the quest guard!",
                    style: const TextStyle(
                      color: Color(0xFFCFD8DC),
                      fontSize: 11,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      if (!_hasHelpBeenTriggered) {
                        _startHelpWalkingCutscene(
                          MediaQuery.of(context).size.width,
                          MediaQuery.of(context).size.height,
                        );
                      }
                    },
                    child: const Text(
                      "Got it",
                      style: TextStyle(
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
      ),
    );
  }

  void _startHelpWalkingCutscene(double screenWidth, double screenHeight) {
    _stopFootstepsImmediate();
    setState(() {
      _isCutscenePlaying = true;
      _canTalkToHelpNpc = false;
      _hasHelpBeenTriggered = true;
    });
    double startHelpX = _helpNpcX ?? (screenWidth * 0.52 - 72);
    double startHelpY = _helpNpcY ?? (screenHeight * 0.44);
    double startPlayerX = startHelpX;
    double startPlayerY = startHelpY - 50;
    player.x = startPlayerX;
    player.y = startPlayerY;
    double cornerHelpX = startHelpX;
    double cornerHelpY = screenHeight * 0.73;
    double cornerPlayerX = cornerHelpX;
    double cornerPlayerY = cornerHelpY - 50;
    double targetGuardX = screenWidth * 0.79;
    double targetGuardY = screenHeight * 0.73;
    double endHelpX = targetGuardX + 70;
    double endHelpY = targetGuardY;
    double endPlayerX = targetGuardX - 70;
    double endPlayerY = targetGuardY;

    Animation<double> hX1 = Tween<double>(
      begin: startHelpX,
      end: cornerHelpX,
    ).animate(_cutsceneController1);
    Animation<double> hY1 = Tween<double>(
      begin: startHelpY,
      end: cornerHelpY,
    ).animate(_cutsceneController1);
    Animation<double> pX1 = Tween<double>(
      begin: startPlayerX,
      end: cornerPlayerX,
    ).animate(_cutsceneController1);
    Animation<double> pY1 = Tween<double>(
      begin: startPlayerY,
      end: cornerPlayerY,
    ).animate(_cutsceneController1);

    Animation<double> hX2 = Tween<double>(
      begin: cornerHelpX,
      end: endHelpX,
    ).animate(_cutsceneController2);
    Animation<double> hY2 = Tween<double>(
      begin: cornerHelpY,
      end: endHelpY,
    ).animate(_cutsceneController2);
    Animation<double> pX2 = Tween<double>(
      begin: cornerPlayerX,
      end: endPlayerX,
    ).animate(_cutsceneController2);
    Animation<double> pY2 = Tween<double>(
      begin: cornerPlayerY,
      end: endPlayerY,
    ).animate(_cutsceneController2);

    void listener1() {
      setState(() {
        _helpNpcX = hX1.value;
        _helpNpcY = hY1.value;
        player.x = pX1.value;
        player.y = pY1.value;
        player.isFacingLeft = false;
      });
    }

    void listener2() {
      setState(() {
        _helpNpcX = hX2.value;
        _helpNpcY = hY2.value;
        player.x = pX2.value;
        player.y = pY2.value;
        player.isFacingLeft = false;
      });
    }

    _cutsceneController1.reset();
    _cutsceneController2.reset();
    _cutsceneController1.addListener(listener1);
    _cutsceneController1.forward().then((_) {
      _cutsceneController1.removeListener(listener1);
      _cutsceneController2.addListener(listener2);
      _cutsceneController2.forward().then((_) {
        _cutsceneController2.removeListener(listener2);
        setState(() {
          _isCutscenePlaying = false;
          _canTalkToGuard = true;
          _hasHelpMissionCompleted = true;
        });
        _showNpcDialog(context);
      });
    });
  }

  void _showNpcDialog(BuildContext context) {
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
                  "Quest NPC",
                  style: TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                    border: Border.all(
                      color: const Color(0xFF324C2C),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Greetings traveler! Welcome to the church grounds.",
                        style: TextStyle(
                          color: Color(0xFFCFD8DC),
                          fontSize: 11,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _startQuestEntryCutscene(
                            1,
                            MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height,
                          );
                        },
                        child: const Text(
                          "Quests 1-3 (Flip Card)",
                          style: TextStyle(
                            color: Color(0xFF81C784),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _startQuestEntryCutscene(
                            3,
                            MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height,
                          );
                        },
                        child: const Text(
                          "Quests 4-6 (Missing Letter)",
                          style: TextStyle(
                            color: Color(0xFF81C784),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _startQuestEntryCutscene(
                            2,
                            MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height,
                          );
                        },
                        child: const Text(
                          "Quests 7-9 (Cipher Matrix)",
                          style: TextStyle(
                            color: Color(0xFF81C784),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _startQuestEntryCutscene(
                            4,
                            MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height,
                          );
                        },
                        child: const Text(
                          "Quest 10 (Random)",
                          style: TextStyle(
                            color: Color(0xFFFFD54F),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      setState(() {
                        _isCutscenePlaying = false;
                      });
                    },
                    child: const Text(
                      "Close",
                      style: TextStyle(
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
      ),
    );
  }

  Future<void> _navigateToQuest1(BuildContext context) async {
    _stopFootstepsImmediate();
    await _fadeOutBgm();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Hard1Screen(
          characterIndex: widget.characterIndex,
          difficulty: widget.difficulty ?? DifficultySettings.medium,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: Container(color: Colors.black, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
    if (mounted) {
      _startBackgroundMusicWithFadeIn();
    }
  }

  Future<void> _navigateToQuest2(BuildContext context) async {
    _stopFootstepsImmediate();
    await _fadeOutBgm();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Hard2Screen(
          characterIndex: widget.characterIndex,
          difficulty: widget.difficulty ?? DifficultySettings.medium,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: Container(color: Colors.black, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
    if (mounted) {
      _startBackgroundMusicWithFadeIn();
    }
  }

  Future<void> _navigateToQuest3(BuildContext context) async {
    _stopFootstepsImmediate();
    await _fadeOutBgm();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Hard3Screen(
          characterIndex: widget.characterIndex,
          difficulty: widget.difficulty ?? DifficultySettings.medium,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: Container(color: Colors.black, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
    if (mounted) {
      _startBackgroundMusicWithFadeIn();
    }
  }

  Future<void> _navigateToRandomQuest(BuildContext context) async {
    final int pick = Random().nextInt(3);
    switch (pick) {
      case 0:
        await _navigateToQuest1(context);
        break;
      case 1:
        await _navigateToQuest2(context);
        break;
      case 2:
        await _navigateToQuest3(context);
        break;
    }
  }

  void _showOpenBookDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 340,
          height: 420,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/open.png'),
              fit: BoxFit.contain,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 45,
                right: 40,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.brown, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(45, 95, 45, 40),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Center(
                        child: Text(
                          "Cyber Security Guide",
                          style: TextStyle(
                            color: Colors.brown,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "1. Quest 1 (Flip Card): Match pairs of cards quickly by remembering positions.\n\n"
                            "2. Quest 2 (Cipher Matrix): Shift letters backward using Caesar cipher.\n\n"
                            "3. Quest 3 (Missing Letter): Fill in the missing letters correctly.\n\n"
                            "4. Watch timer & make quick moves.",
                        style: TextStyle(
                          color: Colors.brown,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGameMenuDialog(BuildContext context) {
    _stopFootstepsImmediate();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(18),
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
                    "Game Menu",
                    style: TextStyle(
                      color: Color(0xFFE8F5E9),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A11),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF324C2C),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Music Volume",
                          style: TextStyle(
                            color: Color(0xFFCFD8DC),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Slider(
                          value: _bgmVolume,
                          min: 0.0,
                          max: 1.0,
                          activeColor: const Color(0xFF81C784),
                          inactiveColor: Colors.white24,
                          onChanged: (val) {
                            setDialogState(() {
                              _bgmVolume = val;
                            });
                            setState(() {
                              _bgmVolume = val;
                            });
                            _bgmPlayer.setVolume(_bgmVolume);
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Sound Effects Volume",
                          style: TextStyle(
                            color: Color(0xFFCFD8DC),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Slider(
                          value: _sfxVolume,
                          min: 0.0,
                          max: 1.0,
                          activeColor: const Color(0xFF81C784),
                          inactiveColor: Colors.white24,
                          onChanged: (val) {
                            setDialogState(() {
                              _sfxVolume = val;
                            });
                            setState(() {
                              _sfxVolume = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF3B1E1E),
                          side: const BorderSide(
                            color: Color(0xFFE57373),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () async {
                          await _fadeOutBgm();
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const CharacterSelectScreen(),
                            ),
                                (route) => false,
                          );
                        },
                        child: const Text(
                          "Character Select",
                          style: TextStyle(
                            color: Color(0xFFFFCDD2),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF263322),
                          side: const BorderSide(
                            color: Color(0xFF558B2F),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          "Resume",
                          style: TextStyle(
                            color: Color(0xFFFFF9C4),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF2A2A2A),
                        side: const BorderSide(color: Colors.white38, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () async {
                        await _fadeOutBgm();
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        CurrentUser.username = null;
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                              (route) => false,
                        );
                      },
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white70,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;
          if (!_isInitialized) {
            player.x = screenWidth * 0.39;
            player.y = screenHeight * 0.55;
            _isInitialized = true;
          }
          if (_helpNpcX == null || _helpNpcY == null) {
            _helpNpcX = screenWidth * 0.52 - 72;
            _helpNpcY = screenHeight * 0.44;
          }
          if (_wizardNpcX == null || _wizardNpcY == null) {
            _wizardNpcX = screenWidth * 0.28;
            _wizardNpcY = screenHeight * 0.17;
          }
          if (_errandNpcX == null || _errandNpcY == null) {
            // Moved left 5 times (0.27 -> 0.22) and up 3 times (0.55 -> 0.43)
            _errandNpcX = screenWidth * 0.22;
            _errandNpcY = screenHeight * 0.43;
          }

          final obstacleRects = mapObstacles
              .map((o) => o.toRect(screenWidth, screenHeight))
              .toList();
          double guardX = screenWidth * 0.79;
          double guardY = screenHeight * 0.73;

          return Focus(
            focusNode: _gameFocusNode,
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.keyE) {
                return _talkToNearbyNpc()
                    ? KeyEventResult.handled
                    : KeyEventResult.ignored;
              }
              if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                return KeyEventResult.ignored;
              }
              switch (event.logicalKey) {
                case LogicalKeyboardKey.keyW:
                case LogicalKeyboardKey.arrowUp:
                  _movePlayer(0, -12, screenWidth, screenHeight, obstacleRects);
                  return KeyEventResult.handled;
                case LogicalKeyboardKey.keyA:
                case LogicalKeyboardKey.arrowLeft:
                  _movePlayer(-12, 0, screenWidth, screenHeight, obstacleRects);
                  return KeyEventResult.handled;
                case LogicalKeyboardKey.keyS:
                case LogicalKeyboardKey.arrowDown:
                  _movePlayer(0, 12, screenWidth, screenHeight, obstacleRects);
                  return KeyEventResult.handled;
                case LogicalKeyboardKey.keyD:
                case LogicalKeyboardKey.arrowRight:
                  _movePlayer(12, 0, screenWidth, screenHeight, obstacleRects);
                  return KeyEventResult.handled;
                default:
                  return KeyEventResult.ignored;
              }
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/bg1.gif',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white38, width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF81C784),
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.none,
                          child: Center(
                            child: OverflowBox(
                              maxWidth: 130,
                              maxHeight: 130,
                              child: SizedBox(
                                width: 130,
                                height: 130,
                                child: Image.asset(
                                  _getCharacterAsset(),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              CurrentUser.username ?? "Guest",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            FutureBuilder<int>(
                              future: CurrentUser.username != null
                                  ? ScoreboardService().fetchHighestScore(
                                CurrentUser.username!,
                              )
                                  : Future.value(0),
                              builder: (context, snapshot) {
                                final score = snapshot.data ?? 0;
                                return Text(
                                  "Best: $score pts",
                                  style: const TextStyle(
                                    color: Color(0xFFFFD54F),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: guardX,
                  top: guardY,
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: Image.asset(
                      'assets/images/tunnel_entrance.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  left: guardX + -150,
                  top: guardY + 10,
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Image.asset(
                      'assets/images/quest.gif',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  left: guardX + -50,
                  top: guardY + 45,
                  child: CustomPaint(
                    painter: SpeechBubblePainter(),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                      child: const Text(
                        "Quest",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: _helpNpcX!,
                  top: _helpNpcY!,
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Image.asset(
                      'assets/images/quest1.gif',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (!_isCutscenePlaying)
                  Positioned(
                    left: _helpNpcX! + 85,
                    top: _helpNpcY! + 35,
                    child: CustomPaint(
                      painter: SpeechBubblePainter(),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                        child: Text(
                          _hasHelpMissionCompleted ? "Good Luck" : "Help",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: _wizardNpcX!,
                  top: _wizardNpcY!,
                  child: const SizedBox(
                    width: 120,
                    height: 120,
                    child: WizardNPC(),
                  ),
                ),
                if (!_isCutscenePlaying)
                  Positioned(
                    left: _wizardNpcX! + 50,
                    top: _wizardNpcY! + 15,
                    child: CustomPaint(
                      painter: SpeechBubblePainter(),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                        child: Text(
                          _hasWizardWalkedToPlayer ? "Greetings" : "Wizard",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Errand NPC (Teacher) with matched size (120x120)
                Positioned(
                  left: _errandNpcX!,
                  top: _errandNpcY!,
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Image.asset(
                      'assets/images/errand.gif',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (!_isCutscenePlaying)
                  Positioned(
                    left: _errandNpcX! + 45,
                    top: _errandNpcY! + 10,
                    child: CustomPaint(
                      painter: SpeechBubblePainter(),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                        child: const Text(
                          "Teacher",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),

                player.render(),
                Positioned(
                  top: 15,
                  right: 20,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.black54,
                    child: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () => _showGameMenuDialog(context),
                  ),
                ),
                Positioned(
                  top: 15,
                  right: 80,
                  child: FloatingActionButton.small(
                    heroTag: 'overworld_scoreboard_btn',
                    backgroundColor: Colors.black54,
                    child: const Icon(Icons.emoji_events, color: Colors.amber),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const ScoreboardDialog(),
                      );
                    },
                  ),
                ),
                if (_canTalkToGuard)
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: GestureDetector(
                      onTap: () => _showNpcDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white38, width: 2),
                        ),
                        child: const Text(
                          "Talk",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_canTalkToHelpNpc)
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: GestureDetector(
                      onTap: () => _showHelpNpcDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white38, width: 2),
                        ),
                        child: const Text(
                          "Talk",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_canTalkToWizardNpc && !_isCutscenePlaying)
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: GestureDetector(
                      onTap: () => _showWizardNpcDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white38, width: 2),
                        ),
                        child: const Text(
                          "Talk",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_canTalkToErrandNpc && !_isCutscenePlaying)
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: GestureDetector(
                      onTap: () => _showErrandNpcDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white38, width: 2),
                        ),
                        child: const Text(
                          "Talk",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 15,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black87.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white38, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: const Color(0xFF333333),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white54,
                                width: 2,
                              ),
                            ),
                            child: _hasBookInInventory
                                ? GestureDetector(
                              onTap: () => _showOpenBookDialog(context),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Image.asset(
                                  'assets/images/book.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                                : const SizedBox.shrink(),
                          ),
                        ],
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
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _movePlayer(
                                0,
                                -12,
                                screenWidth,
                                screenHeight,
                                obstacleRects,
                              ),
                              child: const SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.arrow_drop_up,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _movePlayer(
                                0,
                                12,
                                screenWidth,
                                screenHeight,
                                obstacleRects,
                              ),
                              child: const SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.arrow_drop_up,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _movePlayer(
                                -12,
                                0,
                                screenWidth,
                                screenHeight,
                                obstacleRects,
                              ),
                              child: const SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.arrow_left,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _movePlayer(
                                12,
                                0,
                                screenWidth,
                                screenHeight,
                                obstacleRects,
                              ),
                              child: const SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.arrow_right,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}