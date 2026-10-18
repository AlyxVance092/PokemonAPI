import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/pokemon_service.dart';
import '../services/app_language.dart';

const _natureNames = <String>[
  'hardy',
  'lonely',
  'brave',
  'adamant',
  'naughty',
  'bold',
  'docile',
  'relaxed',
  'impish',
  'lax',
  'timid',
  'hasty',
  'serious',
  'jolly',
  'naive',
  'modest',
  'mild',
  'quiet',
  'bashful',
  'rash',
  'calm',
  'gentle',
  'sassy',
  'careful',
  'quirky',
];

const _statNames = <String, String>{
  'hp': 'PS',
  'attack': 'Ataque',
  'defense': 'Defensa',
  'special-attack': 'Ataque especial',
  'special-defense': 'Defensa especial',
  'speed': 'Velocidad',
};

const _spanishNatureNames = <String, String>{
  'hardy': 'Fuerte',
  'lonely': 'Huraña',
  'brave': 'Audaz',
  'adamant': 'Firme',
  'naughty': 'Pícara',
  'bold': 'Osada',
  'docile': 'Dócil',
  'relaxed': 'Plácida',
  'impish': 'Agitada',
  'lax': 'Floja',
  'timid': 'Miedosa',
  'hasty': 'Activa',
  'serious': 'Seria',
  'jolly': 'Alegre',
  'naive': 'Ingenua',
  'modest': 'Modesta',
  'mild': 'Afable',
  'quiet': 'Mansa',
  'bashful': 'Tímida',
  'rash': 'Alocada',
  'calm': 'Serena',
  'gentle': 'Amable',
  'sassy': 'Grosera',
  'careful': 'Cauta',
  'quirky': 'Rara',
};

class NatureDexScreen extends StatefulWidget {
  const NatureDexScreen({super.key});

  @override
  State<NatureDexScreen> createState() => _NatureDexScreenState();
}

class _NatureDexScreenState extends State<NatureDexScreen> {
  late Future<List<dynamic>> _natures;

  @override
  void initState() {
    super.initState();
    _natures = PokemonService().getResourceList('nature', limit: 25);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F0F1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF111827),
      title: Text(
        appText(context, 'nature_title'),
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
      ),
    ),
    body: FutureBuilder<List<dynamic>>(
      future: _natures,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No pude cargar las naturalezas.'),
                TextButton(
                  onPressed: () => setState(
                    () => _natures = PokemonService().getResourceList(
                      'nature',
                      limit: 25,
                    ),
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.sizeOf(context).width > 820 ? 4 : 2,
            childAspectRatio: 1.28,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final entry = snapshot.data![index] as Map<String, dynamic>;
            final name = entry['name'] as String? ?? _natureNames[index];
            return _NatureCard(name: name);
          },
        );
      },
    ),
  );
}

class _NatureCard extends StatelessWidget {
  final String name;
  const _NatureCard({required this.name});

