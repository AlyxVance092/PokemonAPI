import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pokemon_model.dart';
import '../services/pokemon_service.dart';

class PokemonEncyclopediaSections extends StatelessWidget {
  final Pokemon pokemon;
  const PokemonEncyclopediaSections({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _EncyclopediaPanel(
        icon: Icons.menu_book_outlined,
        title: 'Datos de especie y crianza',
        child: _SpeciesDetails(pokemon: pokemon),
      ),
      const SizedBox(height: 12),
      _EncyclopediaPanel(
        icon: Icons.bolt_rounded,
        title: 'Movimientos',
        subtitle: '${pokemon.moves.length} registros de aprendizaje',
        child: _MovesList(pokemon: pokemon),
      ),
      const SizedBox(height: 12),
      _EncyclopediaPanel(
        icon: Icons.place_outlined,
        title: 'Dónde encontrarlo',
        child: _PokemonLocations(pokemon: pokemon),
      ),
    ],
  );
}

class _EncyclopediaPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  const _EncyclopediaPanel({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.055),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        iconColor: Colors.white70,
        collapsedIconColor: Colors.white38,
        leading: Icon(icon, color: const Color(0xFF9D8AFF)),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
              ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [child],
      ),
    ),
  );
}

class _SpeciesDetails extends StatefulWidget {
  final Pokemon pokemon;
  const _SpeciesDetails({required this.pokemon});

  @override
  State<_SpeciesDetails> createState() => _SpeciesDetailsState();
}

class _SpeciesDetailsState extends State<_SpeciesDetails> {
  late Future<Map<String, dynamic>> _species = _load();
  late final PokemonService _service = PokemonService();

  Future<Map<String, dynamic>> _load() =>
      _service.getResource('pokemon-species/${widget.pokemon.speciesId}');

  @override
  void didUpdateWidget(covariant _SpeciesDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pokemon.speciesId != widget.pokemon.speciesId)
      _species = _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _species,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(14),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (!snapshot.hasData) {
        return const Text(
          'La ficha de especie requiere conexión la primera vez.',
        );
      }
      final species = snapshot.data!;
      final description = _localizedText(
        species['flavor_text_entries'] as List? ?? const [],
      );
      final groups = (species['egg_groups'] as List? ?? const [])
          .map((entry) => _pretty(entry['name'] as String))
          .join(' · ');
      final habitat = species['habitat']?['name'] as String?;
      final generation = species['generation']?['name'] as String?;
      final genderRate = species['gender_rate'] as int? ?? -1;
      final gender = genderRate < 0
          ? 'Sin género'
          : '♀ ${(genderRate * 12.5).toStringAsFixed(1)}% · ♂ ${((8 - genderRate) * 12.5).toStringAsFixed(1)}%';
      final hatchCounter = species['hatch_counter'] as int?;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                description,
                style: GoogleFonts.outfit(color: Colors.white70, height: 1.35),
              ),
            ),
          _SpecLine(
            label: 'Grupos huevo',
            value: groups.isEmpty ? 'Sin datos' : groups,
          ),
          _SpecLine(
            label: 'Ratio de captura',
            value: '${species['capture_rate'] ?? '—'} / 255',
          ),
          _SpecLine(label: 'Género', value: gender),
          _SpecLine(
            label: 'Eclosión',
            value: hatchCounter == null ? '—' : '≈ ${hatchCounter * 255} pasos',
          ),
          _SpecLine(
            label: 'Hábitat',
            value: habitat == null ? 'No especificado' : _pretty(habitat),
          ),
          _SpecLine(
            label: 'Generación',
            value: generation == null ? '—' : _pretty(generation),
          ),
          const SizedBox(height: 8),
          _EvolutionChain(url: species['evolution_chain']?['url'] as String?),
        ],
      );
    },
  );
}

class _EvolutionChain extends StatefulWidget {
  final String? url;
  const _EvolutionChain({required this.url});

  @override
  State<_EvolutionChain> createState() => _EvolutionChainState();
}

class _EvolutionChainState extends State<_EvolutionChain> {
  Future<Map<String, dynamic>>? _chain;

  @override
  Widget build(BuildContext context) {
    if (widget.url == null) return const SizedBox.shrink();
    _chain ??= PokemonService().getResourceByUrl(widget.url!);
    return FutureBuilder<Map<String, dynamic>>(
      future: _chain,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData)
          return const SizedBox.shrink();
        final names = <String>[];
        void collect(Map<String, dynamic> node) {
          final species = node['species'] as Map<String, dynamic>?;
          if (species?['name'] is String)
            names.add(_pretty(species!['name'] as String));
          for (final next in node['evolves_to'] as List? ?? const []) {
            collect(Map<String, dynamic>.from(next as Map));
          }
        }

        collect(Map<String, dynamic>.from(snapshot.data!['chain'] as Map));
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Familia evolutiva',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: names
                    .map(
                      (name) => Chip(
                        label: Text(name),
                        backgroundColor: const Color(0xFF262341),
                        labelStyle: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MovesList extends StatefulWidget {
  final Pokemon pokemon;
  const _MovesList({required this.pokemon});

  @override
  State<_MovesList> createState() => _MovesListState();
}

class _MovesListState extends State<_MovesList> {
  final TextEditingController _filter = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moves = widget.pokemon.moves
        .where((move) => move.name.contains(_query))
        .take(80)
        .toList();
    return Column(
      children: [
        TextField(
          controller: _filter,
          onChanged: (value) => setState(
            () => _query = value.trim().toLowerCase().replaceAll(' ', '-'),
          ),
          decoration: InputDecoration(
            hintText: 'Filtrar movimientos',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 7),
        if (moves.isEmpty)
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text('No hay movimientos que coincidan.'),
          )
        else
          for (final move in moves)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.flash_on_rounded,
                color: Color(0xFFFFD166),
                size: 18,
              ),
              title: Text(
                _pretty(move.name),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.info_outline_rounded,
                color: Colors.white30,
                size: 18,
              ),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                backgroundColor: const Color(0xFF151B2A),
                builder: (_) => _MoveDetailSheet(name: move.name),
              ),
            ),
        if (widget.pokemon.moves.length > 80)
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Text(
              'Filtra por nombre para encontrar los demás movimientos.',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),
      ],
    );
  }
}

