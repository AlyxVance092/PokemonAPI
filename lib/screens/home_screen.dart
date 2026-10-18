import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pokemon_model.dart';
import '../services/app_language.dart';
import '../services/pokemon_service.dart';
import '../services/audio_service.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/pokeball_painter.dart';
import 'pokemon_detail_screen.dart';

/// Pantalla principal: explorador de Pokémon con búsqueda
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final PokemonService _service = PokemonService();
  final AudioService _audioService = AudioService();
  final Random _random = Random();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LayerLink _searchLayerLink = LayerLink();

  List<Pokemon> _pokemonList = [];
  List<Map<String, dynamic>> _pokemonCatalog = [];
  bool _catalogReady = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMorePokemon = true;
  bool _isSearching = false;
  String? _selectedType;
  String? _error;
  String? _loadMoreError;
  int _offset = 0;
  int _searchRequestId = 0;
  Timer? _searchDebounce;
  // Pages and detail requests stay small so scrolling cannot create a burst
  // of network, JSON parsing, and image work on lower-memory phones.
  static const int _limit = 12;
  static const int _pokemonFetchConcurrency = 4;

  late AnimationController _titleController;
  late Animation<double> _titleAnimation;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _titleAnimation = CurvedAnimation(
      parent: _titleController,
      curve: Curves.elasticOut,
    );
    _titleController.forward();

    _cardControllers = [];
    _cardAnimations = [];

    _loadInitialPokemon();
    _loadPokemonCatalog();

    // Iniciar música de fondo
    _audioService.startBackgroundMusic();

    _scrollController.addListener(() {
      if (_scrollController.hasClients &&
          _hasMorePokemon &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          !_isSearching) {
        _loadMorePokemon();
      }
    });
  }

  Future<void> _loadInitialPokemon() async {
    final requestId = _searchRequestId;
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _hasMorePokemon = true;
      _loadMoreError = null;
      _offset = 0;
      _error = null;
    });
    try {
      final pokemons = await _fetchPokemonPage(0);
      if (!mounted || requestId != _searchRequestId) return;

      // Limpiar animaciones anteriores
      for (var controller in _cardControllers) {
        controller.dispose();
      }
      _cardControllers.clear();
      _cardAnimations.clear();

      // Crear animaciones escalonadas
      for (int i = 0; i < pokemons.length; i++) {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 260),
          vsync: this,
        );
        final animation = CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        );
        _cardControllers.add(controller);
        _cardAnimations.add(animation);

        controller.forward();
      }

      setState(() {
        _pokemonList = pokemons;
        _offset = pokemons.length;
        _hasMorePokemon = pokemons.length == _limit;
        _isLoading = false;
      });
      _loadMoreIfViewportNeedsData();
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPokemonCatalog() async {
    try {
      final catalog = await _service.getPokemonList(limit: 2000);
      if (!mounted) return;
      setState(() {
        _pokemonCatalog = catalog;
        _catalogReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _catalogReady = true);
    }

    final query = _searchController.text.trim();
    if (query.isNotEmpty) _onSearchChanged(query);
  }

  Future<void> _loadMorePokemon() async {
    if (_isLoadingMore || !_hasMorePokemon || _isSearching) return;
    final requestId = _searchRequestId;
    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });
    try {
      final pokemons = await _fetchPokemonPage(_offset);
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _pokemonList.addAll(pokemons);
        _offset += pokemons.length;
        _hasMorePokemon = pokemons.length == _limit;
        _isLoadingMore = false;
      });
      _loadMoreIfViewportNeedsData();
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _isLoadingMore = false;
        _loadMoreError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<List<Pokemon>> _fetchPokemonPage(int offset) async {
    final entries = await _service.getPokemonList(
      limit: _limit,
      offset: offset,
    );
    final pokemons = <Pokemon>[];

    // Keep only a few detail requests and JSON decodes in flight at once.
    for (
      var start = 0;
      start < entries.length;
      start += _pokemonFetchConcurrency
    ) {
      final batch = entries.skip(start).take(_pokemonFetchConcurrency);
      pokemons.addAll(
        await Future.wait(
          batch.map(
            (entry) => _service.getPokemon(_extractIdFromUrl(entry['url'])),
          ),
        ),
      );
    }
    return pokemons;
  }

  void _loadMoreIfViewportNeedsData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_scrollController.hasClients ||
          !_hasMorePokemon ||
          _isLoadingMore ||
          _isSearching) {
        return;
      }
      if (_scrollController.position.extentAfter <= 200) {
        _loadMorePokemon();
      }
    });
  }

  Future<void> _searchPokemon(String query) async {
    final normalizedQuery = _normalizeSearchQuery(query);
    final requestId = ++_searchRequestId;
    if (normalizedQuery.isEmpty) {
      setState(() {
        _isSearching = false;
        _selectedType = null;
        _hasMorePokemon = true;
        _loadMoreError = null;
      });
      _loadInitialPokemon();
      return;
    }

    if (_pokemonCatalog.isNotEmpty && !_isExactCatalogMatch(normalizedQuery)) {
      setState(() {
        _isSearching = true;
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _selectedType = null;
      _isLoading = true;
      _error = null;
    });

    try {
      final pokemon = await _service.getPokemon(normalizedQuery);
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _pokemonList = [pokemon];
        _hasMorePokemon = false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _pokemonList = [];
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    final normalizedQuery = _normalizeSearchQuery(value);
    final hasQuery = normalizedQuery.isNotEmpty;
    final canSearchExact =
        _catalogReady &&
        (_pokemonCatalog.isEmpty || _isExactCatalogMatch(normalizedQuery));

    // Invalidate older requests immediately. Partial matches are resolved
    // locally from the catalog; the network is only needed for an exact hit.
    _searchRequestId++;
    _searchDebounce?.cancel();
    setState(() {
      if (!hasQuery) _pokemonList = [];
      _isLoading = hasQuery && canSearchExact;
      _isSearching = hasQuery;
      _isLoadingMore = false;
      _hasMorePokemon = !hasQuery;
      _loadMoreError = null;
      _selectedType = null;
      _error = null;
    });

    if (!hasQuery) {
      _searchPokemon('');
      return;
    }

    if (!_catalogReady ||
        (_pokemonCatalog.isNotEmpty &&
            !_isExactCatalogMatch(normalizedQuery))) {
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 140), () {
      if (mounted) _searchPokemon(normalizedQuery);
    });
  }

  void _submitSearch(String value) {
    _searchDebounce?.cancel();
    final query = _normalizeSearchQuery(value);
    if (!_isExactCatalogMatch(query) && _searchSuggestions.isNotEmpty) {
      _selectSearchSuggestion(_searchSuggestions.first);
      return;
    }
    _onSearchChanged(value);
  }

  void _selectSearchSuggestion(Map<String, dynamic> entry) {
    final name = entry['name'] as String;
    _searchController.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    _onSearchChanged(name);
  }

  String _normalizeSearchQuery(String query) =>
      query.trim().toLowerCase().replaceAll(' ', '-');

  bool _isExactCatalogMatch(String query) {
    if (query.isEmpty) return false;
    if (!_catalogReady && _pokemonCatalog.isEmpty) return false;
    final catalog = _pokemonCatalog.isNotEmpty
        ? _pokemonCatalog
        : _pokemonList
              .map(
                (pokemon) => <String, dynamic>{
                  'name': pokemon.name.toLowerCase(),
                  'url': 'https://pokeapi.co/api/v2/pokemon/${pokemon.id}/',
                },
              )
              .toList();
    return catalog.any((entry) {
      final name = entry['name'] as String? ?? '';
      final id = _extractIdFromUrl(entry['url'] as String);
      return name == query || id == query;
    });
  }

  List<Map<String, dynamic>> get _searchSuggestions {
    final query = _normalizeSearchQuery(_searchController.text);
    if (query.isEmpty) return [];
    final numericQuery = RegExp(r'^\d+$').hasMatch(query);
    final catalog = _pokemonCatalog.isNotEmpty
        ? _pokemonCatalog
        : _pokemonList
              .map(
                (pokemon) => <String, dynamic>{
                  'name': pokemon.name.toLowerCase(),
                  'url': 'https://pokeapi.co/api/v2/pokemon/${pokemon.id}/',
                },
              )
              .toList();
    final matches = catalog.where((entry) {
      final name = entry['name'] as String? ?? '';
      final id = _extractIdFromUrl(entry['url'] as String);
      return numericQuery ? id.startsWith(query) : name.contains(query);
    }).toList();

    int rank(Map<String, dynamic> entry) {
      final name = entry['name'] as String? ?? '';
      final id = _extractIdFromUrl(entry['url'] as String);
      if (name == query || id == query) return 0;
      if (numericQuery ? id.startsWith(query) : name.startsWith(query)) {
        return 1;
      }
      return 2;
    }

    matches.sort((a, b) {
      final rankCompare = rank(a).compareTo(rank(b));
      if (rankCompare != 0) return rankCompare;
      return int.parse(_extractIdFromUrl(a['url'] as String))
          .compareTo(int.parse(_extractIdFromUrl(b['url'] as String)));
    });
    return matches.take(4).toList();
  }

  bool get _showSearchSuggestions {
    final query = _normalizeSearchQuery(_searchController.text);
    return query.isNotEmpty &&
        !_isExactCatalogMatch(query) &&
        _searchSuggestions.isNotEmpty;
  }

  String _extractIdFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return segments.last;
  }

  List<Pokemon> get _visiblePokemon {
    var visible = _pokemonList;
    final query = _normalizeSearchQuery(_searchController.text);
    if (query.isNotEmpty && !_isExactCatalogMatch(query)) {
      final numericQuery = RegExp(r'^\d+$').hasMatch(query);
      visible = visible.where((pokemon) {
        return numericQuery
            ? pokemon.id.toString().startsWith(query)
            : pokemon.name.toLowerCase().contains(query);
      }).toList();
    }
    if (_selectedType == null) return visible;
    return visible
        .where(
          (pokemon) => pokemon.types.any((type) => type.name == _selectedType),
        )
        .toList();
  }

  void _openPokemon(Pokemon pokemon) {
    HapticFeedback.lightImpact();
    _audioService.playPokeballOpen();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, anim, secondAnim) =>
            PokemonDetailScreen(pokemonId: pokemon.id),
        transitionsBuilder: (ctx, anim, secondAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _surpriseMe() {
    final candidates = _visiblePokemon;
    if (candidates.isEmpty) return;
    final pokemon = candidates[_random.nextInt(candidates.length)];
    _openPokemon(pokemon);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _audioService.resumeBackgroundMusic();
    } else if (state == AppLifecycleState.paused) {
      _audioService.pauseBackgroundMusic();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B1738), Color(0xFF111426), Color(0xFF090B14)],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildSpotlight(),
                  _buildSearchBar(),
                  _buildTypeFilters(),
                  Expanded(child: _buildBody()),
                ],
              ),
              if (_showSearchSuggestions)
                CompositedTransformFollower(
                  link: _searchLayerLink,
                  showWhenUnlinked: false,
                  targetAnchor: Alignment.bottomLeft,
                  followerAnchor: Alignment.topLeft,
                  offset: Offset.zero,
                  child: _buildSearchSuggestions(),
                ),
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
                      appText(context, 'nav_dex'),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${_pokemonList.length} ${appText(context, 'loaded')}',
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: _audioService.musicMuted
                      ? 'Activar música'
                      : 'Silenciar música',
                  onPressed: () {
                    setState(() => _audioService.toggleMusicMute());
                  },
                  icon: Icon(
                    _audioService.musicMuted
                        ? Icons.music_off_rounded
                        : Icons.music_note_rounded,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlight() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        height: 126,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6536C8), Color(0xFF40318C), Color(0xFF253C78)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6536C8).withOpacity(0.3),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          onTap: _surpriseMe,
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              const Positioned(
                right: -28,
                top: -45,
                child: DecorativePokeball(
                  size: 205,
                  color: Colors.white,
                  opacity: 0.1,
                ),
              ),
              Positioned(
                right: 28,
                bottom: 15,
                child: Icon(
                  Icons.auto_awesome,
                  size: 23,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 17, 116, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8BF0B0),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'TU AVENTURA COMIENZA AQUÍ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Encuentra tu\npróximo favorito',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Toca y descubre un Pokémon al azar.',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilters() {
    const filters = <(String?, String, Color)>[
      (null, 'Todos los tipos', Color(0xFFFF6B6B)),
      ('normal', 'Normal', Color(0xFFBDBDBD)),
      ('fire', 'Fuego', Color(0xFFFF6B35)),
      ('water', 'Agua', Color(0xFF4FC3F7)),
      ('electric', 'Eléctrico', Color(0xFFFFD54F)),
      ('grass', 'Planta', Color(0xFF66BB6A)),
      ('ice', 'Hielo', Color(0xFF80DEEA)),
      ('fighting', 'Lucha', Color(0xFFFF7043)),
      ('poison', 'Veneno', Color(0xFFAB47BC)),
      ('ground', 'Tierra', Color(0xFFBCAAA4)),
      ('flying', 'Volador', Color(0xFF90CAF9)),
      ('psychic', 'Psíquico', Color(0xFFEC407A)),
      ('bug', 'Bicho', Color(0xFF9CCC65)),
      ('rock', 'Roca', Color(0xFF8D6E63)),
      ('ghost', 'Fantasma', Color(0xFF7E57C2)),
      ('dragon', 'Dragón', Color(0xFF7C4DFF)),
      ('dark', 'Siniestro', Color(0xFF8D6E63)),
      ('steel', 'Acero', Color(0xFF78909C)),
      ('fairy', 'Hada', Color(0xFFF48FB1)),
    ];

    final selectedFilter = filters.firstWhere(
      (filter) => filter.$1 == _selectedType,
    );
    final dropdownWidth = MediaQuery.sizeOf(context).width < 360
        ? 160.0
        : 190.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_outlined,
            color: Colors.white54,
            size: 19,
          ),
          const SizedBox(width: 8),
          Text(
            'TIPO',
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Container(
            width: dropdownWidth,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.075),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: selectedFilter.$3.withOpacity(0.42)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedType,
                isExpanded: true,
                menuMaxHeight: 420,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: const Color(0xFF1D1B31),
                icon: const Icon(
                  Icons.expand_more_rounded,
                  color: Colors.white70,
                ),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                selectedItemBuilder: (context) => filters
                    .map(
                      (filter) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          filter.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                items: filters
                    .map(
                      (filter) => DropdownMenuItem<String?>(
                        value: filter.$1,
                        child: Row(
                          children: [
                            Icon(
                              filter.$1 == null
                                  ? Icons.catching_pokemon
                                  : Icons.circle,
                              color: filter.$3,
                              size: filter.$1 == null ? 16 : 9,
                            ),
                            const SizedBox(width: 10),
                            Text(filter.$2),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (type) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedType = type);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return CompositedTransformTarget(
      link: _searchLayerLink,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
              onSubmitted: _submitSearch,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o ID...',
                hintStyle: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 16,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    if (!_showSearchSuggestions) return const SizedBox.shrink();

    final suggestions = _searchSuggestions;
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF17192A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFBBA0FF),
                      size: 14,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'COINCIDENCIAS',
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              for (var index = 0; index < suggestions.length; index++) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    indent: 14,
                    endIndent: 14,
                    color: Colors.white.withOpacity(0.06),
                  ),
                _buildSuggestionTile(suggestions[index]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(Map<String, dynamic> entry) {
    final name = entry['name'] as String;
    final id = _extractIdFromUrl(entry['url'] as String);
    final homeSprite =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$id.png';
    final officialArtwork =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
    final displayName = name
        .split('-')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectSearchSuggestion(entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.055),
                ),
                child: Image.network(
                  homeSprite,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.network(
                    officialArtwork,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.catching_pokemon,
                      color: Colors.white38,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${id.padLeft(3, '0')}',
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.north_west_rounded,
                color: Colors.white30,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final visiblePokemon = _visiblePokemon;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SpinningPokeball(size: 80),
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
                label: Text(
                  'Reintentar',
                  style: GoogleFonts.outfit(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final searchQuery = _normalizeSearchQuery(_searchController.text);
    final isPartialSearch =
        searchQuery.isNotEmpty && !_isExactCatalogMatch(searchQuery);
    if (isPartialSearch && visiblePokemon.isEmpty) {
      if (!_catalogReady) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SpinningPokeball(size: 54),
              const SizedBox(height: 14),
              Text(
                'Preparando la búsqueda...',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        );
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchSuggestions.isEmpty
                    ? Icons.search_off_rounded
                    : Icons.touch_app_rounded,
                color: Colors.white.withOpacity(0.3),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _searchSuggestions.isEmpty
                    ? 'No se encontraron coincidencias'
                    : 'Elige una coincidencia para ver su ficha',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
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

    if (visiblePokemon.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_alt_off_rounded,
                color: Colors.white.withOpacity(0.35),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'No hay de este tipo entre los ${_pokemonList.length} Pokémon cargados.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _selectedType = null),
                    child: const Text('Ver todos'),
                  ),
                  TextButton.icon(
                    onPressed: _isLoadingMore ? null : _loadMorePokemon,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(_isLoadingMore ? 'Cargando...' : 'Cargar más'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = screenWidth >= 1100
        ? 4
        : screenWidth >= 720
        ? 3
        : 2;

    return Stack(
      children: [
        GridView.builder(
          controller: _scrollController,
          addAutomaticKeepAlives: false,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: screenWidth >= 720
                ? 0.98
                : screenWidth < 360
                ? 0.82
                : 0.88,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount:
              visiblePokemon.length +
              (_isLoadingMore || _loadMoreError != null ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= visiblePokemon.length) {
              if (_loadMoreError != null) {
                return Center(
                  child: TextButton.icon(
                    onPressed: _loadMorePokemon,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar carga'),
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(child: SpinningPokeball(size: 50)),
              );
            }

            final pokemon = visiblePokemon[index];
            final animation = index < _cardAnimations.length
                ? _cardAnimations[index]
                : null;

            final card = PokemonCard(
              pokemon: pokemon,
              onTap: () => _openPokemon(pokemon),
            );

            if (animation != null) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: card,
                ),
              );
            }

            return card;
          },
        ),
        // Botón flotante para regresar al inicio
        Positioned(
          right: 16,
          bottom: 16,
          child: AnimatedOpacity(
            opacity:
                _scrollController.hasClients &&
                    _scrollController.position.pixels > 500
                ? 1.0
                : 0.0,
            duration: const Duration(milliseconds: 300),
            child: FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: const Color(0xFFFF6B6B),
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
