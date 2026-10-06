import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'battle_attack_effect.dart';
import '../difficulty_settings.dart';
import '../scoreboard_service.dart';
import '../current_user.dart';
import '../quest_scoring.dart';

class Hard3Screen extends StatefulWidget {
  final int characterIndex;
  final DifficultySettings difficulty;
  final int roundNumber;
  final int bankedScore;

  const Hard3Screen({
    super.key,
    required this.characterIndex,
    this.difficulty = DifficultySettings.medium,
    this.roundNumber = 1,
    this.bankedScore = 0,
  });

  @override
  State<Hard3Screen> createState() => _Hard3ScreenState();
}

class _Hard3ScreenState extends State<Hard3Screen> {
  int _currentSlide = 0;
  bool _isBattling = false;
  double _heroOpacity = 1.0;
  double _enemyOpacity = 1.0;
  bool _isGameOver = false;
  late final AudioPlayer _battleAudioPlayer;

  final GlobalKey<AttackableActorState> _heroActorKey =
      GlobalKey<AttackableActorState>();
  final GlobalKey<AttackableActorState> _ogreActorKey =
      GlobalKey<AttackableActorState>();
  final GlobalKey<BattleEffectsLayerState> _effectsKey =
      GlobalKey<BattleEffectsLayerState>();
  late final AttackStyle _attackStyle;
  late final int _maxPlayerHp;
  static const int _maxOgreHp = 100;
  late int _playerHp;
  int _ogreHp = _maxOgreHp;
  bool _isAttackAnimating = false;

