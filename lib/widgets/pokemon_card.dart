import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pokemon_model.dart';
import '../widgets/pokemon_type_chip.dart';
import '../widgets/pokeball_painter.dart';

/// Tarjeta de Pokémon en el grid con diseño glassmorphism premium
class PokemonCard extends StatefulWidget {
  final Pokemon pokemon;
  final VoidCallback onTap;

  const PokemonCard({
    super.key,
    required this.pokemon,
    required this.onTap,
  });

  @override
  State<PokemonCard> createState() => _PokemonCardState();
}

class _PokemonCardState extends State<PokemonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

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
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onTapUp: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Hero(
          tag: 'pokemon-${widget.pokemon.id}',
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withOpacity(0.35),
                  _primaryColor.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _primaryColor.withOpacity(_isHovered ? 0.7 : 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(_isHovered ? 0.35 : 0.15),
                  blurRadius: _isHovered ? 20 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Pokébola decorativa de fondo
                Positioned(
                  right: -28,
                  top: -28,
                  child: DecorativePokeball(
                    size: 140,
                    color: _primaryColor,
                    opacity: 0.22,
                  ),
                ),
                // Contenido de la tarjeta
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Número del Pokémon
                      Text(
                        '#${widget.pokemon.id.toString().padLeft(3, '0')}',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Nombre
                      Text(
                        widget.pokemon.name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Tipos
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: widget.pokemon.types
                            .map((t) => PokemonTypeChip.small(t.name))
                            .toList(),
                      ),
                      const Spacer(),
                      // Imagen centrada
                      Center(
                        child: _buildImage(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = widget.pokemon.sprites.officialArtwork ??
        widget.pokemon.sprites.frontDefault;

    if (imageUrl == null) {
      return Icon(
        Icons.catching_pokemon,
        size: 80,
        color: _primaryColor.withOpacity(0.5),
      );
    }

    return Image.network(
      imageUrl,
      height: 100,
      width: 100,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.catching_pokemon,
        size: 80,
        color: _primaryColor.withOpacity(0.5),
      ),
    );
  }
}