class _MoveDetailSheet extends StatefulWidget {
  final String name;
  const _MoveDetailSheet({required this.name});

  @override
  State<_MoveDetailSheet> createState() => _MoveDetailSheetState();
}

class _MoveDetailSheetState extends State<_MoveDetailSheet> {
  late final Future<Map<String, dynamic>> _move = PokemonService().getResource(
    'move/${widget.name}',
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FutureBuilder<Map<String, dynamic>>(
      future: _move,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        if (!snapshot.hasData)
          return const SizedBox(
            height: 150,
            child: Center(
              child: Text('No hay datos guardados de este movimiento.'),
            ),
          );
        final move = snapshot.data!;
        final effect = _localizedText(
          move['effect_entries'] as List? ?? const [],
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _pretty(move['name'] as String),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _SpecLine(
                label: 'Tipo',
                value: _pretty(move['type']?['name'] as String? ?? '—'),
              ),
              _SpecLine(
                label: 'Clase',
                value: _pretty(move['damage_class']?['name'] as String? ?? '—'),
              ),
              _SpecLine(label: 'Potencia', value: '${move['power'] ?? '—'}'),
              _SpecLine(
                label: 'Precisión',
                value: '${move['accuracy'] ?? '—'}',
              ),
              _SpecLine(label: 'PP', value: '${move['pp'] ?? '—'}'),
              if (effect.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    effect,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _PokemonLocations extends StatefulWidget {
  final Pokemon pokemon;
  const _PokemonLocations({required this.pokemon});

  @override
  State<_PokemonLocations> createState() => _PokemonLocationsState();
}

class _PokemonLocationsState extends State<_PokemonLocations> {
  late Future<List<Map<String, dynamic>>> _encounters = _load();

  Future<List<Map<String, dynamic>>> _load() =>
      PokemonService().getPokemonEncounters(widget.pokemon.id);

  @override
  void didUpdateWidget(covariant _PokemonLocations oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pokemon.id != widget.pokemon.id) _encounters = _load();
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _encounters,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator()),
        );
      if (!snapshot.hasData)
        return const Text(
          'Las ubicaciones se cargan desde la API la primera vez que abres esta ficha.',
        );
      final entries = snapshot.data!;
      if (entries.isEmpty)
        return const Text(
          'No hay encuentros naturales registrados para esta forma del Pokémon.',
        );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in entries.take(18))
            ExpansionTile(
              dense: true,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(left: 12, bottom: 8),
              title: Text(
                _pretty(
                  (entry['location_area']?['name'] as String? ?? '').replaceAll(
                    '-',
                    ' ',
                  ),
                ),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              subtitle: Text(
                '${(entry['version_details'] as List? ?? const []).length} versiones de juego',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              children: [
                for (final version
                    in (entry['version_details'] as List? ?? const []).take(5))
                  Builder(
                    builder: (context) {
                      final details =
                          version['encounter_details'] as List? ?? const [];
                      final first = details.isEmpty ? null : details.first;
                      final method = first?['method']?['name'] as String?;
                      final minLevel = first?['min_level'];
                      final maxLevel = first?['max_level'];
                      final levelText = minLevel == null
                          ? ''
                          : ' · Nv. $minLevel${maxLevel == minLevel ? '' : '–$maxLevel'}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          '${_pretty((version['version']?['name'] as String? ?? '').replaceAll('-', ' '))}${method == null ? '' : ' · ${_pretty(method)}'}$levelText',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          if (entries.length > 18)
            Text(
              'Y ${entries.length - 18} lugares más',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
        ],
      );
    },
  );
}

class _SpecLine extends StatelessWidget {
  final String label;
  final String value;
  const _SpecLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

String _localizedText(List entries) {
  Map? english;
  for (final entry in entries) {
    if (entry is! Map) continue;
    final language = entry['language']?['name'];
    if (language == 'es')
      return ((entry['flavor_text'] ?? entry['effect'] ?? '') as String)
          .replaceAll('\n', ' ')
          .replaceAll('\f', ' ')
          .trim();
    if (language == 'en') english = entry;
  }
  final englishEntry = english;
  if (englishEntry == null) return '';
  return ((englishEntry['flavor_text'] ?? englishEntry['effect'] ?? '')
          as String)
      .replaceAll('\n', ' ')
      .replaceAll('\f', ' ')
      .trim();
}

String _pretty(String value) => value
    .split('-')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');
