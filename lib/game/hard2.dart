import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'battle_attack_effect.dart';
import '../difficulty_settings.dart';
import '../scoreboard_service.dart';
import '../current_user.dart';
import '../quest_scoring.dart';

class Hard2Screen extends StatefulWidget {
  final int characterIndex;
  final DifficultySettings difficulty;
  final int roundNumber;
  final int bankedScore;

  const Hard2Screen({
    super.key,
    required this.characterIndex,
    this.difficulty = DifficultySettings.medium,
    this.roundNumber = 1,
    this.bankedScore = 0,
  });

  @override
  State<Hard2Screen> createState() => _Hard2ScreenState();
}

class _Hard2ScreenState extends State<Hard2Screen> {
  int _currentSlide = 0;
  bool _isBattling = false;
  double _heroOpacity = 1.0;
  double _enemyOpacity = 1.0;
  late final AudioPlayer _battleAudioPlayer;

  // Cipher Decode Game States & Timer
  bool _isGameOver = false;
  late int _timeLeft;
  Timer? _gameTimer;
  Timer? _tipTimer;
  int _currentTipIndex = 0;

  // Battle HP + attack animation state
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
    "Zero-trust architecture assumes breach and verifies every user request regardless of network location.",
  ];

  // Dialogue slides configuration
  final List<Map<String, String>> _dialogueSlides = [
    {
      "speaker": "Ogre",
      "text": "Think you can crack my coded defenses so easily?",
    },
    {
      "speaker": "Hero",
      "text": "Every cipher has a key. I'll break yours right now!",
    },
    {
      "speaker": "Ogre",
      "text": "Let's see if your mind is as sharp as your blade!",
    },
  ];

  @override
  void initState() {
    super.initState();
    _attackStyle = attackStyleForCharacter(widget.characterIndex);
    _maxPlayerHp = widget.difficulty.playerHp;
    _playerHp = _maxPlayerHp;
    _timeLeft = widget.difficulty.durationSeconds;
    _initializeCipherChallenge();
    _playBattleMusic();
  }

  void _initializeCipherChallenge() {
    _currentChallenge = _challenges[Random().nextInt(_challenges.length)];
    _targetWord = _currentChallenge["plain"]!;
    _cipherWord = _currentChallenge["cipher"]!;
    _userLetters = List.filled(_targetWord.length, "");
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
    setState(() {
      _isGameOver = true;
    });
    // Let the Ogre land one last blow before the defeat sequence plays.
    final Future<void> attackFuture = _playOgreAttack(damage: _playerHp);
    attackFuture.then((_) {
      if (mounted) _handleLoseBattle();
    });
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

  // -------------------- Attack animation helpers --------------------

  Offset _heroCenter(Size screenSize) =>
      Offset(screenSize.width * 0.05 + 200, screenSize.height * 0.44 + 200);

  Offset _ogreCenter(Size screenSize) =>
      Offset(screenSize.width * 0.52 + 210, screenSize.height * 0.16 + 210);

  /// Hero attacks the Ogre: melee swing for Iron Knight/Forest Archer,
  /// a magic bolt for the Cyber Hacker. Reduces Ogre HP on contact.
  Future<void> _playHeroAttack({required int damage}) async {
    if (_isAttackAnimating) return;
    _isAttackAnimating = true;
    final Size screenSize = MediaQuery.of(context).size;

    void applyDamage() {
      if (!mounted) return;
      setState(() {
        _ogreHp = (_ogreHp - damage).clamp(0, _maxOgreHp);
      });
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

  /// The Ogre counterattacks the hero: always moves in, strikes, and
  /// returns. Reduces player HP on contact.
  Future<void> _playOgreAttack({required int damage}) async {
    if (_isAttackAnimating) return;
    _isAttackAnimating = true;
    final Size screenSize = MediaQuery.of(context).size;

    try {
      await _ogreActorKey.currentState?.playMeleeAttack(
        onContact: () {
          if (!mounted) return;
          setState(() {
            _playerHp = (_playerHp - damage).clamp(0, _maxPlayerHp);
          });
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

  int _scaledOgreDamage(int baseDamage) {
    final scaled = (baseDamage * widget.difficulty.enemyDamageMultiplier)
        .round();
    return scaled.clamp(1, 999);
  }

  void _onKeyPress(String letter) {
    if (_isGameOver) return;
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
    if (_isGameOver) return;
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
    if (_isGameOver || _isAttackAnimating) return;
    String currentAttempt = _userLetters.join();
    if (currentAttempt == _targetWord) {
      _gameTimer?.cancel();
      _tipTimer?.cancel();
      setState(() {
        _isGameOver = true;
      });
      // One decisive hit clears the remaining HP; keep the finishing-blow
      // animation visible before the Ogre fades out.
      final Future<void> attackFuture = _playHeroAttack(damage: _ogreHp);
      attackFuture.then((_) {
        if (mounted) _handleWinBattle();
      });
    } else {
      _playOgreAttack(damage: _scaledOgreDamage(5));

      // 5-second penalty deduction on wrong answer submission
      setState(() {
        _timeLeft = (_timeLeft - 5).clamp(0, widget.difficulty.durationSeconds);
      });

      if (_timeLeft == 0) {
        _timerExpired();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Incorrect decryption! -5s penalty. Check shift scheme.",
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

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}";
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
    setState(() {
      _enemyOpacity = 0.0;
    });

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
              ? "You cracked the cipher matrix across all 3 rounds and defeated the Ogre! Total score: $newBanked"
              : "Cipher cracked! Score so far: $newBanked.",
          buttonText: isFinalRound ? "Continue" : "Next Round",
          onPressed: () {
            Navigator.pop(context);
            if (isFinalRound) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Hard2Screen(
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
                builder: (context) => Hard2Screen(
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

              // Projectile / impact-spark overlay, drawn above both characters.
              Positioned.fill(child: BattleEffectsLayer(key: _effectsKey)),

              // HP Bars
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
                  label: "OGRE",
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

              // Cipher Decode Widget integrated seamlessly into the battle layout
              if (_isBattling)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 380,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.85,
                      ),
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E281A).withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF8FBC8F),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3E2723),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFD32F2F),
                                    ),
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
                                border: Border.all(
                                  color: const Color(0xFF324C2C),
                                  width: 1,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          "PLAIN:  ",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 8,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                        Text(
                                          "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z",
                                          style: TextStyle(
                                            color: Color(0xFF81C784),
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          "CIPHER: ",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 8,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                        Text(
                                          "D E F G H I J K L M N O P Q R S T U V W X Y Z A B C",
                                          style: TextStyle(
                                            color: Color(0xFF81C784),
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
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
                                border: Border.all(
                                  color: const Color(0xFF324C2C),
                                  width: 1,
                                ),
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

                            const Text(
                              "DECRYPT THIS CIPHERWORD:",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 8.5,
                                letterSpacing: 0.5,
                                decoration: TextDecoration.none,
                              ),
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

                            // User Input Slots
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_targetWord.length, (
                                index,
                              ) {
                                return Container(
                                  width: 33,
                                  height: 38,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131A11),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF00ACC1),
                                      width: 1.5,
                                    ),
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
                            _buildKeyboardRow([
                              "Q",
                              "W",
                              "E",
                              "R",
                              "T",
                              "Y",
                              "U",
                              "I",
                              "O",
                              "P",
                            ]),
                            const SizedBox(height: 3),
                            _buildKeyboardRow([
                              "A",
                              "S",
                              "D",
                              "F",
                              "G",
                              "H",
                              "J",
                              "K",
                              "L",
                            ]),
                            const SizedBox(height: 3),
                            _buildKeyboardRow([
                              "Z",
                              "X",
                              "C",
                              "V",
                              "B",
                              "N",
                              "M",
                            ]),

                            const SizedBox(height: 8),

                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 30,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Color(0xFFD32F2F),
                                          width: 1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        backgroundColor: const Color(
                                          0xFF261A1A,
                                        ),
                                      ),
                                      onPressed: _onDelete,
                                      child: const Text(
                                        "DELETE",
                                        style: TextStyle(
                                          color: Color(0xFFFF8A80),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.none,
                                        ),
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
                                        backgroundColor: const Color(
                                          0xFF00E676,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      onPressed: _checkAnswer,
                                      child: const Text(
                                        "CHECK ANSWER",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 9,
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