  // Game States & Timer
  late int _timeLeft;
  Timer? _gameTimer;
  Timer? _tipTimer;
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
    "Report suspicious emails or potential security anomalies to your IT security team immediately.",
  ];

  // Dialogue slides configuration
  final List<Map<String, String>> _dialogueSlides = [
    {
      "speaker": "Ogre",
      "text":
          "You dare face me again? This spelling challenge will be your undoing!",
    },
    {
      "speaker": "Hero",
      "text":
          "My mind is sharp and my security knowledge is unmatched. Let's finish this!",
    },
    {
      "speaker": "Ogre",
      "text": "Foolish hero! Fill in the missing letters before time runs out!",
    },
    {"speaker": "Hero", "text": "I'm ready. Prepare to be defeated!"},
  ];

  @override
  void initState() {
    super.initState();
    _attackStyle = attackStyleForCharacter(widget.characterIndex);
    _maxPlayerHp = widget.difficulty.playerHp;
    _playerHp = _maxPlayerHp;
    _timeLeft = widget.difficulty.durationSeconds;
    _playBattleMusic();
  }

  Future<void> _playBattleMusic() async {
    _battleAudioPlayer = AudioPlayer();
    try {
      await _battleAudioPlayer.setVolume(0.0);
      await _battleAudioPlayer.setReleaseMode(ReleaseMode.loop);
      await _battleAudioPlayer.play(AssetSource('audio/battle.mp3'));

      for (double vol = 0.0; vol <= 1.0; vol += 0.1) {
        if (!mounted) break;
        await _battleAudioPlayer.setVolume(vol);
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      debugPrint("Error playing battle audio: $e");
    }
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timerExpired();
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

  void _timerExpired() {
    _gameTimer?.cancel();
    _tipTimer?.cancel();
    _handleLoseBattle();
  }

  void _deductTimeForWrongAnswer() {
    unawaited(_playOgreAttack(damage: 5));
    setState(() {
      _timeLeft = max(0, _timeLeft - 5);
    });
    if (_timeLeft == 0) {
      _timerExpired();
    }
  }

  Offset _heroCenter(Size screenSize) =>
      Offset(screenSize.width * 0.05 + 200, screenSize.height * 0.44 + 200);

  Offset _ogreCenter(Size screenSize) =>
      Offset(screenSize.width * 0.52 + 210, screenSize.height * 0.16 + 210);

  Future<void> _playHeroAttack({required int damage}) async {
    if (_isAttackAnimating) return;
    _isAttackAnimating = true;
    final screenSize = MediaQuery.of(context).size;

    void applyDamage() {
      if (!mounted) return;
      setState(() => _ogreHp = (_ogreHp - damage).clamp(0, _maxOgreHp));
      unawaited(_ogreActorKey.currentState?.playHitFlash());
      unawaited(
        _effectsKey.currentState?.playImpactSpark(_ogreCenter(screenSize)),
      );
    }

    try {
      if (_attackStyle == AttackStyle.ranged) {
        await _effectsKey.currentState?.fireBolt(
          from: _heroCenter(screenSize),
          to: _ogreCenter(screenSize),
          onContact: applyDamage,
        );
      } else {
        await _heroActorKey.currentState?.playMeleeAttack(
          onContact: applyDamage,
        );
      }
    } finally {
      _isAttackAnimating = false;
    }
  }

  Future<void> _playOgreAttack({required int damage}) async {
    if (_isAttackAnimating) return;
    _isAttackAnimating = true;
    final screenSize = MediaQuery.of(context).size;
    try {
      await _ogreActorKey.currentState?.playMeleeAttack(
        onContact: () {
          if (!mounted) return;
          setState(
            () => _playerHp = (_playerHp - damage).clamp(0, _maxPlayerHp),
          );
          unawaited(_heroActorKey.currentState?.playHitFlash());
          unawaited(
            _effectsKey.currentState?.playImpactSpark(_heroCenter(screenSize)),
          );
        },
      );
      if (mounted && _playerHp <= 0 && !_isGameOver) {
        _isGameOver = true;
        _gameTimer?.cancel();
        _tipTimer?.cancel();
        _handleLoseBattle();
      }
    } finally {
      _isAttackAnimating = false;
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
      _startTimer();
      _startTipCycler();
    }
  }

  Future<void> _fadeOutAndExit() async {
    _gameTimer?.cancel();
    _tipTimer?.cancel();
    try {
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
    _gameTimer?.cancel();
    _tipTimer?.cancel();
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

  void _showCustomForestDialog({
    required String title,
    required Color titleColor,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
    String? secondButtonText,
    VoidCallback? onSecondPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E281A).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8FBC8F), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (secondButtonText != null && onSecondPressed != null) ...[
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
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: onSecondPressed,
                      child: Text(
                        secondButtonText,
                        style: const TextStyle(
                          color: Color(0xFFFFCDD2),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
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
                    onPressed: onPressed,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleWinBattle() async {
    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) setState(() => _enemyOpacity = 0.0);
    });
    _gameTimer?.cancel();
    _tipTimer?.cancel();

    final int newBanked =
        widget.bankedScore + QuestScoring.roundBonus(widget.roundNumber);
    final bool isFinalRound = widget.roundNumber >= 3;

    if (isFinalRound) {
      final username = CurrentUser.username;
      if (username != null) {
        final int timeTaken = widget.difficulty.durationSeconds - _timeLeft;
        unawaited(
          ScoreboardService().submitScore(
            username: username,
            difficulty: widget.difficulty.difficultyKey,
            score: newBanked,
            timeTakenSeconds: timeTaken,
          ),
        );
      }
    }

    try {
      for (double vol = 1.0; vol >= 0.0; vol -= 0.2) {
        await _battleAudioPlayer.setVolume(vol);
        await Future.delayed(const Duration(milliseconds: 40));
      }
      await _battleAudioPlayer.stop();
    } catch (_) {}

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _showCustomForestDialog(
          title: isFinalRound
              ? "VICTORY!"
              : "ROUND ${widget.roundNumber} CLEAR!",
          titleColor: const Color(0xFF81C784),
          message: isFinalRound
              ? "You solved all challenges across all 3 rounds and defeated the Ogre! Total score: $newBanked"
              : "Challenge complete! Score so far: $newBanked.",
          buttonText: isFinalRound ? "Continue" : "Next Round",
          onPressed: () {
            Navigator.pop(context);
            if (isFinalRound) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Hard3Screen(
                    characterIndex: widget.characterIndex,
                    difficulty: widget.difficulty,
                    roundNumber: widget.roundNumber + 1,
                    bankedScore: newBanked,
                  ),
                ),
              );
            }
          },
          secondButtonText: isFinalRound ? null : "Stop Here",
          onSecondPressed: isFinalRound
              ? null
              : () async {
                  final username = CurrentUser.username;
                  if (username != null) {
                    final int timeTaken =
                        widget.difficulty.durationSeconds - _timeLeft;
                    unawaited(
                      ScoreboardService().submitScore(
                        username: username,
                        difficulty: widget.difficulty.difficultyKey,
                        score: newBanked,
                        timeTakenSeconds: timeTaken,
                      ),
                    );
                  }
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
        );
      }
    });
  }

  void _handleLoseBattle() async {
    setState(() {
      _heroOpacity = 0.0;
    });
    _gameTimer?.cancel();
    _tipTimer?.cancel();

    final username = CurrentUser.username;
    if (username != null) {
      final int timeTaken = widget.difficulty.durationSeconds - _timeLeft;
      unawaited(
        ScoreboardService().submitScore(
          username: username,
          difficulty: widget.difficulty.difficultyKey,
          score: widget.bankedScore,
          timeTakenSeconds: timeTaken,
        ),
      );
    }

    try {
      for (double vol = 1.0; vol >= 0.0; vol -= 0.2) {
        await _battleAudioPlayer.setVolume(vol);
        await Future.delayed(const Duration(milliseconds: 40));
      }
      await _battleAudioPlayer.stop();
    } catch (_) {}

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _showCustomForestDialog(
          title: "DEFEATED!",
          titleColor: const Color(0xFFFF8A80),
          message:
              "You ran out of time on Round ${widget.roundNumber}. Score banked: ${widget.bankedScore}.",
          buttonText: "Exit",
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          secondButtonText: "Try Again",
          onSecondPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Hard3Screen(
                  characterIndex: widget.characterIndex,
                  difficulty: widget.difficulty,
                  roundNumber: 1,
                  bankedScore: 0,
                ),
              ),
            );
          },
        );
      }
    });
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

              // Hero Character
              Positioned(
                left: screenWidth * 0.05,
                top: screenHeight * 0.44,
                child: AnimatedOpacity(
                  opacity: _heroOpacity,
                  duration: const Duration(milliseconds: 1200),
                  child: AttackableActor(
                    key: _heroActorKey,
                    directionSign: 1.0,
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
              ),

              // Ogre Enemy
              Positioned(
                left: screenWidth * 0.52,
                top: screenHeight * 0.16,
                child: AnimatedOpacity(
                  opacity: _enemyOpacity,
                  duration: const Duration(milliseconds: 1200),
                  child: AttackableActor(
                    key: _ogreActorKey,
                    directionSign: -1.0,
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
                ),
              ),

              Positioned.fill(child: BattleEffectsLayer(key: _effectsKey)),
              Positioned(
                top: 15,
                left: 16,
                child: HpBar(
                  label: "HERO",
                  currentHp: _playerHp,
                  maxHp: _maxPlayerHp,
                  barColor: const Color(0xFF66BB6A),
                ),
              ),
              Positioned(
                top: 115,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFD54F),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "ROUND ${widget.roundNumber}/3 · SCORE: ${widget.bankedScore}",
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 65,
                right: 16,
                child: HpBar(
                  label: 'OGRE',
                  currentHp: _ogreHp,
                  maxHp: _maxOgreHp,
                  barColor: const Color(0xFFEF5350),
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

              // Dialogue Speech Bubbles before battle starts
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

              // Missing Letter Widget Box integrated with difficulty and active tips matching Hard1 & Hard2 style layout
              if (_isBattling)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: MissingLetterWidget(
                      timeLeft: _timeLeft,
                      currentTip: _securityTips[_currentTipIndex],
                      currentTipIndex: _currentTipIndex,
                      difficultyLabel: widget.difficulty.label,
                      onWinBattle: _handleWinBattle,
                      onLoseBattle: _handleLoseBattle,
                      onWrongAnswer: _deductTimeForWrongAnswer,
                      onAttack: () {
                        unawaited(_playHeroAttack(damage: 34));
                      },
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

// ---------------------------------------------------------
// MISSING LETTER WIDGET (Quest 3 Challenge Module)
// ---------------------------------------------------------
class MissingLetterWidget extends StatefulWidget {
  final int timeLeft;
  final String currentTip;
  final int currentTipIndex;
  final String difficultyLabel;
  final VoidCallback onWinBattle;
  final VoidCallback onLoseBattle;
  final VoidCallback onWrongAnswer;
  final VoidCallback onAttack;

  const MissingLetterWidget({
    super.key,
    required this.timeLeft,
    required this.currentTip,
    required this.currentTipIndex,
    required this.difficultyLabel,
    required this.onWinBattle,
    required this.onLoseBattle,
    required this.onWrongAnswer,
    required this.onAttack,
  });

  @override
  State<MissingLetterWidget> createState() => _MissingLetterWidgetState();
}

class _MissingLetterWidgetState extends State<MissingLetterWidget> {
  final List<Map<String, dynamic>> _masterQuestions = [
    {
      "definition":
          "A copy of computer data taken and stored elsewhere so that it may be used to restore the original.",
      "word": "BACKUP",
      "missingIndices": [1, 4],
    },
    {
      "definition":
          "A network security system that monitors and controls incoming and outgoing network traffic.",
      "word": "FIREWALL",
      "missingIndices": [1, 4],
    },
    {
      "definition":
          "The practice of protecting systems, networks, and programs from digital attacks.",
      "word": "SECURITY",
      "missingIndices": [1, 3],
    },
    {
      "definition":
          "A software application used to locate, retrieve and display content on the web.",
      "word": "BROWSER",
      "missingIndices": [2, 5],
    },
    {
      "definition":
          "A device or program that connects computers to communicate over a network.",
      "word": "ROUTER",
      "missingIndices": [1, 3],
    },
    {
      "definition":
          "A private network that connects a group of computers to each other securely.",
      "word": "INTRANET",
      "missingIndices": [2, 5],
    },
    {
      "definition":
          "A program designed to replicate itself and spread from one computer to another.",
      "word": "MALWARE",
      "missingIndices": [1, 4],
    },
    {
      "definition":
          "An independent piece of malicious code that replicates itself to spread to other files.",
      "word": "VIRUS",
      "missingIndices": [1, 3],
    },
    {
      "definition":
          "A type of malware that conceals itself as legitimate software to deceive users.",
      "word": "TROJAN",
      "missingIndices": [2, 4],
    },
    {
      "definition":
          "Software designed to block unauthorized access while permitting outward communication.",
      "word": "DEFENDER",
      "missingIndices": [2, 5],
    },
    {
      "definition":
          "An encoded representation of data used to secure communications against eavesdroppers.",
      "word": "CIPHER",
      "missingIndices": [1, 3],
    },
    {
      "definition":
          "The process of converting plaintext data into unreadable ciphertext.",
      "word": "ENCRYPT",
      "missingIndices": [2, 5],
    },
    {
      "definition":
          "A piece of data sent from a website and stored on your computer by your web browser.",
      "word": "COOKIE",
      "missingIndices": [2, 4],
    },
    {
      "definition":
          "An unsolicited message sent in bulk over the internet, typically to users for advertising.",
      "word": "SPAMMER",
      "missingIndices": [1, 4],
    },
    {
      "definition":
          "A security mechanism for verifying identity before granting system access.",
      "word": "PASSWORD",
      "missingIndices": [2, 5],
    },
    {
      "definition":
          "A physical or virtual point where data enters or leaves a network node.",
      "word": "SOCKET",
      "missingIndices": [1, 4],
    },
    {
      "definition":
          "A small block of data transmitted across a packet-switched network.",
      "word": "PACKET",
      "missingIndices": [2, 4],
    },
    {
      "definition":
          "A unique string of characters used to authenticate a client application or user session.",
      "word": "TOKEN",
      "missingIndices": [1, 4],
    },
    {
      "definition":
          "A fixed-size string generated by a mathematical algorithm to secure data integrity.",
      "word": "HASHED",
      "missingIndices": [1, 3],
    },
    {
      "definition":
          "A dedicated high-performance computer that manages network resources and server requests.",
      "word": "SERVER",
      "missingIndices": [1, 4],
    },
  ];

  late List<Map<String, dynamic>> _gameQuestions;
  int _currentIndex = 0;
  late Map<String, dynamic> _currentQ;
  late String _word;
  late List<int> _missingIndices;

  final List<String> _userEnteredMissing = ["", ""];
  int _activeMissingSlot = 0;

  @override
  void initState() {
    super.initState();
    _masterQuestions.shuffle(Random());
    _gameQuestions = _masterQuestions.take(3).toList();
    _loadQuestion();
  }

  void _loadQuestion() {
    _currentQ = _gameQuestions[_currentIndex];
    _word = _currentQ["word"]!;
    _missingIndices = List<int>.from(_currentQ["missingIndices"]);
    _userEnteredMissing[0] = "";
    _userEnteredMissing[1] = "";
    _activeMissingSlot = 0;
  }

  void _onKeyPress(String letter) {
    setState(() {
      if (_activeMissingSlot < 2) {
        _userEnteredMissing[_activeMissingSlot] = letter;
        if (_activeMissingSlot < 1) {
          _activeMissingSlot++;
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (_activeMissingSlot > 0 &&
          _userEnteredMissing[_activeMissingSlot].isEmpty) {
        _activeMissingSlot--;
        _userEnteredMissing[_activeMissingSlot] = "";
      } else {
        _userEnteredMissing[_activeMissingSlot] = "";
      }
    });
  }

  void _checkAnswer() {
    bool isCorrect = true;
    for (int i = 0; i < 2; i++) {
      int charIndex = _missingIndices[i];
      if (_userEnteredMissing[i] != _word[charIndex]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      _advanceToNextOrWin();
    } else {
      widget.onWrongAnswer(); // Deducts 5 seconds penalty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Incorrect! -5 seconds penalty.",
            style: TextStyle(
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          backgroundColor: Color(0xFFD32F2F),
          duration: Duration(milliseconds: 1000),
        ),
      );
    }
  }

  void _advanceToNextOrWin() {
    widget.onAttack();
    if (_currentIndex < _gameQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _loadQuestion();
      });
    } else {
      widget.onWinBattle();
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
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "QUEST 3: CHALLENGE (${_currentIndex + 1}/3)",
                style: const TextStyle(
                  color: Color(0xFF81C784),
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
                  "Time: ${_formatTime(widget.timeLeft)}",
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
                Text(
                  "DIFFICULTY: ${widget.difficultyLabel.toUpperCase()}",
                  style: const TextStyle(
                    color: Color(0xFFEF5350),
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    letterSpacing: 0.6,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Tip ${widget.currentTipIndex + 1}/10: ${widget.currentTip}",
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF131A11),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF324C2C), width: 1),
            ),
            child: Text(
              _currentQ["definition"],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFCFD8DC),
                fontSize: 10,
                height: 1.25,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "COMPLETE THE HIDDEN SPELLING",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 8,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_word.length, (index) {
              bool isMissing = _missingIndices.contains(index);
              String displayChar = isMissing
                  ? (_missingIndices[0] == index
                        ? (_userEnteredMissing[0].isEmpty
                              ? "_"
                              : _userEnteredMissing[0])
                        : (_userEnteredMissing[1].isEmpty
                              ? "_"
                              : _userEnteredMissing[1]))
                  : _word[index];

              return Container(
                width: 28,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isMissing
                      ? const Color(0xFF263322)
                      : const Color(0xFF131A11),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isMissing
                        ? const Color(0xFF81C784)
                        : const Color(0xFF324C2C),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    displayChar,
                    style: TextStyle(
                      color: isMissing ? const Color(0xFF81C784) : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          const Text(
            "TYPE MISSING CHARACTERS IN ORDER:",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 7,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (slotIndex) {
              bool isActiveSlot = _activeMissingSlot == slotIndex;
              return Container(
                width: 26,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A11),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActiveSlot
                        ? const Color(0xFF00E676)
                        : const Color(0xFF558B2F),
                    width: isActiveSlot ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    _userEnteredMissing[slotIndex],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          _buildKeyboardRow(["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]),
          const SizedBox(height: 3),
          _buildKeyboardRow(["A", "S", "D", "F", "G", "H", "J", "K", "L"]),
          const SizedBox(height: 3),
          _buildKeyboardRow(["Z", "X", "C", "V", "B", "N", "M"]),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFD32F2F),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      backgroundColor: const Color(0xFF261A1A),
                    ),
                    onPressed: _onDelete,
                    child: const Text(
                      "DELETE",
                      style: TextStyle(
                        color: Color(0xFFFF8A80),
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _checkAnswer,
                    child: const Text(
                      "CHECK ANSWER",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> letters) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: letters.map((letter) {
        return Container(
          width: 25,
          height: 27,
          margin: const EdgeInsets.symmetric(horizontal: 1),
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
                    fontSize: 9.5,
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
