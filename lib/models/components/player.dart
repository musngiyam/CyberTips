import 'package:flutter/material.dart';
import 'dart:math';

// --- CUSTOM PAINTERS & WIDGETS FOR FULL-BODY FRONT-FACING HERO ICONS ---

// 1. Full-Body Iron Knight Painter
class IronKnightFullPainter extends CustomPainter {
  final double animationValue;
  IronKnightFullPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double offsetY = sin(animationValue * 2 * pi) * 2.5;

    canvas.save();
    canvas.translate(0, offsetY);

    final paintHelmet = Paint()..color = const Color(0xFF7A8B99);
    final paintHelmetDark = Paint()..color = const Color(0xFF4A5568);
    final paintVisor = Paint()..color = const Color(0xFF2D3748);
    final paintArmor = Paint()..color = const Color(0xFF5A6B7C);
    final paintShield = Paint()..color = const Color(0xFF6B5B95);
    final paintShieldEdge = Paint()..color = const Color(0xFF483D8B);
    final paintSword = Paint()..color = const Color(0xFFD3D3D3);

    final double scale = w / 32.0;

    void drawPixel(
      double x,
      double y,
      double width,
      double height,
      Paint paint,
    ) {
      canvas.drawRect(
        Rect.fromLTWH(x * scale, y * scale, width * scale, height * scale),
        paint,
      );
    }

    // Helmet
    drawPixel(11, 3, 10, 2, paintHelmetDark);
    drawPixel(9, 5, 14, 7, paintHelmet);
    drawPixel(14, 7, 4, 4, paintVisor);
    drawPixel(12, 7, 6, 2, paintVisor);

    // Body / Armor
    drawPixel(10, 12, 12, 8, paintArmor);

    // Shield (Right side)
    drawPixel(21, 11, 7, 10, paintShield);
    drawPixel(20, 12, 1, 8, paintShieldEdge);
    drawPixel(28, 12, 1, 8, paintShieldEdge);

    // Sword/Weapon (Left side)
    drawPixel(5, 15, 4, 2, paintSword);
    drawPixel(3, 14, 2, 4, paintSword);

    // Legs / Boots
    drawPixel(11, 20, 4, 3, paintHelmetDark);
    drawPixel(17, 20, 4, 3, paintHelmetDark);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant IronKnightFullPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class AnimatedIronKnightFullIcon extends StatefulWidget {
  const AnimatedIronKnightFullIcon({super.key});

  @override
  State<AnimatedIronKnightFullIcon> createState() =>
      _AnimatedIronKnightFullIconState();
}

class _AnimatedIronKnightFullIconState extends State<AnimatedIronKnightFullIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(56, 56),
          painter: IronKnightFullPainter(animationValue: _controller.value),
        );
      },
    );
  }
}

// 2. Full-Body Forest Archer Painter
class ForestArcherFullPainter extends CustomPainter {
  final double animationValue;
  ForestArcherFullPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double offsetY = sin(animationValue * 2 * pi) * 2.5;

    canvas.save();
    canvas.translate(0, offsetY);

    final paintHood = Paint()..color = const Color(0xFF3B5323);
    final paintFace = Paint()..color = const Color(0xFFF5D6B0);
    final paintEyes = Paint()..color = const Color(0xFF2D3748);
    final paintTunic = Paint()..color = const Color(0xFF4E7029);
    final paintBow = Paint()..color = const Color(0xFF8B4513);
    final paintQuiver = Paint()..color = const Color(0xFF5C4033);

    final double scale = w / 32.0;

    void drawPixel(
      double x,
      double y,
      double width,
      double height,
      Paint paint,
    ) {
      canvas.drawRect(
        Rect.fromLTWH(x * scale, y * scale, width * scale, height * scale),
        paint,
      );
    }

    // Hood & Face
    drawPixel(10, 3, 12, 3, paintHood);
    drawPixel(8, 6, 16, 4, paintHood);
    drawPixel(10, 8, 12, 5, paintFace);
    drawPixel(12, 9, 2, 2, paintEyes);
    drawPixel(18, 9, 2, 2, paintEyes);

    // Tunic / Body
    drawPixel(10, 13, 12, 7, paintTunic);

    // Quiver on back (Left side)
    drawPixel(7, 12, 3, 8, paintQuiver);

    // Bow (Right side)
    drawPixel(23, 11, 2, 11, paintBow);

