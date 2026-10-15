import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pokemon_model.dart';

/// Widget que muestra la barra de estadística animada de un Pokémon
class StatBar extends StatefulWidget {
  final PokemonStat stat;

  const StatBar({super.key, required this.stat});

  @override
  State<StatBar> createState() => _StatBarState();
}

class _StatBarState extends State<StatBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;

  static const Map<String, String> _statNames = {
    'hp': 'HP',
    'attack': 'Ataque',
    'defense': 'Defensa',
    'special-attack': 'Atq. Esp.',
    'special-defense': 'Def. Esp.',
    'speed': 'Velocidad',
  };

  static const Map<String, Color> _statColors = {
    'hp': Color(0xFFFF6B6B),
    'attack': Color(0xFFFF9F43),
    'defense': Color(0xFF48CAE4),
    'special-attack': Color(0xFFA855F7),
    'special-defense': Color(0xFF22C55E),
    'speed': Color(0xFFFBBF24),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _widthAnimation = Tween<double>(
      begin: 0,
      end: (widget.stat.baseStat / 255).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Pequeño delay para que la animación se vea al hacer scroll
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statName = _statNames[widget.stat.name] ?? widget.stat.name;
    final statColor =
        _statColors[widget.stat.name] ?? const Color(0xFF78909C);
    final percentage = (widget.stat.baseStat / 255 * 100).toInt();

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            statName,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${widget.stat.baseStat}',
            textAlign: TextAlign.right,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Stack(
            children: [
              // Fondo de la barra
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Barra animada
              AnimatedBuilder(
                animation: _widthAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: _widthAnimation.value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statColor.withOpacity(0.7),
                            statColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: statColor.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$percentage%',
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
