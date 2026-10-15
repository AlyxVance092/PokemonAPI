import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pokemon_model.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokemon_type_chip.dart';
import '../widgets/stat_bar.dart';

/// Pantalla de detalle de un Pokémon individual
class PokemonDetailScreen extends StatefulWidget {
  final int pokemonId;

  const PokemonDetailScreen({super.key, required this.pokemonId});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen>
    with TickerProviderStateMixin {
  final PokemonService _service = PokemonService();
  Pokemon? _pokemon;
  bool _isLoading = true;
  String? _error;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fetchPokemon();
  }

  Future<void> _fetchPokemon() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pokemon = await _service.getPokemon(widget.pokemonId.toString());
      setState(() {
        _pokemon = pokemon;
        _isLoading = false;
      });
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Color _getTypeColor(String type) {
    const typeColors = {
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
    return typeColors[type] ?? const Color(0xFF78909C);
  }

  LinearGradient _getBackgroundGradient() {
    if (_pokemon == null) {
      return const LinearGradient(
        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    final primaryType = _pokemon!.types.first.name;
    final typeColor = _getTypeColor(primaryType);
    return LinearGradient(
      colors: [
        typeColor.withOpacity(0.8),
        const Color(0xFF0F0F1A),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(gradient: _getBackgroundGradient()),
        child: SafeArea(
          child: _isLoading
              ? _buildLoading()
              : _error != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cargando Pokémon...',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 72),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchPokemon,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text('Reintentar', style: GoogleFonts.outfit(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final pokemon = _pokemon!;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header con imagen
            _buildHeader(pokemon),
            // Info cards
            SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Tipos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: pokemon.types
                          .map((t) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: PokemonTypeChip(typeName: t.name),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    // Stats generales
                    _buildInfoRow(pokemon),
                    const SizedBox(height: 24),
                    // Base Stats
                    _buildStatsCard(pokemon),
                    const SizedBox(height: 24),
                    // Habilidades
                    _buildAbilitiesCard(pokemon),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Pokemon pokemon) {
    final imageUrl = pokemon.sprites.officialArtwork ?? pokemon.sprites.frontDefault;
    return Stack(
      children: [
        // Círculo decorativo de fondo
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              // Número y nombre
              Row(
                children: [
                  Text(
                    '#${pokemon.id.toString().padLeft(3, '0')}',
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                pokemon.name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // Imagen oficial del Pokémon
              if (imageUrl != null)
                Hero(
                  tag: 'pokemon-${pokemon.id}',
                  child: Image.network(
                    imageUrl,
                    height: 220,
                    fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(
                        height: 220,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                            color: Colors.white54,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(Pokemon pokemon) {
    return Row(
      children: [
        _buildInfoCard(
          icon: Icons.straighten,
          label: 'Altura',
          value: '${(pokemon.height / 10).toStringAsFixed(1)} m',
        ),
        const SizedBox(width: 12),
        _buildInfoCard(
          icon: Icons.monitor_weight_outlined,
          label: 'Peso',
          value: '${(pokemon.weight / 10).toStringAsFixed(1)} kg',
        ),
        const SizedBox(width: 12),
        _buildInfoCard(
          icon: Icons.star_outline,
          label: 'Exp. Base',
          value: '${pokemon.baseExperience}',
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(Pokemon pokemon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas Base',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...pokemon.stats.map(
            (stat) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StatBar(stat: stat),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilitiesCard(Pokemon pokemon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Habilidades',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: pokemon.abilities.map((ability) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ability.isHidden
                      ? Colors.purple.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: ability.isHidden
                        ? Colors.purple.withOpacity(0.5)
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ability.name
                          .split('-')
                          .map((w) =>
                              '${w[0].toUpperCase()}${w.substring(1)}')
                          .join(' '),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (ability.isHidden) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.visibility_off,
                          size: 14, color: Colors.purple),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          if (pokemon.abilities.any((a) => a.isHidden)) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.visibility_off,
                    size: 12, color: Colors.purple),
                const SizedBox(width: 4),
                Text(
                  'Habilidad oculta',
                  style: GoogleFonts.outfit(
                    color: Colors.purple.shade300,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
