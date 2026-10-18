import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pokemon_model.dart';
import '../services/app_language.dart';
import '../services/pokemon_service.dart';
import '../widgets/animated_pokemon_sprite.dart';

class ComparatorScreen extends StatefulWidget {
  const ComparatorScreen({super.key});

  @override
  State<ComparatorScreen> createState() => _ComparatorScreenState();
}

class _ComparatorScreenState extends State<ComparatorScreen> {
  Pokemon? _first;
  Pokemon? _second;

  Future<void> _choose(bool first) async {
    final pokemon = await showDialog<Pokemon>(
      context: context,
      builder: (_) => const _ComparatorPicker(),
    );
    if (pokemon == null) return;
    setState(() {
      if (first) {
        _first = pokemon;
      } else {
        _second = pokemon;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: Text(
          appText(context, 'compare_title'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _PokemonSelectCard(
                  pokemon: _first,
                  label: 'Pokémon A',
                  onTap: () => _choose(true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.compare_arrows_rounded,
                  color: Color(0xFFFFD166),
                  size: 26,
                ),
              ),
              Expanded(
                child: _PokemonSelectCard(
                  pokemon: _second,
                  label: 'Pokémon B',
                  onTap: () => _choose(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_first != null && _second != null) ...[
            _StatComparison(first: _first!, second: _second!),
            const SizedBox(height: 14),
            _AbilityComparison(first: _first!, second: _second!),
          ] else
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF171C2B),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.compare_arrows_rounded,
                    size: 48,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Elige dos Pokémon',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Compara estadísticas base, tipos y habilidades en paralelo.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white54),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PokemonSelectCard extends StatelessWidget {
  final Pokemon? pokemon;
  final String label;
  final VoidCallback onTap;
  const _PokemonSelectCard({
    required this.pokemon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image =
        pokemon?.sprites.homeArtwork ?? pokemon?.sprites.officialArtwork;
    return Material(
      color: const Color(0xFF181E2D),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: pokemon == null
                  ? Colors.white12
                  : const Color(0xFF7D68D9).withOpacity(0.5),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: image == null
                    ? const Icon(
                        Icons.add_circle_outline_rounded,
                        color: Colors.white30,
                        size: 42,
                      )
                    : AnimatedPokemonSprite(
                        animatedUrl: image,
                        staticUrl: pokemon!.sprites.frontDefault,
                        size: 90,
                        bobbingOffset: 3,
                      ),
              ),
              Text(
                pokemon?.name ?? label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                pokemon == null
                    ? 'Toca para buscar'
                    : pokemon!.types.map((type) => type.name).join(' / '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatComparison extends StatelessWidget {
  final Pokemon first;
  final Pokemon second;
  const _StatComparison({required this.first, required this.second});

  static const _labels = <String, String>{
    'hp': 'PS',
    'attack': 'Ataque',
    'defense': 'Defensa',
    'special-attack': 'At. especial',
    'special-defense': 'Def. especial',
    'speed': 'Velocidad',
  };

  @override
  Widget build(BuildContext context) {
    final totalFirst = first.stats.fold<int>(
      0,
      (sum, stat) => sum + stat.baseStat,
    );
    final totalSecond = second.stats.fold<int>(
      0,
      (sum, stat) => sum + stat.baseStat,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171C2B),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas base',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 12),
          for (final statA in first.stats)
            _StatRow(
              label: _labels[statA.name] ?? statA.name,
              valueA: statA.baseStat,
              valueB: _statValue(second, statA.name),
            ),
          const Divider(color: Colors.white12, height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total  $totalFirst',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF77CFFF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Total  $totalSecond',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFFA979),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${first.name}  ·  azul',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Text(
                '${second.name}  ·  naranja',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

int _statValue(Pokemon pokemon, String name) {
  for (final stat in pokemon.stats) {
    if (stat.name == name) return stat.baseStat;
  }
  return 0;
}

class _StatRow extends StatelessWidget {
  final String label;
  final int valueA;
  final int valueB;
  const _StatRow({
    required this.label,
    required this.valueA,
    required this.valueB,
  });

  @override
  Widget build(BuildContext context) {
    final total = (valueA + valueB).clamp(1, 510);
    final widthA = valueA / total;
    final widthB = valueB / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 78,
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
              Expanded(
                child: Text(
                  '$valueA',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF77CFFF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$valueB',
                  style: const TextStyle(
                    color: Color(0xFFFFA979),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: widthA,
                    child: Container(
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF77CFFF),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: widthB,
                    child: Container(
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFA979),
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AbilityComparison extends StatelessWidget {
  final Pokemon first;
  final Pokemon second;
  const _AbilityComparison({required this.first, required this.second});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF171C2B),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Habilidades',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _AbilityColumn(pokemon: first)),
            const SizedBox(width: 12),
            Expanded(child: _AbilityColumn(pokemon: second)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Los valores son estadísticas base; no incluyen nivel, naturaleza, EV ni IV.',
          style: TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    ),
  );
}

class _AbilityColumn extends StatelessWidget {
  final Pokemon pokemon;
  const _AbilityColumn({required this.pokemon});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        pokemon.name,
        style: const TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.w600,
        ),
      ),
      for (final ability in pokemon.abilities)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${ability.name.replaceAll('-', ' ')}${ability.isHidden ? ' · oculta' : ''}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
    ],
  );
}

class _ComparatorPicker extends StatefulWidget {
  const _ComparatorPicker();

  @override
  State<_ComparatorPicker> createState() => _ComparatorPickerState();
}

class _ComparatorPickerState extends State<_ComparatorPicker> {
  final TextEditingController _controller = TextEditingController();
  Pokemon? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pokemon = await PokemonService().getPokemon(
        _controller.text.trim().toLowerCase(),
      );
      if (!mounted) return;
      setState(() {
        _result = pokemon;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No encontré ese Pokémon.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Elegir Pokémon'),
    content: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
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
              padding: EdgeInsets.all(15),
              child: CircularProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          if (_result case final pokemon?) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: AnimatedPokemonSprite(
                    animatedUrl:
                        pokemon.sprites.homeArtwork ??
                        pokemon.sprites.officialArtwork,
                    staticUrl: pokemon.sprites.frontDefault,
                    size: 60,
                    bobbingOffset: 2,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${pokemon.name}\n${pokemon.types.map((type) => type.name).join(' / ')}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
        onPressed: _result == null
            ? null
            : () => Navigator.pop(context, _result),
        child: const Text('Elegir'),
      ),
    ],
  );
}
