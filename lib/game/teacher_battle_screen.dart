import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../teacher_quiz_service.dart';
import '../difficulty_settings.dart';
import '../current_user.dart';
import 'battle_attack_effect.dart';

class SpeechBubblePainter extends CustomPainter {
  final bool tailAlignLeft;
  SpeechBubblePainter({this.tailAlignLeft = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF8FBC8F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    const double radius = 12.0;
    const double tailHeight = 10.0;
    const double tailWidth = 14.0;

    final double rectBottom = size.height - tailHeight;

    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, rectBottom - radius);
    path.quadraticBezierTo(size.width, rectBottom, size.width - radius, rectBottom);

    if (tailAlignLeft) {
      path.lineTo(size.width * 0.3 + tailWidth, rectBottom);
      path.lineTo(size.width * 0.3, size.height);
      path.lineTo(size.width * 0.3 - tailWidth / 2, rectBottom);
    } else {
      path.lineTo(size.width * 0.7 + tailWidth / 2, rectBottom);
      path.lineTo(size.width * 0.7, size.height);
      path.lineTo(size.width * 0.7 - tailWidth, rectBottom);
    }

    path.lineTo(radius, rectBottom);
    path.quadraticBezierTo(0, rectBottom, 0, rectBottom - radius);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TeacherBattleScreen extends StatefulWidget {
  final int characterIndex;
  final TeacherQuizModel quiz;

  const TeacherBattleScreen({
    super.key,
    required this.characterIndex,
    required this.quiz,
  });

  @override
  State<TeacherBattleScreen> createState() => _TeacherBattleScreenState();
}

class _TeacherBattleScreenState extends State<TeacherBattleScreen> {
  int _currentSlide = 0;
  bool _isBattling = false;
  bool _battleEnded = false;
  double _heroOpacity = 1.0;
  double _enemyOpacity = 1.0;
  bool _isAttackAnimating = false;
  int _questionsSolved = 0; // Tracks solved questions (0, 1, 2, 3)
  late final AudioPlayer _battleAudioPlayer;

  final GlobalKey<AttackableActorState> _heroActorKey =
      GlobalKey<AttackableActorState>();
  final GlobalKey<AttackableActorState> _ogreActorKey =
      GlobalKey<AttackableActorState>();
  final GlobalKey<BattleEffectsLayerState> _effectsKey =
      GlobalKey<BattleEffectsLayerState>();

  late final AttackStyle _attackStyle;
  late final DifficultySettings _diffSettings;
  late final int _maxPlayerHp;
  static const int _maxOgreHp = 100;
  late int _playerHp;
  int _ogreHp = _maxOgreHp;

  late int _timeLeft;
  Timer? _gameTimer;

  late final List<Map<String, String>> _dialogueSlides;

  @override
  void initState() {
    super.initState();
    _attackStyle = attackStyleForCharacter(widget.characterIndex);
    _diffSettings = _parseDifficulty(widget.quiz.difficulty);
    _maxPlayerHp = _diffSettings.playerHp;
    _playerHp = _maxPlayerHp;
    _timeLeft = _diffSettings.durationSeconds;

    _dialogueSlides = [
      {
        "speaker": "Rival",
        "text":
            "A teacher challenge has been issued! Quiz Code: [${widget.quiz.codeKey}].",
      },
      {
        "speaker": "Rival",
        "text":
            "Trial Mode: ${widget.quiz.gameType == 'missing_letter' ? 'Missing Letter' : 'Caesar Matrix'} (${widget.quiz.difficulty.toUpperCase()}). 1 attempt allowed per account!",
      },
      {
        "speaker": "Hero",
        "text": "I am ready to solve all 3 trial questions and record my score!",
      },
    ];

    _playBattleMusic();
  }

  DifficultySettings _parseDifficulty(String level) {
    switch (level.toLowerCase()) {
      case 'easy':
        return DifficultySettings.easy;
      case 'hard':
        return DifficultySettings.hard;
      case 'medium':
      default:
        return DifficultySettings.medium;
    }
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
      debugPrint("Error playing battle music: $e");
    }
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        if (mounted) {
          setState(() {
            _timeLeft--;
          });
        }
      } else {
        _gameTimer?.cancel();
        if (!_battleEnded) {
          _handleLoseBattle();
        }
      }
    });
  }

  Offset _heroCenter(Size screenSize) =>
      Offset(screenSize.width * 0.05 + 200, screenSize.height * 0.44 + 200);

  Offset _ogreCenter(Size screenSize) =>
      Offset(screenSize.width * 0.52 + 210, screenSize.height * 0.28 + 210);

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
      if (mounted && _playerHp <= 0 && !_battleEnded) {
        _battleEnded = true;
        _gameTimer?.cancel();
        _handleLoseBattle();
      }
    } finally {
      _isAttackAnimating = false;
    }
  }

  void _handleWrongAnswer() {
    unawaited(_playOgreAttack(damage: 20));
    setState(() {
      _timeLeft = max(0, _timeLeft - 5);
    });
    if (_timeLeft == 0 && !_battleEnded) {
      _battleEnded = true;
      _gameTimer?.cancel();
      _handleLoseBattle();
    }
  }

  Future<void> _fadeOutAndExit() async {
    _gameTimer?.cancel();
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

  void _handleWinBattle() async {
    _gameTimer?.cancel();
    _questionsSolved = 3;
    setState(() {
      _enemyOpacity = 0.0;
      _battleEnded = true;
    });

    final int baseScore = 1000;
    final int timeBonus = _timeLeft * 10;
    final int difficultyBonus = widget.quiz.difficulty == 'hard'
        ? 500
        : (widget.quiz.difficulty == 'medium' ? 250 : 100);
    final int totalScore = baseScore + timeBonus + difficultyBonus;

    final String username = CurrentUser.username ?? "Student";
    final int timeTaken = _diffSettings.durationSeconds - _timeLeft;

    await TeacherQuizService().submitScore(
      codeKey: widget.quiz.codeKey,
      username: username,
      score: totalScore,
      timeTakenSeconds: timeTaken,
    );

    _showCustomForestDialog(
      title: "VICTORY!",
      titleColor: const Color(0xFF81C784),
      message:
          "Congratulations $username!\nYou solved all 3/3 questions!\n\nScore: $totalScore pts\nTime Taken: ${timeTaken}s\nRecorded on Teacher Scoreboard.",
      buttonText: "CONTINUE",
      onPressed: _fadeOutAndExit,
    );
  }

  void _handleLoseBattle() async {
    _gameTimer?.cancel();
    setState(() {
      _heroOpacity = 0.0;
      _battleEnded = true;
    });

    final int scorePerQuestion = 300;
    final int totalScore = _questionsSolved * scorePerQuestion;

    final String username = CurrentUser.username ?? "Student";
    final int timeTaken = _diffSettings.durationSeconds - _timeLeft;

    await TeacherQuizService().submitScore(
      codeKey: widget.quiz.codeKey,
      username: username,
      score: totalScore,
      timeTakenSeconds: timeTaken,
    );

    _showCustomForestDialog(
      title: "QUIZ COMPLETED",
      titleColor: const Color(0xFFFF8A80),
      message:
          "Time ran out or health depleted!\n\nQuestions Solved: $_questionsSolved/3\nFinal Score: $totalScore pts\n\nYour score has been recorded on the Teacher Scoreboard.",
      buttonText: "EXIT",
      onPressed: _fadeOutAndExit,
    );
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
                    Navigator.pop(dialogContext);
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
              // Battle Background Image
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

              // Enemy Character (Ogre)
              Positioned(
                left: screenWidth * 0.52,
                top: screenHeight * 0.28,
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
                          'assets/images/enemy1.gif',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Effects Layer
              Positioned.fill(
                child: BattleEffectsLayer(key: _effectsKey),
              ),

              // Top HUD - HP Bars (Positioned matching Quest NPC 4-9)
              if (_isBattling) ...[
                Positioned(
                  top: 15,
                  left: 16,
                  child: HpBar(
                    label: CurrentUser.username ?? "HERO",
                    currentHp: _playerHp,
                    maxHp: _maxPlayerHp,
                    barColor: const Color(0xFF66BB6A),
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
              ],

              // Exit Button
              Positioned(
                top: 15,
                right: 20,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.black54,
                  onPressed: _fadeOutAndExit,
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),

              // Dialogue Speech Bubbles (before battle starts)
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

              // Interactive Puzzle Widget Box
              if (_isBattling && !_battleEnded)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: widget.quiz.gameType == 'missing_letter'
                        ? TeacherMissingLetterWidget(
                            quiz: widget.quiz,
                            timeLeft: _timeLeft,
                            onWinBattle: _handleWinBattle,
                            onLoseBattle: _handleLoseBattle,
                            onWrongAnswer: _handleWrongAnswer,
                            onCorrectQuestionSolved: (solvedCount) {
                              setState(() {
                                _questionsSolved = solvedCount;
                              });
                            },
                            onAttack: () {
                              unawaited(_playHeroAttack(damage: 34));
                            },
                          )
                        : TeacherCaesarWidget(
                            quiz: widget.quiz,
                            timeLeft: _timeLeft,
                            onWinBattle: _handleWinBattle,
                            onLoseBattle: _handleLoseBattle,
                            onWrongAnswer: _handleWrongAnswer,
                            onCorrectQuestionSolved: (solvedCount) {
                              setState(() {
                                _questionsSolved = solvedCount;
                              });
                            },
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

/// Custom Missing Letter Widget using Teacher's 3 Questions
class TeacherMissingLetterWidget extends StatefulWidget {
  final TeacherQuizModel quiz;
  final int timeLeft;
  final VoidCallback onWinBattle;
  final VoidCallback onLoseBattle;
  final VoidCallback onWrongAnswer;
  final ValueChanged<int> onCorrectQuestionSolved;
  final VoidCallback onAttack;

  const TeacherMissingLetterWidget({
    super.key,
    required this.quiz,
    required this.timeLeft,
    required this.onWinBattle,
    required this.onLoseBattle,
    required this.onWrongAnswer,
    required this.onCorrectQuestionSolved,
    required this.onAttack,
  });

  @override
  State<TeacherMissingLetterWidget> createState() =>
      _TeacherMissingLetterWidgetState();
}

class _TeacherMissingLetterWidgetState
    extends State<TeacherMissingLetterWidget> {
  int _currentIndex = 0;
  late TeacherQuestionItem _currentQ;
  late String _targetWord;
  late List<int> _missingIndices;
  late List<String> _userEnteredMissing;
  int _activeMissingSlot = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  void _loadQuestion() {
    if (widget.quiz.questions.isEmpty) return;
    _currentQ = widget.quiz.questions[_currentIndex];
    _targetWord = _currentQ.word.trim().toUpperCase();
    if (_targetWord.isEmpty) _targetWord = "SECURITY";

    int desiredCount = widget.quiz.missingCount;
    int count = min(desiredCount, max(1, _targetWord.length - 1));

    _missingIndices = [];
    if (count == 1) {
      _missingIndices.add(_targetWord.length ~/ 2);
    } else if (count == 2) {
      _missingIndices.add(1);
      _missingIndices.add(_targetWord.length - 2);
    } else {
      _missingIndices.add(0);
      _missingIndices.add(_targetWord.length ~/ 2);
      _missingIndices.add(_targetWord.length - 1);
    }

    _missingIndices.sort();
    _userEnteredMissing = List.filled(_missingIndices.length, "");
    _activeMissingSlot = 0;
  }

  void _onKeyPress(String letter) {
    setState(() {
      if (_activeMissingSlot < _userEnteredMissing.length) {
        _userEnteredMissing[_activeMissingSlot] = letter;
        if (_activeMissingSlot < _userEnteredMissing.length - 1) {
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
    bool correct = true;
    for (int i = 0; i < _missingIndices.length; i++) {
      int charIdx = _missingIndices[i];
      if (_userEnteredMissing[i] != _targetWord[charIdx]) {
        correct = false;
        break;
      }
    }

    if (correct) {
      widget.onAttack();
      widget.onCorrectQuestionSolved(_currentIndex + 1);

      if (_currentIndex < widget.quiz.questions.length - 1) {
        setState(() {
          _currentIndex++;
          _loadQuestion();
        });
      } else {
        widget.onWinBattle();
      }
    } else {
      widget.onWrongAnswer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incorrect! Enemy counterattacked!",
              style: TextStyle(color: Colors.white, decoration: TextDecoration.none)),
          backgroundColor: Color(0xFFD32F2F),
          duration: Duration(milliseconds: 1000),
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          child: SizedBox(
            width: 28,
            height: 28,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF263322),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Color(0xFF558B2F), width: 1),
                ),
              ),
              onPressed: () => _onKeyPress(key),
              child: Text(
                key,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TEACHER TRIAL (${_currentIndex + 1}/${widget.quiz.questions.length})",
                style: const TextStyle(
                  color: Color(0xFF81C784),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
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
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF131A11),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF324C2C), width: 1),
            ),
            child: Text(
              _currentQ.definition,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFCFD8DC),
                fontSize: 10.5,
                height: 1.25,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            "COMPLETE THE HIDDEN SPELLING",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 8.5,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_targetWord.length, (index) {
              int missingSlot = _missingIndices.indexOf(index);
              bool isMissing = missingSlot != -1;

              String displayChar = isMissing
                  ? (_userEnteredMissing[missingSlot].isEmpty
                      ? "_"
                      : _userEnteredMissing[missingSlot])
                  : _targetWord[index];

              return Container(
                width: 32,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  color: isMissing ? const Color(0xFF263322) : const Color(0xFF131A11),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isMissing ? const Color(0xFF81C784) : const Color(0xFF324C2C),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    displayChar,
                    style: TextStyle(
                      color: isMissing ? const Color(0xFF81C784) : Colors.white,
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

          const Text(
            "TYPE MISSING CHARACTERS IN ORDER:",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 7.5,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_missingIndices.length, (slotIndex) {
              bool isActiveSlot = _activeMissingSlot == slotIndex;
              return GestureDetector(
                onTap: () => setState(() => _activeMissingSlot = slotIndex),
                child: Container(
                  width: 30,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
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
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),

          _buildKeyboardRow(["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]),
          const SizedBox(height: 4),
          _buildKeyboardRow(["A", "S", "D", "F", "G", "H", "J", "K", "L"]),
          const SizedBox(height: 4),
          _buildKeyboardRow(["Z", "X", "C", "V", "B", "N", "M"]),

          const SizedBox(height: 8),

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
    );
  }
}

/// Custom Caesar Matrix Widget using Teacher's 3 Questions (Fixed +3 Shift)
class TeacherCaesarWidget extends StatefulWidget {
  final TeacherQuizModel quiz;
  final int timeLeft;
  final VoidCallback onWinBattle;
  final VoidCallback onLoseBattle;
  final VoidCallback onWrongAnswer;
  final ValueChanged<int> onCorrectQuestionSolved;
  final VoidCallback onAttack;

  const TeacherCaesarWidget({
    super.key,
    required this.quiz,
    required this.timeLeft,
    required this.onWinBattle,
    required this.onLoseBattle,
    required this.onWrongAnswer,
    required this.onCorrectQuestionSolved,
    required this.onAttack,
  });

  @override
  State<TeacherCaesarWidget> createState() => _TeacherCaesarWidgetState();
}

class _TeacherCaesarWidgetState extends State<TeacherCaesarWidget> {
  int _currentIndex = 0;
  late TeacherQuestionItem _currentQ;
  late String _targetWord;
  late String _cipherWord;
  late List<String> _userLetters;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  void _loadQuestion() {
    if (widget.quiz.questions.isEmpty) return;
    _currentQ = widget.quiz.questions[_currentIndex];
    _targetWord = _currentQ.word.trim().toUpperCase();
    if (_targetWord.isEmpty) _targetWord = "FIREWALL";

    // Fixed Caesar Shift +3
    _cipherWord = _applyCaesarShift(_targetWord, 3);
    _userLetters = List.filled(_targetWord.length, "");
  }

  String _applyCaesarShift(String input, int shift) {
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      if (code >= 65 && code <= 90) {
        final shifted = ((code - 65 + shift) % 26) + 65;
        buffer.writeCharCode(shifted);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  void _onKeyPress(String letter) {
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
    final String entered = _userLetters.join();
    if (entered == _targetWord) {
      widget.onAttack();
      widget.onCorrectQuestionSolved(_currentIndex + 1);

      if (_currentIndex < widget.quiz.questions.length - 1) {
        setState(() {
          _currentIndex++;
          _loadQuestion();
        });
      } else {
        widget.onWinBattle();
      }
    } else {
      widget.onWrongAnswer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incorrect decrypted text! Enemy counterattacked!",
              style: TextStyle(color: Colors.white, decoration: TextDecoration.none)),
          backgroundColor: Color(0xFFD32F2F),
          duration: Duration(milliseconds: 1000),
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          child: SizedBox(
            width: 28,
            height: 28,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF263322),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Color(0xFF558B2F), width: 1),
                ),
              ),
              onPressed: () => _onKeyPress(key),
              child: Text(
                key,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                children: const [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("PLAIN:  ", style: TextStyle(color: Colors.grey, fontSize: 8, decoration: TextDecoration.none)),
                      Text("A B C D E F G H I J K L M N O P Q R S T U V W X Y Z", style: TextStyle(color: Color(0xFF81C784), fontSize: 7, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("CIPHER: ", style: TextStyle(color: Colors.grey, fontSize: 8, decoration: TextDecoration.none)),
                      Text("D E F G H I J K L M N O P Q R S T U V W X Y Z A B C", style: TextStyle(color: Color(0xFF81C784), fontSize: 7, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    ],
                  ),
                ],
              ),
            ),
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
            child: Text(
              _currentQ.definition,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFCFD8DC),
                fontSize: 10,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 6),

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

          _buildKeyboardRow(["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]),
          const SizedBox(height: 3),
          _buildKeyboardRow(["A", "S", "D", "F", "G", "H", "J", "K", "L"]),
          const SizedBox(height: 3),
          _buildKeyboardRow(["Z", "X", "C", "V", "B", "N", "M"]),

          const SizedBox(height: 8),

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
    );
  }
}
