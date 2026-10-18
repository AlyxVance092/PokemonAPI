import 'package:flutter/material.dart';

/// Widget que muestra un sprite animado de Pokémon con movimiento
class AnimatedPokemonSprite extends StatefulWidget {
  final String? animatedUrl;
  final String? staticUrl;
  final double size;
  final double bobbingOffset;
  final Color? color;

  const AnimatedPokemonSprite({
    super.key,
    this.animatedUrl,
    this.staticUrl,
    this.size = 220,
    this.bobbingOffset = 0,
    this.color,
  });

  @override
  State<AnimatedPokemonSprite> createState() => _AnimatedPokemonSpriteState();
}

class _AnimatedPokemonSpriteState extends State<AnimatedPokemonSprite>
    with SingleTickerProviderStateMixin {
  AnimationController? _bobbingController;
  Animation<double>? _bobbingAnimation;

  @override
  void initState() {
    super.initState();
    _configureBobbing();
  }

  @override
  void didUpdateWidget(covariant AnimatedPokemonSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bobbingOffset != widget.bobbingOffset) {
      _configureBobbing();
    }
  }

  void _configureBobbing() {
    _bobbingController?.dispose();
    _bobbingController = null;
    _bobbingAnimation = null;
    if (widget.bobbingOffset <= 0) return;

    final controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _bobbingController = controller;
    _bobbingAnimation = Tween<double>(
      begin: 0,
      end: widget.bobbingOffset,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bobbingController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.animatedUrl ?? widget.staticUrl;

    if (imageUrl == null) {
      return Icon(
        Icons.catching_pokemon,
        size: widget.size * 0.6,
        color: widget.color?.withOpacity(0.5),
      );
    }

    final fallback = Icon(
      Icons.catching_pokemon,
      size: widget.size * 0.6,
      color: widget.color?.withOpacity(0.5),
    );
    final cacheDimension =
        (widget.size * MediaQuery.devicePixelRatioOf(context)).round();
    final image = Image.network(
      key: ValueKey(imageUrl),
      imageUrl,
      height: widget.size,
      width: widget.size,
      cacheHeight: cacheDimension,
      cacheWidth: cacheDimension,
      fit: BoxFit.contain,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return SizedBox(
          height: widget.size,
          width: widget.size,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.color?.withOpacity(0.65) ?? Colors.white30,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) {
        final fallbackUrl = widget.staticUrl;
        if (fallbackUrl == null || fallbackUrl == imageUrl) return fallback;
        return Image.network(
          fallbackUrl,
          height: widget.size,
          width: widget.size,
          cacheHeight: cacheDimension,
          cacheWidth: cacheDimension,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => fallback,
        );
      },
    );

    final bobbingAnimation = _bobbingAnimation;
    if (bobbingAnimation == null) return image;

    return AnimatedBuilder(
      animation: bobbingAnimation,
      child: image,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -bobbingAnimation.value),
          child: child,
        );
      },
    );
  }
}
