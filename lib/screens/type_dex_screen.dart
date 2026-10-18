import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/pokemon_service.dart';
import '../services/app_language.dart';

const _dexTypes = <String>[
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

const _typeColors = <String, Color>{
  'normal': Color(0xFFA8A77A),
  'fire': Color(0xFFEE8130),
  'water': Color(0xFF6390F0),
  'electric': Color(0xFFF7D02C),
  'grass': Color(0xFF7AC74C),
  'ice': Color(0xFF96D9D6),
  'fighting': Color(0xFFC22E28),
  'poison': Color(0xFFA33EA1),
  'ground': Color(0xFFE2BF65),
  'flying': Color(0xFFA98FF3),
  'psychic': Color(0xFFF95587),
  'bug': Color(0xFFA6B91A),
  'rock': Color(0xFFB6A136),
  'ghost': Color(0xFF735797),
  'dragon': Color(0xFF6F35FC),
  'dark': Color(0xFF705746),
  'steel': Color(0xFFB7B7CE),
  'fairy': Color(0xFFD685AD),
};

const _spanishTypeNames = <String, String>{
  'normal': 'Normal',
  'fire': 'Fuego',
  'water': 'Agua',
  'electric': 'Eléctrico',
  'grass': 'Planta',
  'ice': 'Hielo',
  'fighting': 'Lucha',
  'poison': 'Veneno',
  'ground': 'Tierra',
  'flying': 'Volador',
  'psychic': 'Psíquico',
  'bug': 'Bicho',
  'rock': 'Roca',
  'ghost': 'Fantasma',
  'dragon': 'Dragón',
  'dark': 'Siniestro',
  'steel': 'Acero',
  'fairy': 'Hada',
};

class TypeDexScreen extends StatefulWidget {
  const TypeDexScreen({super.key});

  @override
  State<TypeDexScreen> createState() => _TypeDexScreenState();
}

class _TypeDexScreenState extends State<TypeDexScreen> {
  late Future<List<Map<String, dynamic>>> _types;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _types = _loadTypes();
  }

  Future<List<Map<String, dynamic>>> _loadTypes() async {
    final values = await Future.wait(
      _dexTypes.map((type) => PokemonService().getResource('type/$type')),
    );
    return values;
  }

  void _showRelations(Map<String, dynamic> type) {
    setState(() => _selectedType = type['name'] as String);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F0F1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF111827),
      title: Text(
        appText(context, 'type_title'),
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
      ),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _types,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white38,
                  size: 42,
                ),
                const SizedBox(height: 9),
                const Text('No pude cargar la tabla de tipos.'),
                TextButton(
                  onPressed: () => setState(() => _types = _loadTypes()),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final types = snapshot.data!;
        final selected = types
            .where((type) => type['name'] == _selectedType)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3764), Color(0xFF181D2D)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Toca un tipo para consultar sus fortalezas, resistencias e inmunidades. Las relaciones se calculan con la tabla de tipos de PokéAPI.',
                style: GoogleFonts.outfit(color: Colors.white70, height: 1.35),
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width > 780 ? 6 : 3,
                childAspectRatio: 2.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: types.length,
              itemBuilder: (context, index) {
                final type = types[index];
                final name = type['name'] as String;
                final color = _typeColors[name] ?? Colors.blueGrey;
                final chosen = name == _selectedType;
                return Material(
                  color: color.withOpacity(chosen ? 0.85 : 0.22),
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    onTap: () => _showRelations(type),
                    borderRadius: BorderRadius.circular(15),
                    child: Center(
                      child: Text(
                        (_spanishTypeNames[name] ?? name).toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          letterSpacing: 0.5,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (selected.isNotEmpty) ...[
              const SizedBox(height: 16),
              _TypeRelationsCard(type: selected.first),
            ] else ...[
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Selecciona un tipo',
                  style: GoogleFonts.outfit(color: Colors.white38),
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}

class _TypeRelationsCard extends StatelessWidget {
  final Map<String, dynamic> type;
  const _TypeRelationsCard({required this.type});

  List<String> _names(dynamic value) => (value as List? ?? const [])
      .map(
        (entry) => _spanishTypeNames[entry['name']] ?? entry['name'] as String,
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final relation = type['damage_relations'] as Map<String, dynamic>;
    final name = type['name'] as String;
    final color = _typeColors[name] ?? Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF171C2B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(_spanishTypeNames[name] ?? name).toUpperCase()} · DEFENSA',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RelationGroup(
            title: 'Débil ante · ×2',
            names: _names(relation['double_damage_from']),
            accent: const Color(0xFFFF827F),
          ),
          _RelationGroup(
            title: 'Resiste · ×½',
            names: _names(relation['half_damage_from']),
            accent: const Color(0xFF74D9AD),
          ),
          _RelationGroup(
            title: 'Inmune · ×0',
            names: _names(relation['no_damage_from']),
            accent: const Color(0xFF8AB7FF),
          ),
          const Divider(color: Colors.white12, height: 24),
          _RelationGroup(
            title: 'Sus ataques son fuertes contra',
            names: _names(relation['double_damage_to']),
            accent: const Color(0xFFFFD166),
          ),
          _RelationGroup(
            title: 'Sus ataques son poco eficaces contra',
            names: _names(relation['half_damage_to']),
            accent: Colors.white54,
          ),
          _RelationGroup(
            title: 'Sus ataques no afectan a',
            names: _names(relation['no_damage_to']),
            accent: const Color(0xFF8AB7FF),
          ),
        ],
      ),
    );
  }
}

class _RelationGroup extends StatelessWidget {
  final String title;
  final List<String> names;
  final Color accent;
  const _RelationGroup({
    required this.title,
    required this.names,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: accent,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        if (names.isEmpty)
          const Text(
            'Ninguno',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: names
                .map(
                  (name) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    ),
  );
}
