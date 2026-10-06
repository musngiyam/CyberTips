import 'dart:math';
import 'package:flutter/material.dart';

/// Which kind of attack animation a character should play, derived from
/// the existing `characterIndex` used across the game.
///
/// 0 = Iron Knight, 1 = Forest Archer -> melee sword attacks.
/// 2 = Cyber Hacker -> ranged magic-bolt attacks.
enum AttackStyle { melee, ranged }

AttackStyle attackStyleForCharacter(int characterIndex) {
  return characterIndex == 2 ? AttackStyle.ranged : AttackStyle.melee;
}

/// -------------------- HP BAR --------------------

/// A small labeled HP bar used for both the player and the Ogre.
/// Animates smoothly whenever [currentHp] changes.
class HpBar extends StatelessWidget {
  final String label;
  final int currentHp;
  final int maxHp;
  final Color barColor;

  const HpBar({
    super.key,
    required this.label,
    required this.currentHp,
    required this.maxHp,
    this.barColor = const Color(0xFF66BB6A),
  });

  @override
  Widget build(BuildContext context) {
    final double fraction = maxHp <= 0
        ? 0.0
        : (currentHp / maxHp).clamp(0.0, 1.0);

    return Container(
      width: 148,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E281A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8FBC8F), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 1,
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
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              Text(
                "$currentHp/$maxHp",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: const Color(0xFF0D1A0B)),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    tween: Tween<double>(begin: 0.0, end: fraction),
                    builder: (context, value, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value.clamp(0.0, 1.0),
                        child: Container(color: barColor),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// -------------------- MELEE / COUNTERATTACK ACTOR --------------------

/// Wraps a character sprite so it can be told to:
///  - move toward its target, "swing", hold at contact, and return
///    ([playMeleeAttack]), used for the warrior/archer hero AND the Ogre.
///  - flash red briefly when it is hit ([playHitFlash]).
///
/// The sprite widget itself is only built once and reused every animation
/// frame (via [AnimatedBuilder]'s `child` parameter), so movement never
/// causes duplicate or re-decoded sprites.
class AttackableActor extends StatefulWidget {
  final Widget child;

  /// +1 for an actor that attacks toward the right, -1 for left.
  final double directionSign;
  final double attackDistance;

  const AttackableActor({
    super.key,
    required this.child,
    required this.directionSign,
    this.attackDistance = 90,
  });

  @override
  State<AttackableActor> createState() => AttackableActorState();
}

class AttackableActorState extends State<AttackableActor>
    with TickerProviderStateMixin {
  late final AnimationController _moveController;
  late final Animation<double> _moveAnimation;
  late final AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _moveAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 38,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 24),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 38,
      ),
    ]).animate(_moveController);

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  /// Moves the actor toward its target and back. [onContact] fires the
  /// moment the swing reaches full extension. Completes once the actor
  /// is fully back at its resting position.
  Future<void> playMeleeAttack({VoidCallback? onContact}) async {
    if (!mounted) return;
    bool fired = false;
    void listener() {
      if (!fired && _moveController.value >= 0.38) {
        fired = true;
        onContact?.call();
      }
    }

    _moveController.addListener(listener);
    await _moveController.forward(from: 0);
    _moveController.removeListener(listener);
  }

  /// A brief red glow to indicate the actor was just hit.
  Future<void> playHitFlash() async {
    if (!mounted) return;
    await _flashController.forward(from: 0);
    if (!mounted) return;
    await _flashController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_moveController, _flashController]),
      builder: (context, child) {
        final double dx =
            widget.directionSign * widget.attackDistance * _moveAnimation.value;
        final double angle =
            widget.directionSign * 0.14 * sin(pi * _moveAnimation.value);

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.rotate(
            angle: angle,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.redAccent.withValues(
                  alpha: 0.55 * _flashController.value,
                ),
                BlendMode.srcATop,
              ),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// -------------------- RANGED / IMPACT EFFECTS LAYER --------------------

class _ActiveBolt {
  final AnimationController controller;
  final Offset from;
  final Offset to;
  final Color color;

  _ActiveBolt({
    required this.controller,
    required this.from,
    required this.to,
    required this.color,
  });
}

class _ActiveSpark {
  final AnimationController controller;
  final Offset at;

  _ActiveSpark({required this.controller, required this.at});
}

/// Transparent overlay that draws transient effects above the characters:
///  - [fireBolt]: a glowing magic projectile for the mage's ranged attack.
///  - [playImpactSpark]: a short flash/slash burst at a contact point,
///    used for melee hits (and the bolt's own impact).
///
/// Meant to be placed as a `Positioned.fill` near the top of a battle
/// screen's Stack, above the hero/Ogre sprites.
class BattleEffectsLayer extends StatefulWidget {
  const BattleEffectsLayer({super.key});

  @override
  State<BattleEffectsLayer> createState() => BattleEffectsLayerState();
}

class BattleEffectsLayerState extends State<BattleEffectsLayer>
    with TickerProviderStateMixin {
  final List<_ActiveBolt> _bolts = [];
  final List<_ActiveSpark> _sparks = [];

  /// Launches a glowing projectile from [from] to [to]. [onContact] fires
  /// on arrival. Completes once the bolt has finished.
  Future<void> fireBolt({
    required Offset from,
    required Offset to,
    Color color = const Color(0xFF80DEEA),
    VoidCallback? onContact,
  }) async {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final bolt = _ActiveBolt(
      controller: controller,
      from: from,
      to: to,
      color: color,
    );

    if (mounted) setState(() => _bolts.add(bolt));

    await controller.forward(from: 0);
    onContact?.call();
    await Future.delayed(const Duration(milliseconds: 60));

    if (mounted) {
      setState(() => _bolts.remove(bolt));
    }
    controller.dispose();
  }

  /// Plays a brief impact spark (expanding ring + slash mark) at [at].
  Future<void> playImpactSpark(Offset at) async {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    final spark = _ActiveSpark(controller: controller, at: at);

    if (mounted) setState(() => _sparks.add(spark));

    await controller.forward(from: 0);

    if (mounted) {
      setState(() => _sparks.remove(spark));
    }
    controller.dispose();
  }

  @override
  void dispose() {
    for (final bolt in _bolts) {
      bolt.controller.dispose();
    }
    for (final spark in _sparks) {
      spark.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Listenable> listenables = [
      ..._bolts.map((b) => b.controller),
      ..._sparks.map((s) => s.controller),
    ];

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge(listenables),
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _EffectsPainter(
              bolts: List.of(_bolts),
              sparks: List.of(_sparks),
            ),
          );
        },
      ),
    );
  }
}

