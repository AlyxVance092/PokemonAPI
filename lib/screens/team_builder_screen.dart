import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pokemon_model.dart';
import '../services/app_language.dart';
import '../services/local_dex_store.dart';
import '../services/pokemon_service.dart';
import '../widgets/animated_pokemon_sprite.dart';

const _battleTypes = <String>[
  'normal',
  'fire',
  'water',
  'electric',
  'grass',
  'ice',
  'fighting',
  'poison',
  'ground',
  'flying',
  'psychic',
  'bug',
  'rock',
  'ghost',
  'dragon',
  'dark',
  'steel',
  'fairy',
];

class TeamBuilderScreen extends StatefulWidget {
  const TeamBuilderScreen({super.key});

  @override
  State<TeamBuilderScreen> createState() => _TeamBuilderScreenState();
}

class _TeamBuilderScreenState extends State<TeamBuilderScreen> {
  final LocalDexStore _store = LocalDexStore();
  final PokemonService _service = PokemonService();
  List<Map<String, dynamic>> _teams = [];
  int _selectedTeam = 0;
  bool _ready = false;
  late Future<_TeamAnalysis> _analysisFuture;

  Map<String, dynamic>? get _team =>
      _teams.isEmpty || _selectedTeam >= _teams.length
      ? null
      : _teams[_selectedTeam];

  List<Map<String, dynamic>> get _members => List<Map<String, dynamic>>.from(
    (_team?['members'] as List? ?? const []).map(
      (member) => Map<String, dynamic>.from(member as Map),
    ),
  );

  @override
  void initState() {
    super.initState();
    _analysisFuture = Future.value(_TeamAnalysis.empty());
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    var teams = await _store.getTeams();
    if (teams.isEmpty) {
      teams = [
        {'name': 'Mi primer equipo', 'members': <Map<String, dynamic>>[]},
      ];
      await _store.saveTeams(teams);
    }
    if (!mounted) return;
    setState(() {
      _teams = teams;
      _selectedTeam = 0;
      _ready = true;
      _analysisFuture = _analyse(_teams.first);
    });
  }

  Future<void> _persist({bool refreshAnalysis = true}) async {
    await _store.saveTeams(_teams);
    if (!mounted) return;
    if (refreshAnalysis && _team != null) {
      setState(() => _analysisFuture = _analyse(_team!));
    } else {
      setState(() {});
    }
  }

