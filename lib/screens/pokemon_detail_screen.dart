import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pokemon_model.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokemon_type_chip.dart';
import '../widgets/stat_bar.dart';
import '../widgets/pokeball_painter.dart';

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
  late AnimationController _springController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Animation<Offset>? _springAnimation;
  Offset _pokemonOffset = Offset.zero;

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

    _springController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _springController.addListener(() {
      if (mounted && _springAnimation != null) {
        setState(() => _pokemonOffset = _springAnimation!.value);
      }
    });

    _fetchPokemon();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _pokemonOffset = Offset(
        (_pokemonOffset.dx + details.delta.dx).clamp(-110.0, 110.0),
        (_pokemonOffset.dy + details.delta.dy).clamp(-110.0, 110.0),
      );
    });
  }

  void _onPanEnd(DragEndDetails _) {
    _springController.reset();
    _springAnimation = Tween<Offset>(
      begin: _pokemonOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.elasticOut,
    ));
    _springController.forward();
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
    _springController.dispose();
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
          const SpinningPokeball(size: 90),
          const SizedBox(height: 28),
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
    final typeColor = _getTypeColor(pokemon.types.first.name);
    return Stack(
      children: [
        // Pokébola grande en la esquina superior derecha
        Positioned(
          top: -55,
          right: -65,
          child: DecorativePokeball(
            size: 290,
            color: Colors.white,
            opacity: 0.06,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              // Botón atrás + número del Pokémon
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
              // Imagen arrastrable sobre Pokébola decorativa
              SizedBox(
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pokébola centrada detrás del Pokémon
                    DecorativePokeball(
                      size: 230,
                      color: typeColor,
                      opacity: 0.18,
                    ),
                    // Pokémon arrastrable con efecto 3D
                    if (imageUrl != null)
                      GestureDetector(
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..translate(_pokemonOffset.dx, _pokemonOffset.dy)
                            ..rotateY(_pokemonOffset.dx * 0.007)
                            ..rotateX(-_pokemonOffset.dy * 0.007),
                          alignment: FractionalOffset.center,
                          child: Hero(
                            tag: 'pokemon-${pokemon.id}',
                            child: Image.network(
                              imageUrl,
                              height: 220,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.catching_pokemon,
                                size: 120,
                                color: typeColor.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Hint de arrastre
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_with, size: 13, color: Colors.white24),
                  const SizedBox(width: 4),
                  Text(
                    'Arrástralo',
                    style: GoogleFonts.outfit(
                      color: Colors.white24,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
