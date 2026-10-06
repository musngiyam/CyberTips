import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class IntroStoryScreen extends StatefulWidget {
  final int characterIndex;

  const IntroStoryScreen({super.key, required this.characterIndex});

  @override
  State<IntroStoryScreen> createState() => _IntroStoryScreenState();
}

class _IntroStoryScreenState extends State<IntroStoryScreen> {
  int _dialogueStep = 0;
  late final AudioPlayer _battleAudioPlayer;

  // Expanded dialogue list with multiple slides/steps
  final List<Map<String, String>> _storyDialogue = [
    {
      "speaker": "Narrator",
      "text": "For generations, the valley lived in peace under the shadow of the great mountains, protected by ancient firewalls and digital harmony.",
    },
    {
      "speaker": "Narrator",
      "text": "But peace breeds complacency. In the dark corners of the deep web, a massive coalition has been silently assembling.",
    },
    {
      "speaker": "The Enemy Alliance",
      "text": "Hear us, citizens of the realm! Your walls are fragile, your data is vulnerable, and your era of peace is officially over!",
    },
    {
      "speaker": "The Enemy Alliance",
      "text": "We are the cyber-bandit warlords, the rogue exploit developers, and the architects of malware. We will crash your core servers and claim this city as our own!",
    },
    {
      "speaker": "Narrator",
      "text": "Panic spread through the networks like wildfire. The system administrators retreated, and hope seemed entirely lost...",
    },
    {
      "speaker": "The Heroes",
      "text": "Not on our watch! We didn't spend years training in advanced algorithms and system defense just to back down now.",
    },
    {
      "speaker": "The Heroes",
      "text": "Stand fast, team! Draw your weapons, deploy the defense protocols, and let's push these intruders back to where they came from!",
    },
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

  void _nextDialogue() {
    if (_dialogueStep < _storyDialogue.length - 1) {
      setState(() {
        _dialogueStep++;
      });
    } else {
      _fadeOutAndExit();
    }
  }

  @override
  void dispose() {
    _battleAudioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double baseSize = 140.0;
    final currentDialogue = _storyDialogue[_dialogueStep];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _fadeOutAndExit();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Background image: story.png covering the full screen
            Positioned.fill(
              child: Image.asset(
                'assets/images/story.png',
                fit: BoxFit.cover,
              ),
            ),

            // Dark overlay gradient for readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Left Side: The 3 Heroes standing together
            Positioned(
              left: 50,
              bottom: 120,
              child: Row(
                children: [
                  Opacity(
                    opacity: widget.characterIndex == 0 ? 1.0 : 0.6,
                    child: SizedBox(
                      width: baseSize,
                      height: baseSize,
                      child: Transform.scale(
                        scale: 2.5,
                        child: Image.asset('assets/images/char1.gif', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Opacity(
                    opacity: widget.characterIndex == 1 ? 1.0 : 0.6,
                    child: SizedBox(
                      width: baseSize,
                      height: baseSize,
                      child: Transform.scale(
                        scale: 2.5,
                        child: Image.asset('assets/images/char2.gif', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Opacity(
                    opacity: widget.characterIndex == 2 ? 1.0 : 0.6,
                    child: SizedBox(
                      width: baseSize,
                      height: baseSize,
                      child: Transform.scale(
                        scale: 2.5,
                        child: Image.asset('assets/images/char3.gif', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Right Side: The Enemy Alliance
            Positioned(
              right: 50,
              bottom: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.scale(
                    scaleX: -1.0,
                    scaleY: 1.0,
                    child: Transform.scale(
                      scale: 2.2,
                      child: SizedBox(
                        width: baseSize,
                        height: baseSize,
                        child: Image.asset('assets/images/enemy2.gif', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Transform.translate(
                    offset: const Offset(0, -25),
                    child: Transform.scale(
                      scaleX: -1.0,
                      scaleY: 1.0,
                      child: Transform.scale(
                        scale: 1.2,
                        child: SizedBox(
                          width: baseSize,
                          height: baseSize,
                          child: Image.asset('assets/images/ogre.gif', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Transform.scale(
                    scaleX: -1.0,
                    scaleY: 1.0,
                    child: SizedBox(
                      width: baseSize,
                      height: baseSize,
                      child: Image.asset('assets/images/cult.gif', fit: BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Bottom Dialogue Box & Next Button
            Positioned(
              bottom: 30,
              left: 50,
              right: 50,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E281A).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF8FBC8F), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentDialogue["speaker"]!,
                            style: const TextStyle(
                              color: Color(0xFF81C784),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentDialogue["text"]!,
                            style: const TextStyle(
                              color: Color(0xFFCFD8DC),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF263322),
                          side: const BorderSide(color: Color(0xFF558B2F), width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: _nextDialogue,
                        child: Text(
                          _dialogueStep == _storyDialogue.length - 1
                              ? "Start Battle"
                              : "Next",
                          style: const TextStyle(
                            color: Color(0xFFFFF9C4),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
      ),
    );
  }
}