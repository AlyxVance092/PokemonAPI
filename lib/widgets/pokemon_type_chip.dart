import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget de tipo chip con el color correspondiente al tipo de Pokémon
class PokemonTypeChip extends StatelessWidget {
  final String typeName;

  const PokemonTypeChip({super.key, required this.typeName});

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

  static const Map<String, IconData> _typeIcons = {
    'fire': Icons.local_fire_department,
    'water': Icons.water_drop,
    'grass': Icons.grass,
    'electric': Icons.bolt,
    'psychic': Icons.auto_awesome,
    'ice': Icons.ac_unit,
    'dragon': Icons.air,
    'dark': Icons.dark_mode,
    'fairy': Icons.star,
    'fighting': Icons.sports_martial_arts,
    'flying': Icons.flight,
    'poison': Icons.science,
    'ground': Icons.landscape,
    'rock': Icons.diamond,
    'bug': Icons.bug_report,
    'ghost': Icons.visibility_off,
    'steel': Icons.shield,
    'normal': Icons.circle,
  };

  Color get typeColor => _typeColors[typeName] ?? const Color(0xFF78909C);
  IconData get typeIcon => _typeIcons[typeName] ?? Icons.catching_pokemon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: typeColor.withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(typeIcon, color: typeColor, size: 16),
          const SizedBox(width: 6),
          Text(
            '${typeName[0].toUpperCase()}${typeName.substring(1)}',
            style: GoogleFonts.outfit(
              color: typeColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Versión pequeña para usar en tarjetas
  static Widget small(String typeName) {
    final color = _typeColors[typeName] ?? const Color(0xFF78909C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        '${typeName[0].toUpperCase()}${typeName.substring(1)}',
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