    // Boots
    drawPixel(11, 20, 4, 3, paintQuiver);
    drawPixel(17, 20, 4, 3, paintQuiver);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ForestArcherFullPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class AnimatedForestArcherFullIcon extends StatefulWidget {
  const AnimatedForestArcherFullIcon({super.key});

  @override
  State<AnimatedForestArcherFullIcon> createState() =>
      _AnimatedForestArcherFullIconState();
}

class _AnimatedForestArcherFullIconState
    extends State<AnimatedForestArcherFullIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(56, 56),
          painter: ForestArcherFullPainter(animationValue: _controller.value),
        );
      },
    );
  }
}

// 3. Full-Body Cyber Hacker / Mage Painter (Matched to Character 3 Sprite)
class CyberHackerFullPainter extends CustomPainter {
  final double animationValue;
  CyberHackerFullPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double offsetY = sin(animationValue * 2 * pi) * 2.5;

    canvas.save();
    canvas.translate(0, offsetY);

    final paintHair = Paint()..color = const Color(0xFF4A2E2B);
    final paintHeadband = Paint()..color = const Color(0xFFE2E8F0);
    final paintFace = Paint()..color = const Color(0xFFF5D6B0);
    final paintEyes = Paint()..color = const Color(0xFF2D3748);
    final paintOutfit = Paint()
      ..color = const Color(0xFF1B4965); // Blue tunic color
    final paintStaff = Paint()..color = const Color(0xFF6C757D);
    final paintStaffCrystal = Paint()..color = const Color(0xFFFFFFFF);

    final double scale = w / 32.0;

    void drawPixel(
      double x,
      double y,
      double width,
      double height,
      Paint paint,
    ) {
      canvas.drawRect(
        Rect.fromLTWH(x * scale, y * scale, width * scale, height * scale),
        paint,
      );
    }

    // Hair & Headband
    drawPixel(9, 4, 14, 4, paintHair);
    drawPixel(9, 7, 14, 2, paintHeadband);

    // Face & Eyes
    drawPixel(10, 9, 12, 4, paintFace);
    drawPixel(12, 10, 2, 2, paintEyes);
    drawPixel(18, 10, 2, 2, paintEyes);

    // Blue Outfit / Robe Body
    drawPixel(10, 13, 12, 6, paintOutfit);

    // Staff / Wand (Right side, matching character 3 sprite)
    drawPixel(23, 11, 2, 11, paintStaff);
    drawPixel(22, 10, 4, 2, paintStaffCrystal);

    // Boots / Legs
    drawPixel(11, 19, 4, 3, paintHair);
    drawPixel(17, 19, 4, 3, paintHair);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CyberHackerFullPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class AnimatedCyberHackerFullIcon extends StatefulWidget {
  const AnimatedCyberHackerFullIcon({super.key});

  @override
  State<AnimatedCyberHackerFullIcon> createState() =>
      _AnimatedCyberHackerFullIconState();
}

class _AnimatedCyberHackerFullIconState
    extends State<AnimatedCyberHackerFullIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(56, 56),
          painter: CyberHackerFullPainter(animationValue: _controller.value),
        );
      },
    );
  }
}

// --- MAIN PLAYER CLASS ---

class Player {
  double x;
  double y;
  int characterIndex;
  bool isFacingLeft = false;
  double opacity = 1.0;
  double scaleFactor = 1.0;
  Player({required this.x, required this.y, required this.characterIndex});

  void move(double dx, double dy, double screenWidth, double screenHeight) {
    x += dx;
    y += dy;

    if (dx < 0) {
      isFacingLeft = true;
    } else if (dx > 0) {
      isFacingLeft = false;
    }
  }

  // Helper method to return the full-body animated front-facing widget per hero index
  static Widget getHeroHeadIcon(int index) {
    switch (index) {
      case 0:
        return const AnimatedIronKnightFullIcon();
      case 1:
        return const AnimatedForestArcherFullIcon();
      case 2:
      default:
        return const AnimatedCyberHackerFullIcon();
    }
  }

  Widget render() {
    List<String> characterGifs = [
      'assets/images/char1.gif',
      'assets/images/char2.gif',
      'assets/images/char3.gif',
    ];
    String selectedAsset =
        characterGifs[characterIndex.clamp(0, characterGifs.length - 1)];

    Widget characterImage = SizedBox(
      width: 180,
      height: 180,
      child: Image.asset(selectedAsset, fit: BoxFit.contain),
    );

    if (isFacingLeft) {
      characterImage = Transform.scale(
        scaleX: -1.0,
        scaleY: 1.0,
        child: characterImage,
      );
    }

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scaleFactor,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 16,
                left: 78,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.blueAccent,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              characterImage,
            ],
          ),
        ),
      ),
    );
  }
}
