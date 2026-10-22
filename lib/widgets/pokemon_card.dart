import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pokemon_model.dart';
import '../widgets/pokemon_type_chip.dart';
import '../widgets/pokeball_painter.dart';
import '../widgets/animated_pokemon_sprite.dart';
import '../widgets/dex_status_badges.dart';

/// Tarjeta de Pokémon en el grid — diseño premium con efecto 3D tilt
class PokemonCard extends StatefulWidget {
  final Pokemon pokemon;
  final VoidCallback onTap;

  const PokemonCard({super.key, required this.pokemon, required this.onTap});

  @override
  State<PokemonCard> createState() => _PokemonCardState();
}

class _PokemonCardState extends State<PokemonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  // Tilt 3D
  double _tiltX = 0;
  double _tiltY = 0;

  static const Map<String, Color> _typeColors = {
    'fire': Color(0xFFFF6B35),
    'water': Color(0xFF4FC3F7),
    'grass': Color(0xFF66BB6A),
    'electric': Color(0xFFFFD54F),
    'psychic': Color(0xFFEC407A),
    'ice': Color(0xFF80DEEA),
    'dragon': Color(0xFF7C4DFF),
    'dark': Color(0xFF5D4037),
    'fairy': Color(0xFFF48FB1),
    'fighting': Color(0xFFFF7043),
    'flying': Color(0xFF90CAF9),
    'poison': Color(0xFFAB47BC),
    'ground': Color(0xFFBCAAA4),
    'rock': Color(0xFF8D6E63),
    'bug': Color(0xFF9CCC65),
    'ghost': Color(0xFF7E57C2),
    'steel': Color(0xFF78909C),
    'normal': Color(0xFFBDBDBD),
  };

  Color get _primaryColor =>
      _typeColors[widget.pokemon.types.first.name] ?? const Color(0xFF78909C);

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.15, end: 0.6).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
    final pos = details.localPosition;
    setState(() {
      _tiltY = ((pos.dx - center.dx) / center.dx) * 8;
      _tiltX = -((pos.dy - center.dy) / center.dy) * 8;
    });
  }

  void _resetTilt() {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) {
            setState(() => _isPressed = true);
            _hoverController.forward();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _hoverController.reverse();
            _resetTilt();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _hoverController.reverse();
            _resetTilt();
          },
          onPanUpdate: (d) => _onPanUpdate(d, constraints),
          onPanEnd: (_) => _resetTilt(),
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(_tiltX * math.pi / 180)
                  ..rotateY(_tiltY * math.pi / 180)
                  ..scale(_scaleAnimation.value),
                child: Hero(
                  tag: 'pokemon-${widget.pokemon.id}',
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _primaryColor.withOpacity(0.40),
                          _primaryColor.withOpacity(0.10),
                          const Color(0xFF0E1120),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _primaryColor.withOpacity(
                          _isPressed ? 0.75 : 0.28,
                        ),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(
                            _glowAnimation.value,
                          ),
                          blurRadius: _isPressed ? 30 : 14,
                          spreadRadius: _isPressed ? 3 : 0,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Fondo degradado radial brillante tipo holograma
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.08,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment(_tiltY / 12, _tiltX / -12),
                                  colors: [Colors.white, Colors.transparent],
                                  radius: 0.85,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Pokébola decorativa de fondo
                        Positioned(
                          right: -28,
                          top: -28,
                          child: DecorativePokeball(
                            size: 145,
                            color: _primaryColor,
                            opacity: 0.18,
                          ),
                        ),
                        // Badges capturado / shiny (tiempo real)
                        DexStatusBadges(
                          pokemonId: widget.pokemon.id,
                          heroTag: 'dex-status-${widget.pokemon.id}',
                        ),
                        // Contenido de la tarjeta
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Número del Pokémon
                              Text(
                                '#${widget.pokemon.id.toString().padLeft(3, '0')}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Nombre
                              Text(
                                widget.pokemon.name,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              // Tipos
                              Wrap(
                                spacing: 4,
                                runSpacing: 3,
                                children: widget.pokemon.types
                                    .map((t) => PokemonTypeChip.small(t.name))
                                    .toList(),
                              ),
                              const Spacer(),
                              Center(child: _buildImage()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildImage() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Incrementado el tamaño base para que se vea más grande en la tarjeta
    final imageSize = screenWidth < 360
        ? 90.0
        : screenWidth < 720
        ? 108.0
        : 140.0;
    final imageUrl =
        widget.pokemon.sprites.homeArtwork ??
        widget.pokemon.sprites.officialArtwork ??
        widget.pokemon.sprites.frontDefault;
    final staticFallback = imageUrl == widget.pokemon.sprites.officialArtwork
        ? widget.pokemon.sprites.frontDefault
        : widget.pokemon.sprites.officialArtwork ??
              widget.pokemon.sprites.frontDefault;
    if (imageUrl == null) {
      return Icon(
        Icons.catching_pokemon,
        size: imageSize * 0.67,
        color: _primaryColor.withOpacity(0.5),
      );
    }

    return SizedBox(
      width: imageSize,
      height: imageSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Imagen principal (más grande)
          AnimatedScale(
            scale: _isPressed ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.5),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ]
                    : [],
              ),
              child: AnimatedPokemonSprite(
                key: ValueKey('card-art-${widget.pokemon.id}'),
                animatedUrl: imageUrl,
                staticUrl: staticFallback,
                size: imageSize,
                color: _primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
