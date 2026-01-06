import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/domino_tile.dart';
import 'domino_tile_painter.dart';

/// Widget qui gère l'animation réaliste de placement d'un domino
/// Inclut: vol, rotation, atterrissage avec rebond, glissement
class AnimatedDominoPlacement extends StatefulWidget {
  final DominoTile tile;
  final Offset startPosition;
  final Offset endPosition;
  final bool isVertical;
  final VoidCallback onComplete;
  final double width;
  final double height;

  const AnimatedDominoPlacement({
    Key? key,
    required this.tile,
    required this.startPosition,
    required this.endPosition,
    required this.onComplete,
    this.isVertical = true,
    this.width = 65,
    this.height = 130,
  }) : super(key: key);

  @override
  State<AnimatedDominoPlacement> createState() => _AnimatedDominoPlacementState();
}

class _AnimatedDominoPlacementState extends State<AnimatedDominoPlacement>
    with TickerProviderStateMixin {
  late AnimationController _flightController;
  late AnimationController _rotationController;
  late AnimationController _landingController;
  late AnimationController _glideController;

  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _glideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimation();
  }

  void _setupAnimations() {
    // 1. Vol (500ms)
    _flightController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _positionAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(
      parent: _flightController,
      curve: Curves.easeInOutCubic,
    ));

    // 2. Rotation pendant le vol (500ms)
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: math.pi * 0.1, // Rotation de ~18°
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    // 3. Atterrissage avec rebond (400ms)
    _landingController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.2,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _landingController,
      curve: Curves.elasticOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _landingController,
      curve: Curves.bounceOut,
    ));

    // 4. Glissement final (300ms)
    _glideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _glideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glideController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _startAnimation() async {
    // Séquence d'animations
    await Future.wait([
      _flightController.forward(),
      _rotationController.forward(),
    ]);

    await _landingController.forward();
    await _glideController.forward();

    widget.onComplete();
  }

  @override
  void dispose() {
    _flightController.dispose();
    _rotationController.dispose();
    _landingController.dispose();
    _glideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _flightController,
        _rotationController,
        _landingController,
        _glideController,
      ]),
      builder: (context, child) {
        return Stack(
          children: [
            // Ombre dynamique qui suit le domino
            Positioned(
              left: _positionAnimation.value.dx,
              top: _positionAnimation.value.dy + _elevationAnimation.value + 5,
              child: Opacity(
                opacity: 0.3 * (1 - _elevationAnimation.value / 20),
                child: Container(
                  width: widget.width * _scaleAnimation.value,
                  height: widget.height * _scaleAnimation.value * 0.3,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Le domino en vol
            Positioned(
              left: _positionAnimation.value.dx,
              top: _positionAnimation.value.dy - _elevationAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * math.sin(_flightController.value * math.pi),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _buildDominoWithGlow(),
                ),
              ),
            ),

            // Particules lors de l'atterrissage
            if (_landingController.value > 0.3 && _landingController.value < 0.7)
              ..._buildImpactParticles(),
          ],
        );
      },
    );
  }

  Widget _buildDominoWithGlow() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(
              alpha: 0.6 * (1 - _landingController.value),
            ),
            blurRadius: 20 + (_elevationAnimation.value * 2),
            spreadRadius: 5,
          ),
        ],
      ),
      child: DominoTileWidget(
        value1: widget.tile.value1,
        value2: widget.tile.value2,
        width: widget.width,
        height: widget.height,
        isVertical: widget.isVertical,
      ),
    );
  }

  List<Widget> _buildImpactParticles() {
    final particles = <Widget>[];
    final particleCount = 8;
    final progress = (_landingController.value - 0.3) / 0.4;

    for (int i = 0; i < particleCount; i++) {
      final angle = (math.pi * 2 * i) / particleCount;
      final distance = 30 * progress;
      final opacity = 1.0 - progress;

      particles.add(
        Positioned(
          left: _positionAnimation.value.dx + widget.width / 2 + math.cos(angle) * distance,
          top: _positionAnimation.value.dy + widget.height / 2 + math.sin(angle) * distance,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return particles;
  }
}

/// Overlay global pour gérer l'animation de placement
class DominoPlacementOverlay {
  static OverlayEntry? _currentOverlay;

  static void showPlacementAnimation({
    required BuildContext context,
    required DominoTile tile,
    required Offset startPosition,
    required Offset endPosition,
    required VoidCallback onComplete,
    bool isVertical = true,
    double width = 65,
    double height = 130,
  }) {
    // Retirer l'overlay précédent s'il existe
    _currentOverlay?.remove();

    final overlay = Overlay.of(context);
    _currentOverlay = OverlayEntry(
      builder: (context) => AnimatedDominoPlacement(
        tile: tile,
        startPosition: startPosition,
        endPosition: endPosition,
        isVertical: isVertical,
        width: width,
        height: height,
        onComplete: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
          onComplete();
        },
      ),
    );

    overlay.insert(_currentOverlay!);
  }
}

/// Animation de vague pour les dominos adjacents
class DominoWaveEffect extends StatefulWidget {
  final Widget child;
  final int index;
  final int totalDominos;
  final bool shouldAnimate;

  const DominoWaveEffect({
    Key? key,
    required this.child,
    required this.index,
    required this.totalDominos,
    this.shouldAnimate = false,
  }) : super(key: key);

  @override
  State<DominoWaveEffect> createState() => _DominoWaveEffectState();
}

class _DominoWaveEffectState extends State<DominoWaveEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _offsetAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.shouldAnimate) {
      _startWave();
    }
  }

  void _startWave() async {
    // Délai basé sur la distance du point d'impact
    await Future.delayed(Duration(milliseconds: widget.index * 50));
    if (mounted) {
      await _controller.forward();
      await _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(DominoWaveEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldAnimate && !oldWidget.shouldAnimate) {
      _startWave();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_offsetAnimation.value),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}
