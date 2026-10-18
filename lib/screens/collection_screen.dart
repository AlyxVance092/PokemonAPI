import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pokemon_model.dart';
import '../services/app_language.dart';
import '../services/local_dex_store.dart';
import '../services/pokemon_service.dart';
import '../widgets/animated_pokemon_sprite.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  final LocalDexStore _store = LocalDexStore();
  late final TabController _tabs;
  Set<int> _caught = {};
  Set<int> _shinies = {};
  Map<String, dynamic> _hunt = {'count': 0, 'target': '', 'odds': 4096};
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      _store.getCaughtIds(),
      _store.getShinyIds(),
      _store.getHuntSettings(),
    ]);
    if (!mounted) return;
    setState(() {
      _caught = values[0] as Set<int>;
      _shinies = values[1] as Set<int>;
      _hunt = values[2] as Map<String, dynamic>;
      _ready = true;
    });
  }

  Future<void> _toggleCaught(int id) async {
    final isCaught = !_caught.contains(id);
    setState(() {
      if (isCaught) {
        _caught.add(id);
      } else {
        _caught.remove(id);
      }
    });
    await _store.setCaught(id, isCaught);
  }

  Future<void> _toggleShiny(int id) async {
    final isShiny = !_shinies.contains(id);
    setState(() {
      if (isShiny) {
        _shinies.add(id);
      } else {
        _shinies.remove(id);
      }
    });
    await _store.setShiny(id, isShiny);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: Text(
          appText(context, 'collection_title'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFFFFD166),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(
              icon: const Icon(Icons.catching_pokemon),
              text: appText(context, 'caught'),
            ),
            Tab(
              icon: const Icon(Icons.auto_awesome),
              text: appText(context, 'shinies'),
            ),
            Tab(
              icon: const Icon(Icons.timer_outlined),
              text: appText(context, 'hunt'),
            ),
          ],
        ),
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _CollectionList(
                  ids: _caught.toList()..sort(),
                  caughtIds: _caught,
                  shinyIds: _shinies,
                  emptyTitle: 'Tu aventura empieza aquí',
                  emptyText: 'Guarda una captura desde la ficha o desde aquí.',
                  onCaughtChanged: _toggleCaught,
                  onShinyChanged: _toggleShiny,
                ),
                _CollectionList(
                  ids: _shinies.toList()..sort(),
                  caughtIds: _caught,
                  shinyIds: _shinies,
                  emptyTitle: 'Todavía no hay shinies',
                  emptyText: 'Marca un Pokémon como shiny desde su ficha para guardarlo aquí.',
                  onCaughtChanged: _toggleCaught,
                  onShinyChanged: _toggleShiny,
                ),
                _ShinyHuntCard(
                  settings: _hunt,
                  onChanged: (settings) async {
                    await _store.saveHuntSettings(settings);
                    if (mounted) setState(() => _hunt = settings);
                  },
                ),
              ],
            ),
    );
  }
}

class _CollectionList extends StatelessWidget {
  final List<int> ids;
  final Set<int> caughtIds;
  final Set<int> shinyIds;
  final String emptyTitle;
  final String emptyText;
  final ValueChanged<int> onCaughtChanged;
  final ValueChanged<int> onShinyChanged;

  const _CollectionList({
    required this.ids,
    required this.caughtIds,
    required this.shinyIds,
    required this.emptyTitle,
    required this.emptyText,
    required this.onCaughtChanged,
    required this.onShinyChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.explore_outlined,
                size: 58,
                color: Colors.white24,
              ),
              const SizedBox(height: 12),
              Text(
                emptyTitle,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptyText,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: ids.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        if (index == 0) return const _CollectionHintCard();
        final id = ids[index - 1];
        return _CollectionPokemonTile(
          key: ValueKey('collection-$id'),
          id: id,
          isCaught: caughtIds.contains(id),
          isShiny: shinyIds.contains(id),
          onCaughtChanged: () => onCaughtChanged(id),
          onShinyChanged: () => onShinyChanged(id),
        );
      },
    );
  }
}

class _CollectionHintCard extends StatelessWidget {
  const _CollectionHintCard();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFF203349),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF70CDA6).withOpacity(0.25)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFF70CDA6)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Es un registro personal: agrega o quita capturas y shinies con los botones de cada Pokémon. La app no los captura por ti.',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CollectionPokemonTile extends StatefulWidget {
  final int id;
  final bool isCaught;
  final bool isShiny;
  final VoidCallback onCaughtChanged;
  final VoidCallback onShinyChanged;

  const _CollectionPokemonTile({
    super.key,
    required this.id,
    required this.isCaught,
    required this.isShiny,
    required this.onCaughtChanged,
    required this.onShinyChanged,
  });

  @override
  State<_CollectionPokemonTile> createState() => _CollectionPokemonTileState();
}

