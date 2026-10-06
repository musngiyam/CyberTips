import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audio_manager.dart'; // Import your audio manager
import 'game/cyber_game.dart';
import 'models/components/player.dart'; // Import player to access custom head icons
import 'login_screen.dart';
import 'scoreboard_screen.dart';
import 'difficulty_select_screen.dart';
import 'current_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape mode for mobile gaming and enable fullscreen
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://qubvqexiuscabkjbxagt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF1YnZxZXhpdXNjYWJramJ4YWd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzMTAzNzksImV4cCI6MjEwNTg4NjM3OX0.CHVrltXru7eYTgL74WPxAn1-27psVy9IxPanvsJoOZU',
  );

  // Start background music immediately when the app launches
  AudioManager().playBackgroundMusic();

  runApp(const CyberApp());
}

class CyberApp extends StatelessWidget {
  const CyberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retro Mobile RPG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
      ),
      // Set the LoginScreen as the root entry point of the app
      home: const LoginScreen(),
    );
  }
}

// ==========================================
// 1. INITIAL LOADING SCREEN (Loads bg.gif, fills screen for 10s)
// ==========================================
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    // 10-second loading duration matching your progress bar requirement
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..forward();

    // Automatically transition to the Character Selection screen after exactly 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const CharacterSelectScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Using BoxFit.fill stretches your background GIF asset to completely cover the screen
          Positioned.fill(
            child: Image.asset('assets/images/bg.gif', fit: BoxFit.fill),
          ),

          // Loading text and progress bar positioned at the bottom
          Positioned(
            bottom: 35,
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 220,
                  height: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressController.value,
                          backgroundColor: Colors.black54,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.greenAccent,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. CHARACTER SELECTION SCREEN (Max-Sized GIFs, Normal Boxes)
// ==========================================
class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen>
    with SingleTickerProviderStateMixin {
  int _selectedCharacter = 0;
  late AnimationController _animController;

  // Uses your char1.gif, char2.gif, and char3.gif files
  final List<Map<String, dynamic>> _characters = [
    {'name': 'Iron Knight', 'image': 'assets/images/char1.gif'},
    {'name': 'Forest Archer', 'image': 'assets/images/char2.gif'},
    {'name': 'Cyber Hacker', 'image': 'assets/images/char3.gif'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.blueGrey],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 20,
              right: 20,
              child: FloatingActionButton.small(
                backgroundColor: Colors.black54,
                heroTag: 'scoreboard_btn',
                child: const Icon(Icons.emoji_events, color: Colors.amber),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ScoreboardDialog(),
                  );
                },
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: FloatingActionButton.small(
                backgroundColor: Colors.black54,
                heroTag: 'logout_btn',
                child: const Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                  CurrentUser.username = null;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'CHOOSE YOUR HERO',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_characters.length, (index) {
                        bool isSelected = _selectedCharacter == index;
                        String imagePath = _characters[index]['image'];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCharacter = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green.shade800
                                  : Colors.grey.shade900,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.greenAccent
                                    : Colors.grey.shade700,
                                width: 4,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                ScaleTransition(
                                  scale: Tween<double>(begin: 0.95, end: 1.05)
                                      .animate(
                                        CurvedAnimation(
                                          parent: _animController,
                                          curve: Curves.easeInOut,
                                        ),
                                      ),
                                  child: Container(
                                    width:
                                        150, // Box container stays clean and compact
                                    height:
                                        150, // Box container stays clean and compact
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.greenAccent
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: Center(
                                      child: OverflowBox(
                                        maxWidth:
                                            260, // Character figure size is blown up massively
                                        maxHeight:
                                            260, // Character figure size is blown up massively
                                        child: SizedBox(
                                          width: 260,
                                          height: 260,
                                          child: Image.asset(
                                            imagePath,
                                            fit: BoxFit.contain,
                                            filterQuality: FilterQuality.none,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Center(
                                                    child:
                                                        Player.getHeroHeadIcon(
                                                          index,
                                                        ),
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _characters[index]['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 45,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        // Smoothly fade out the music before entering the game
                        await AudioManager().fadeOutMusic();

                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DifficultySelectScreen(
                              characterIndex: _selectedCharacter,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'START GAME',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
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
