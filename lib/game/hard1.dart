import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'battle_attack_effect.dart';
import '../difficulty_settings.dart';
import '../scoreboard_service.dart';
import '../current_user.dart';
import '../quest_scoring.dart';

class Hard1Screen extends StatefulWidget {
  final int characterIndex;
  final DifficultySettings difficulty;
  final int roundNumber; // 1, 2, or 3
  final int bankedScore; // points accumulated from prior rounds

  const Hard1Screen({
    super.key,
    required this.characterIndex,
    this.difficulty = DifficultySettings.medium,
    this.roundNumber = 1,
    this.bankedScore = 0,
  });

  @override
  State<Hard1Screen> createState() => _Hard1ScreenState();
}

class _Hard1ScreenState extends State<Hard1Screen> {
  int _currentSlide = 0;
  bool _isBattling = false;
  double _heroOpacity = 1.0;
  double _enemyOpacity = 1.0;
  late final AudioPlayer _battleAudioPlayer;

  // Game States & Timer
  bool _isGameOver = false;
  late int _timeLeft;
  Timer? _gameTimer;
  Timer? _tipTimer;
  int _matchesFound = 0;
  final int _totalPairs = 6; // Updated to 6 pairs like the sample reference

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

  // Pool of 10 cybersecurity card items to randomize from
  final List<Map<String, dynamic>> _masterCardPool = [
    {"name": "AUTH KEY", "icon": Icons.vpn_key, "color": Colors.amber},
    {"name": "MALWARE", "icon": Icons.bug_report, "color": Colors.orangeAccent},
    {
      "name": "SPAM",
      "icon": Icons.mark_email_read,
      "color": Colors.lightGreenAccent,
    },
    {"name": "PHISHING", "icon": Icons.phishing, "color": Colors.cyanAccent},
    {
      "name": "ZERO-TRUST",
      "icon": Icons.admin_panel_settings,
      "color": Colors.amberAccent,
    },
    {
      "name": "BRUTEFORCE",
      "icon": Icons.password,
      "color": Colors.deepOrangeAccent,
    },
    {
      "name": "FIREWALL",
      "icon": Icons.local_fire_department,
      "color": Colors.redAccent,
    },
    {"name": "ENCRYPT", "icon": Icons.lock, "color": Colors.yellowAccent},
    {"name": "VPN TUNNEL", "icon": Icons.security, "color": Colors.greenAccent},
    {
      "name": "MFA CODE",
      "icon": Icons.verified_user,
      "color": Colors.limeAccent,
    },
  ];

  late List<Map<String, dynamic>> _cards;
  int? _firstSelectedCardIndex;
  bool _isCheckingMatch = false;

  // Dialogue slides configuration
  final List<Map<String, String>> _dialogueSlides = [
    {
      "speaker": "Ogre",
      "text": "Well, well, look who finally showed up in the forest.",
    },
    {
      "speaker": "Hero",
      "text": "I've been tracking you for miles. It ends here!",
    },
    {
      "speaker": "Ogre",
      "text": "You think your skills are enough to match mine?",
    },
    {"speaker": "Hero", "text": "Talk all you want. My blade is ready."},
    {"speaker": "Ogre", "text": "Let's start the battle!"},
  ];

  @override
  void initState() {
    super.initState();
    _attackStyle = attackStyleForCharacter(widget.characterIndex);
    _maxPlayerHp = widget.difficulty.playerHp;
    _playerHp = _maxPlayerHp;
    _timeLeft = widget.difficulty.durationSeconds;
    _initializeRandomCards();
    _playBattleMusic();
  }