class _CollectionPokemonTileState extends State<_CollectionPokemonTile> {
  late Future<Pokemon> _pokemon;

  @override
  void initState() {
    super.initState();
    _pokemon = PokemonService().getPokemon('${widget.id}');
  }

  @override
  void didUpdateWidget(covariant _CollectionPokemonTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _pokemon = PokemonService().getPokemon('${widget.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Pokemon>(
      future: _pokemon,
      builder: (context, snapshot) {
        final pokemon = snapshot.data;
        final image =
            pokemon?.sprites.homeArtwork ??
            pokemon?.sprites.officialArtwork ??
            pokemon?.sprites.frontDefault;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF171C2B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: image == null
                    ? const Icon(Icons.catching_pokemon, color: Colors.white38)
                    : AnimatedPokemonSprite(
                        key: ValueKey('collection-${widget.id}'),
                        animatedUrl: image,
                        staticUrl: pokemon!.sprites.frontDefault,
                        size: 56,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pokemon?.name ??
                          '#${widget.id.toString().padLeft(3, '0')}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '#${widget.id.toString().padLeft(3, '0')}  ·  ${pokemon?.types.map((type) => type.name).join(' / ') ?? 'Pokémon'}',
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: widget.isShiny ? 'Quitar de shinies' : 'Marcar shiny',
                onPressed: widget.onShinyChanged,
                icon: Icon(
                  widget.isShiny
                      ? Icons.auto_awesome
                      : Icons.auto_awesome_outlined,
                  color: widget.isShiny
                      ? const Color(0xFFFFD166)
                      : Colors.white38,
                ),
              ),
              IconButton(
                tooltip: widget.isCaught
                    ? 'Quitar de capturados'
                    : 'Marcar como capturado',
                onPressed: widget.onCaughtChanged,
                icon: Icon(
                  widget.isCaught
                      ? Icons.delete_outline_rounded
                      : Icons.add_circle_outline_rounded,
                  color: widget.isCaught
                      ? const Color(0xFFFF8585)
                      : const Color(0xFF78D6A5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShinyHuntCard extends StatefulWidget {
  final Map<String, dynamic> settings;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const _ShinyHuntCard({required this.settings, required this.onChanged});

  @override
  State<_ShinyHuntCard> createState() => _ShinyHuntCardState();
}

class _ShinyHuntCardState extends State<_ShinyHuntCard> {
  late final TextEditingController _targetController;

  int get _count => widget.settings['count'] as int? ?? 0;
  int get _odds => widget.settings['odds'] as int? ?? 4096;

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(
      text: widget.settings['target'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  void _save({int? count, int? odds, String? target}) {
    widget.onChanged({
      'count': count ?? _count,
      'odds': odds ?? _odds,
      'target': target ?? widget.settings['target'] ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _odds <= 1
        ? 1.0
        : (1 - math.pow(1 - 1 / _odds, _count)).clamp(0.0, 1.0).toDouble();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A2C83), Color(0xFF182342)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFFFD166).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFFFD166),
                size: 30,
              ),
              const SizedBox(height: 12),
              Text(
                'Tu próxima aventura brillante',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 21,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Lleva la cuenta de encuentros. La probabilidad depende del juego y del método que estés usando.',
                style: GoogleFonts.outfit(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _targetController,
                onSubmitted: (value) => _save(target: value.trim()),
                decoration: InputDecoration(
                  labelText: 'Pokémon objetivo',
                  hintText: 'Ej. Eevee',
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Guardar objetivo',
                    onPressed: () =>
                        _save(target: _targetController.text.trim()),
                    icon: const Icon(Icons.check_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Column(
                  children: [
                    Text(
                      '$_count',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 54,
                      ),
                    ),
                    Text(
                      'encuentros registrados',
                      style: GoogleFonts.outfit(color: Colors.white60),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _save(count: _count + 1),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Registrar encuentro'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD166),
                          foregroundColor: const Color(0xFF292033),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _count == 0 ? null : () => _save(count: 0),
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: const Text('Reiniciar contador'),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 28),
              Row(
                children: [
                  const Expanded(child: Text('Tasa configurada por ti')),
                  DropdownButton<int>(
                    value: _odds,
                    dropdownColor: const Color(0xFF20283A),
                    items: const [512, 1024, 2048, 4096, 8192]
                        .map(
                          (odds) => DropdownMenuItem(
                            value: odds,
                            child: Text('1 / $odds'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) _save(odds: value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                color: const Color(0xFFFFD166),
              ),
              const SizedBox(height: 8),
              Text(
                'Esta barra es una referencia configurada, no una promesa de probabilidad del juego.',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