  Future<void> _createTeam() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo equipo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          decoration: const InputDecoration(labelText: 'Nombre del equipo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    setState(() {
      _teams = [
        ..._teams,
        {'name': name, 'members': <Map<String, dynamic>>[]},
      ];
      _selectedTeam = _teams.length - 1;
      _analysisFuture = _analyse(_team!);
    });
    await _store.saveTeams(_teams);
  }

  Future<void> _addPokemon() async {
    if (_members.length >= 6) {
      _showMessage('Un equipo puede tener hasta seis Pokémon.');
      return;
    }
    final pokemon = await showDialog<Pokemon>(
      context: context,
      builder: (context) => const _PokemonPickerDialog(),
    );
    if (pokemon == null || _team == null) return;
    if (_members.any((member) => member['id'] == pokemon.id)) {
      _showMessage('Ese Pokémon ya está en este equipo.');
      return;
    }
    final members = [
      ..._members,
      {'id': pokemon.id, 'moves': <String>[]},
    ];
    _team!['members'] = members;
    await _persist();
  }

  Future<void> _removeMember(int id) async {
    _team!['members'] = _members.where((member) => member['id'] != id).toList();
    await _persist();
  }

  Future<void> _toggleMove(int pokemonId, String moveName) async {
    final member = _members.firstWhere((entry) => entry['id'] == pokemonId);
    final moves = List<String>.from(member['moves'] as List? ?? const []);
    if (moves.contains(moveName)) {
      moves.remove(moveName);
    } else if (moves.length < 4) {
      moves.add(moveName);
    } else {
      _showMessage('Cada Pokémon puede llevar hasta cuatro movimientos.');
      return;
    }
    member['moves'] = moves;
    _team!['members'] = _members.map((entry) {
      return entry['id'] == pokemonId ? member : entry;
    }).toList();
    await _persist();
  }

  Future<_TeamAnalysis> _analyse(Map<String, dynamic> team) async {
    final members = List<Map<String, dynamic>>.from(
      (team['members'] as List? ?? const []).map(
        (member) => Map<String, dynamic>.from(member as Map),
      ),
    );
    if (members.isEmpty) return _TeamAnalysis.empty();
    try {
      final pokemon = await Future.wait(
        members.map((member) => _service.getPokemon('${member['id']}')),
      );
      final chartValues = await Future.wait(
        _battleTypes.map((type) => _service.getResource('type/$type')),
      );
      final chart = <String, Map<String, dynamic>>{
        for (final data in chartValues) data['name'] as String: data,
      };
      final selectedMoves = <String>{
        for (final member in members)
          ...List<String>.from(member['moves'] as List? ?? const []),
      };
      final moveTypes = <String>{};
      for (final move in selectedMoves) {
        try {
          final data = await _service.getResource('move/$move');
          final type = data['type']?['name'] as String?;
          if (type != null) moveTypes.add(type);
        } catch (_) {
          // Keep showing the team's type defense when a move is uncached offline.
        }
      }

      final weak = <String, int>{};
      final resist = <String, int>{};
      final immune = <String, int>{};
      for (final attackType in _battleTypes) {
        for (final member in pokemon) {
          var multiplier = 1.0;
          for (final defendingType in member.types) {
            final relations =
                chart[defendingType.name]?['damage_relations'] as Map?;
            if (relations == null) continue;
            if (_relationContains(relations['double_damage_from'], attackType))
              multiplier *= 2;
            if (_relationContains(relations['half_damage_from'], attackType))
              multiplier *= 0.5;
            if (_relationContains(relations['no_damage_from'], attackType))
              multiplier = 0;
          }
          if (multiplier > 1)
            weak.update(attackType, (value) => value + 1, ifAbsent: () => 1);
          if (multiplier > 0 && multiplier < 1)
            resist.update(attackType, (value) => value + 1, ifAbsent: () => 1);
          if (multiplier == 0)
            immune.update(attackType, (value) => value + 1, ifAbsent: () => 1);
        }
      }

      final coveredTypes = <String>{};
      for (final moveType in moveTypes) {
        final relations = chart[moveType]?['damage_relations'] as Map?;
        for (final entry
            in relations?['double_damage_to'] as List? ?? const []) {
          if (entry is Map && entry['name'] is String)
            coveredTypes.add(entry['name'] as String);
        }
      }
      return _TeamAnalysis(
        weaknesses: weak,
        resistances: resist,
        immunities: immune,
        coveredTypes: coveredTypes,
        missingCoverage: _battleTypes
            .where((type) => !coveredTypes.contains(type))
            .toSet(),
        memberCount: pokemon.length,
        moveCount: selectedMoves.length,
      );
    } catch (_) {
      return _TeamAnalysis.empty(memberCount: members.length);
    }
  }

  bool _relationContains(dynamic entries, String name) {
    return (entries as List? ?? const []).any(
      (entry) => entry is Map && entry['name'] == name,
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: Text(
          appText(context, 'team_title'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Crear equipo',
            onPressed: _createTeam,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
          ? const Center(child: Text('Crea tu primer equipo'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedTeam,
                  decoration: InputDecoration(
                    labelText: 'Equipo activo',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: const Color(0xFF1A2030),
                  items: [
                    for (var index = 0; index < _teams.length; index++)
                      DropdownMenuItem(
                        value: index,
                        child: Text(
                          _teams[index]['name'] as String? ?? 'Equipo',
                        ),
                      ),
                  ],
                  onChanged: (index) {
                    if (index == null) return;
                    setState(() {
                      _selectedTeam = index;
                      _analysisFuture = _analyse(_team!);
                    });
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Integrantes',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${_members.length}/6',
                      style: GoogleFonts.outfit(color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                for (final member in _members)
                  _TeamMemberCard(
                    key: ValueKey(member['id']),
                    id: member['id'] as int,
                    selectedMoves: List<String>.from(
                      member['moves'] as List? ?? const [],
                    ),
                    onRemove: () => _removeMember(member['id'] as int),
                    onMoveChanged: (move) =>
                        _toggleMove(member['id'] as int, move),
                  ),
                if (_members.length < 6)
                  OutlinedButton.icon(
                    onPressed: _addPokemon,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Agregar Pokémon'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                const SizedBox(height: 18),
                FutureBuilder<_TeamAnalysis>(
                  future: _analysisFuture,
                  builder: (context, snapshot) => _TeamAnalysisPanel(
                    analysis: snapshot.data,
                    loading: snapshot.connectionState != ConnectionState.done,
                  ),
                ),
              ],
            ),
    );
  }
}

class _PokemonPickerDialog extends StatefulWidget {
  const _PokemonPickerDialog();

  @override
  State<_PokemonPickerDialog> createState() => _PokemonPickerDialogState();
}

class _PokemonPickerDialogState extends State<_PokemonPickerDialog> {
  final TextEditingController _query = TextEditingController();
  Pokemon? _pokemon;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final value = _query.text.trim().toLowerCase();
    if (value.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pokemon = await PokemonService().getPokemon(
        value,
        includeMoves: true,
      );
      if (!mounted) return;
      setState(() {
        _pokemon = pokemon;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No encontré ese Pokémon. Revisa el nombre o número.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Buscar Pokémon'),
    content: SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _query,
            autofocus: true,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Nombre o número',
              suffixIcon: IconButton(
                onPressed: _search,
                icon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          if (_pokemon case final pokemon?) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: AnimatedPokemonSprite(
                    animatedUrl:
                        pokemon.sprites.homeArtwork ??
                        pokemon.sprites.officialArtwork,
                    staticUrl: pokemon.sprites.frontDefault,
                    size: 72,
                    bobbingOffset: 2,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pokemon.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        pokemon.types.map((type) => type.name).join(' / '),
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _pokemon == null
            ? null
            : () => Navigator.pop(context, _pokemon),
        child: const Text('Agregar'),
      ),
    ],
  );
}

class _TeamMemberCard extends StatefulWidget {
  final int id;
  final List<String> selectedMoves;
  final VoidCallback onRemove;
  final ValueChanged<String> onMoveChanged;

  const _TeamMemberCard({
    super.key,
    required this.id,
    required this.selectedMoves,
    required this.onRemove,
    required this.onMoveChanged,
  });

  @override
  State<_TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<_TeamMemberCard> {
  late final Future<Pokemon> _pokemon = PokemonService().getPokemon(
    '${widget.id}',
    includeMoves: true,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Pokemon>(
      future: _pokemon,
      builder: (context, snapshot) {
        final pokemon = snapshot.data;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF171C2B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              leading: SizedBox(
                width: 54,
                height: 54,
                child:
                    pokemon?.sprites.homeArtwork == null &&
                        pokemon?.sprites.officialArtwork == null
                    ? const Icon(Icons.catching_pokemon, color: Colors.white38)
                    : AnimatedPokemonSprite(
                        key: ValueKey('team-sprite-${widget.id}'),
                        animatedUrl:
                            pokemon?.sprites.homeArtwork ??
                            pokemon?.sprites.officialArtwork,
                        staticUrl: pokemon?.sprites.frontDefault,
                        size: 54,
                      ),
              ),
              title: Text(
                pokemon?.name ?? 'Cargando #${widget.id}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                pokemon?.types.map((type) => type.name).join(' / ') ??
                    'Modo sin conexión: usa el dato guardado',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
              ),
              trailing: IconButton(
                tooltip: 'Quitar del equipo',
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
              ),
              children: [
                if (pokemon == null)
                  const Text(
                    'No se pudo leer el conjunto de movimientos sin conexión.',
                  )
                else if (pokemon.moves.isEmpty)
                  const Text('No hay movimientos guardados para este Pokémon.')
                else ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Movimientos (elige hasta 4)',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 1,
                    children: pokemon.moves.take(30).map((move) {
                      final selected = widget.selectedMoves.contains(move.name);
                      return FilterChip(
                        label: Text(move.name.replaceAll('-', ' ')),
                        selected: selected,
                        onSelected: (_) => widget.onMoveChanged(move.name),
                        selectedColor: const Color(0xFF7660D8),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontSize: 11,
                        ),
                        backgroundColor: Colors.white.withOpacity(0.05),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TeamAnalysisPanel extends StatelessWidget {
  final _TeamAnalysis? analysis;
  final bool loading;

  const _TeamAnalysisPanel({required this.analysis, required this.loading});

  @override
  Widget build(BuildContext context) {
    final value = analysis ?? _TeamAnalysis.empty();
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF202B46), Color(0xFF171D2C)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF7B68D9).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Color(0xFFB9A8FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Análisis de cobertura',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Cuenta debilidades y resistencias del equipo y revisa qué tipos cubren tus movimientos elegidos.',
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          _TypeCountRow(
            title: 'Debilidades del equipo',
            values: value.weaknesses,
            color: const Color(0xFFFF817C),
          ),
          _TypeCountRow(
            title: 'Resistencias',
            values: value.resistances,
            color: const Color(0xFF75D7B0),
          ),
          _TypeCountRow(
            title: 'Inmunidades',
            values: value.immunities,
            color: const Color(0xFF8AB7FF),
          ),
          const Divider(color: Colors.white12, height: 24),
          Text(
            'Cobertura ofensiva: ${value.coveredTypes.length}/${_battleTypes.length} tipos',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          if (value.moveCount == 0)
            Text(
              'Abre cada Pokémon y elige sus movimientos para calcular la cobertura.',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
            )
          else
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final type in value.coveredTypes)
                  _TypePill(type: type, color: const Color(0xFF73D2AC)),
                for (final type in value.missingCoverage.take(8))
                  _TypePill(type: type, color: Colors.white30),
              ],
            ),
          if (value.moveCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                'Los tonos apagados señalan tipos que aún no cubren los movimientos seleccionados.',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypeCountRow extends StatelessWidget {
  final String title;
  final Map<String, int> values;
  final Color color;
  const _TypeCountRow({
    required this.title,
    required this.values,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        if (values.isEmpty)
          Text('—', style: GoogleFonts.outfit(color: Colors.white30))
        else
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: values.entries
                .map(
                  (entry) => _TypePill(
                    type: '${entry.key} ×${entry.value}',
                    color: color,
                  ),
                )
                .toList(),
          ),
      ],
    ),
  );
}

class _TypePill extends StatelessWidget {
  final String type;
  final Color color;
  const _TypePill({required this.type, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.13),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.28)),
    ),
    child: Text(
      type,
      style: GoogleFonts.outfit(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _TeamAnalysis {
  final Map<String, int> weaknesses;
  final Map<String, int> resistances;
  final Map<String, int> immunities;
  final Set<String> coveredTypes;
  final Set<String> missingCoverage;
  final int memberCount;
  final int moveCount;

  const _TeamAnalysis({
    required this.weaknesses,
    required this.resistances,
    required this.immunities,
    required this.coveredTypes,
    required this.missingCoverage,
    required this.memberCount,
    required this.moveCount,
  });

  factory _TeamAnalysis.empty({int memberCount = 0}) => _TeamAnalysis(
    weaknesses: const {},
    resistances: const {},
    immunities: const {},
    coveredTypes: const {},
    missingCoverage: _battleTypes.toSet(),
    memberCount: memberCount,
    moveCount: 0,
  );
}