  @override
  Widget build(BuildContext context) {
    final pair = _natureEffect(name);
    return Material(
      color: const Color(0xFF181E2D),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF151B2A),
          builder: (_) => _NatureDetailSheet(name: name),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.spa_outlined, color: Color(0xFF8EE0BC)),
              const Spacer(),
              Text(
                _spanishNatureNames[name] ?? _title(name),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pair,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NatureDetailSheet extends StatefulWidget {
  final String name;
  const _NatureDetailSheet({required this.name});

  @override
  State<_NatureDetailSheet> createState() => _NatureDetailSheetState();
}

class _NatureDetailSheetState extends State<_NatureDetailSheet> {
  late final Future<Map<String, dynamic>> _nature = PokemonService()
      .getResource('nature/${widget.name}');

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FutureBuilder<Map<String, dynamic>>(
      future: _nature,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData)
          return const SizedBox(
            height: 160,
            child: Center(child: Text('No hay datos guardados.')),
          );
        final nature = snapshot.data!;
        final increased = nature['increased_stat']?['name'] as String?;
        final decreased = nature['decreased_stat']?['name'] as String?;
        final likes = nature['likes_flavor']?['name'] as String?;
        final hates = nature['hates_flavor']?['name'] as String?;
        final displayName = _localizedNature(nature);
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 14),
              _NatureLine(
                label: 'Aumenta',
                value: increased == null
                    ? 'Sin cambios'
                    : '${_statNames[increased] ?? increased}  +10%',
              ),
              _NatureLine(
                label: 'Disminuye',
                value: decreased == null
                    ? 'Sin cambios'
                    : '${_statNames[decreased] ?? decreased}  −10%',
              ),
              const SizedBox(height: 12),
              if (likes != null)
                _FlavorBerries(flavor: likes, label: 'Bayas de sabor favorito'),
              if (hates != null)
                _FlavorBerries(
                  flavor: hates,
                  label: 'Bayas de sabor que no le gusta',
                ),
              const SizedBox(height: 8),
              Text(
                'Las naturalezas neutrales no suben ni bajan una estadística.',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _FlavorBerries extends StatefulWidget {
  final String flavor;
  final String label;
  const _FlavorBerries({required this.flavor, required this.label});

  @override
  State<_FlavorBerries> createState() => _FlavorBerriesState();
}

class _FlavorBerriesState extends State<_FlavorBerries> {
  late Future<Map<String, dynamic>> _berries = PokemonService().getResource(
    'berry-flavor/${widget.flavor}',
  );

  @override
  void didUpdateWidget(covariant _FlavorBerries oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flavor != widget.flavor) {
      _berries = PokemonService().getResource('berry-flavor/${widget.flavor}');
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _berries,
    builder: (context, snapshot) {
      final berries = (snapshot.data?['berries'] as List? ?? const [])
          .map(
            (entry) => (entry['berry']['name'] as String).replaceAll('-', ' '),
          )
          .toList();
      if (berries.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              berries.map(_title).join(' · '),
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      );
    },
  );
}

class _NatureLine extends StatelessWidget {
  final String label;
  final String value;
  const _NatureLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: Colors.white38)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

String _localizedNature(Map<String, dynamic> nature) {
  final names = nature['names'] as List? ?? const [];
  for (final entry in names) {
    if (entry['language']?['name'] == 'es') return entry['name'] as String;
  }
  return _title(nature['name'] as String? ?? 'naturaleza');
}

String _natureEffect(String name) {
  final neutral = {'hardy', 'docile', 'serious', 'bashful', 'quirky'};
  if (neutral.contains(name)) return 'Naturaleza neutral';
  const effects = <String, (String, String)>{
    'lonely': ('attack', 'defense'),
    'brave': ('attack', 'speed'),
    'adamant': ('attack', 'special-attack'),
    'naughty': ('attack', 'special-defense'),
    'bold': ('defense', 'attack'),
    'relaxed': ('defense', 'speed'),
    'impish': ('defense', 'special-attack'),
    'lax': ('defense', 'special-defense'),
    'timid': ('speed', 'attack'),
    'hasty': ('speed', 'defense'),
    'jolly': ('speed', 'special-attack'),
    'naive': ('speed', 'special-defense'),
    'modest': ('special-attack', 'attack'),
    'mild': ('special-attack', 'defense'),
    'quiet': ('special-attack', 'speed'),
    'rash': ('special-attack', 'special-defense'),
    'calm': ('special-defense', 'attack'),
    'gentle': ('special-defense', 'defense'),
    'sassy': ('special-defense', 'speed'),
    'careful': ('special-defense', 'special-attack'),
  };
  final effect = effects[name];
  if (effect == null) return 'Consulta sus estadísticas';
  return '+${_statNames[effect.$1]} · −${_statNames[effect.$2]}';
}

String _title(String name) => name
    .split(' ')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