  void _initializeRandomCards() {
    List<Map<String, dynamic>> shuffledPool = List.from(_masterCardPool)
      ..shuffle();
    List<Map<String, dynamic>> selectedTypes = shuffledPool
        .take(_totalPairs)
        .toList();

    List<Map<String, dynamic>> tempCards = [];
    for (var type in selectedTypes) {
      tempCards.add({...type, "id": type["name"]});
      tempCards.add({...type, "id": type["name"]});
    }
    tempCards.shuffle();

    _cards = tempCards
        .map((card) => {...card, "isFlipped": false, "isMatched": false})
        .toList();
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

  void _onCardTap(int index) {
    if (_isCheckingMatch ||
        _isAttackAnimating ||
        _cards[index]['isFlipped'] ||
        _cards[index]['isMatched'] ||
        _isGameOver) {
      return;
    }

    setState(() {
      _cards[index]['isFlipped'] = true;
    });

    if (_firstSelectedCardIndex == null) {
      _firstSelectedCardIndex = index;
    } else {
      int firstIndex = _firstSelectedCardIndex!;
      _firstSelectedCardIndex = null;

      if (_cards[firstIndex]['id'] == _cards[index]['id']) {
        setState(() {
          _cards[firstIndex]['isMatched'] = true;
          _cards[index]['isMatched'] = true;
          _matchesFound++;
        });

        final int dmg = (_maxOgreHp / _totalPairs).round();
        final bool isFinalMatch = _matchesFound == _totalPairs;
        final Future<void> attackFuture = _playHeroAttack(damage: dmg);

        if (isFinalMatch) {
          _gameTimer?.cancel();
          _tipTimer?.cancel();
          setState(() {
            _isGameOver = true;
          });
          // Keep the finishing-blow animation visible before the Ogre fades out.
          attackFuture.then((_) {
            if (mounted) _handleWinBattle();
          });
        }
      } else {
        _playOgreAttack(damage: _scaledOgreDamage(5));

        setState(() {
          _isCheckingMatch = true;
          _timeLeft = (_timeLeft - 5).clamp(0, 999); // 5s penalty deduction
        });

        Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _cards[firstIndex]['isFlipped'] = false;
              _cards[index]['isFlipped'] = false;
              _isCheckingMatch = false;
            });

            if (_timeLeft <= 0 && !_isGameOver) {
              _timerExpired();
            }
          }
        });
      }
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
              ? "You matched all pairs across all 3 rounds and defeated the Ogre! Total score: $newBanked"
              : "You matched all pairs! Score so far: $newBanked.",
          buttonText: isFinalRound ? "Continue" : "Next Round",
          onPressed: () {
            Navigator.pop(context);
            if (isFinalRound) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Hard1Screen(
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
                builder: (context) => Hard1Screen(
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

              // Memory Match Answering Box integrated with icons and tips matching sample reference layout
              if (_isBattling)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 340,
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
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Difficulty: Hard & Tips Section on top left
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
                                Text(
                                  "DIFFICULTY: ${widget.difficulty.label.toUpperCase()}",
                                  style: const TextStyle(
                                    color: Color(0xFFEF5350),
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
                            behavior: ScrollConfiguration.of(
                              context,
                            ).copyWith(scrollbars: false),
                            child: SizedBox(
                              height: 175,
                              child: GridView.builder(
                                itemCount: _cards.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      crossAxisSpacing: 5,
                                      mainAxisSpacing: 5,
                                      childAspectRatio: 1.25,
                                    ),
                                itemBuilder: (context, index) {
                                  final card = _cards[index];
                                  bool isFlipped =
                                      card['isFlipped'] || card['isMatched'];

                                  return GestureDetector(
                                    onTap: () => _onCardTap(index),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isFlipped
                                            ? const Color(0xFF2E3D2A)
                                            : const Color(0xFF263322),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isFlipped
                                              ? const Color(0xFF81C784)
                                              : const Color(0xFF558B2F),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Center(
                                        child: isFlipped
                                            ? Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    card["icon"],
                                                    color: card["color"],
                                                    size: 16,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    card["name"],
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      color: Color(0xFFFFF9C4),
                                                      fontSize: 4.8,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          Color(0xFF33442C),
                                                          Color(0xFF1B2617),
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ),
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.eco,
                                                    color:
                                                        Colors.green.shade700,
                                                    size: 14,
                                                  ),
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