class _EffectsPainter extends CustomPainter {
  final List<_ActiveBolt> bolts;
  final List<_ActiveSpark> sparks;

  _EffectsPainter({required this.bolts, required this.sparks});

  @override
  void paint(Canvas canvas, Size size) {
    for (final bolt in bolts) {
      final double t = bolt.controller.value;

      for (int i = 0; i < 5; i++) {
        final double trailT = (t - i * 0.05).clamp(0.0, 1.0);
        final Offset p = Offset.lerp(bolt.from, bolt.to, trailT)!;
        final double alpha = (1.0 - i * 0.18).clamp(0.0, 1.0);
        final Paint glow = Paint()
          ..color = bolt.color.withValues(alpha: alpha * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(p, 6 - i * 0.7, glow);
      }

      final Offset head = Offset.lerp(bolt.from, bolt.to, t)!;
      final Paint corePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(head, 4, corePaint);
    }

    for (final spark in sparks) {
      final double t = spark.controller.value;
      final double alpha = (1 - t).clamp(0.0, 1.0);
      final double radius = 6 + 22 * t;

      final Paint ring = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(spark.at, radius, ring);

      final double slashLen = 18 + 10 * t;
      final Paint slash = Paint()
        ..color = const Color(0xFFFFF59D).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawLine(
        spark.at.translate(-slashLen, -slashLen * 0.4),
        spark.at.translate(slashLen, slashLen * 0.4),
        slash,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EffectsPainter oldDelegate) => true;
}
