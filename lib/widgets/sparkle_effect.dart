import 'dart:math';

import 'package:flutter/material.dart';

/// Widget que crea partículas brillantes (sparkles) alrededor de un contenido
class SparkleEffect extends StatefulWidget {
  final Widget child;
  final Color color;
  final int particleCount;

  const SparkleEffect({
    super.key,
    required this.child,
    this.color = Colors.amber,
    this.particleCount = 15,
  });

  @override
  State<SparkleEffect> createState() => _SparkleEffectState();
}

class _SparkleEffectState extends State<SparkleEffect>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final List<SparkleParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controllers = [];
    _animations = [];
    _createParticles();
  }

  @override
  void didUpdateWidget(covariant SparkleEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.particleCount != widget.particleCount) {
      for (final controller in _controllers) {
        controller.dispose();
      }
      _controllers.clear();
      _animations.clear();
      _particles.clear();
      _createParticles();
    }
  }

  void _createParticles() {
    for (int i = 0; i < widget.particleCount; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 1500 + _random.nextInt(2000)),
        vsync: this,
      );

      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

      _controllers.add(controller);
      _animations.add(animation);

      _particles.add(
        SparkleParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 2.0 + _random.nextDouble() * 3.0,
        ),
      );

      Future.delayed(Duration(milliseconds: i * 75), () {
        if (mounted && _controllers.contains(controller)) {
          controller.repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 280.0;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 250.0;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            widget.child,
            ...List.generate(widget.particleCount, (index) {
              final particle = _particles[index];
              return Positioned(
                left: particle.x * width,
                top: particle.y * height,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _animations[index],
                    builder: (context, child) {
                      final progress = _animations[index].value;
                      return Opacity(
                        opacity: 0.15 + progress * 0.75,
                        child: Transform.scale(
                          scale: 0.55 + progress * 0.8,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: particle.size,
                      height: particle.size,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class SparkleParticle {
  final double x;
  final double y;
  final double size;

  SparkleParticle({required this.x, required this.y, required this.size});
}
