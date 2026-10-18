import 'package:flutter/material.dart';

/// Animación de Pokébola que se abre con efecto dramático
class PokeballOpenAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onComplete;

  const PokeballOpenAnimation({
    super.key,
    required this.child,
    required this.onComplete,
  });

  @override
  State<PokeballOpenAnimation> createState() => _PokeballOpenAnimationState();
}

class _PokeballOpenAnimationState extends State<PokeballOpenAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flashAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _flashAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

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
        return Stack(
          children: [
            // Flash blanco inicial
            Opacity(
              opacity: _flashAnimation.value,
              child: Container(color: Colors.white),
            ),
            // Contenido con animación
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotateAnimation.value * 0.5,
                child: Opacity(
                  opacity: _scaleAnimation.value,
                  child: widget.child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
