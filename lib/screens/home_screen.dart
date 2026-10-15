import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pokemon_model.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokemon_card.dart';
import 'pokemon_detail_screen.dart';

/// Pantalla principal: explorador de Pokémon con búsqueda
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final PokemonService _service = PokemonService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Pokemon> _pokemonList = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  String? _error;
  int _offset = 0;
  final int _limit = 20;

  late AnimationController _titleController;
  late Animation<double> _titleAnimation;

  @override
  void initState() {
    super.initState();

    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _titleAnimation = CurvedAnimation(
      parent: _titleController,
      curve: Curves.elasticOut,
    );
    _titleController.forward();

    _loadInitialPokemon();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          !_isSearching) {
        _loadMorePokemon();
      }
    });
  }

  Future<void> _loadInitialPokemon() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _service.getPokemonList(limit: _limit, offset: 0);
      final pokemons = await Future.wait(
        list.map((p) => _service.getPokemon(_extractIdFromUrl(p['url']))),
      );
      setState(() {
        _pokemonList = pokemons;
        _offset = _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePokemon() async {
    setState(() => _isLoadingMore = true);
    try {
      final list =
          await _service.getPokemonList(limit: _limit, offset: _offset);
      final pokemons = await Future.wait(
        list.map((p) => _service.getPokemon(_extractIdFromUrl(p['url']))),
      );
      setState(() {
        _pokemonList.addAll(pokemons);
        _offset += _limit;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _searchPokemon(String query) async {
    if (query.isEmpty) {
      setState(() => _isSearching = false);
      _loadInitialPokemon();
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _error = null;
    });

    try {
      final pokemon = await _service.getPokemon(query.toLowerCase().trim());
      setState(() {
        _pokemonList = [pokemon];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _pokemonList = [];
        _isLoading = false;
      });
    }
  }

  String _extractIdFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return segments.last;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1040), Color(0xFF0F0F1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScaleTransition(
            scale: _titleAnimation,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.catching_pokemon,
                    color: Color(0xFFFF6B6B),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PokéDex',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${_pokemonList.length} Pokémon cargados',
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
          onSubmitted: _searchPokemon,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o ID...',
            hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 16),
            prefixIcon: const Icon(Icons.search, color: Colors.white38),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: () {
                      _searchController.clear();
                      _searchPokemon('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cargando Pokémon...',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error != null && _pokemonList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Color(0xFFFF6B6B), size: 64),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadInitialPokemon,
                icon: const Icon(Icons.refresh),
                label: Text('Reintentar',
                    style: GoogleFonts.outfit(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pokemonList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              'No se encontró ningún Pokémon',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _pokemonList.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= _pokemonList.length) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
              ),
            ),
          );
        }

        final pokemon = _pokemonList[index];
        return PokemonCard(
          pokemon: pokemon,
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (ctx, anim, secondAnim) =>
                    PokemonDetailScreen(pokemonId: pokemon.id),
                transitionsBuilder:
                    (ctx, anim, secondAnim, child) {
                  return FadeTransition(opacity: anim, child: child);
                },
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          },
        );
      },
    );
  }
}
