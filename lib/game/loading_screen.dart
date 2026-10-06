import 'package:flutter/material.dart';
import 'cyber_game.dart'; // Make sure the path matches your project structure

class LoadingScreen extends StatefulWidget {
  final int characterIndex;
  const LoadingScreen({super.key, required this.characterIndex});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for 2 seconds, then replace this screen with CyberGame so it only shows once
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => CyberGame(characterIndex: widget.characterIndex),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // You can replace this with your game logo or custom loading graphics
            const Text(
              "LOADING GAME...",
              style: TextStyle(
                color: Color(0xFF81C784),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81C784)),
            ),
          ],
        ),
      ),
    );
  }
}