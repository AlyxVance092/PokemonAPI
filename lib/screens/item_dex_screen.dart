import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/pokemon_service.dart';
import '../services/app_language.dart';

class ItemDexScreen extends StatefulWidget {
  const ItemDexScreen({super.key});

  @override
  State<ItemDexScreen> createState() => _ItemDexScreenState();
}

class _ItemDexScreenState extends State<ItemDexScreen> {
  final PokemonService _service = PokemonService();
  final TextEditingController _searchController = TextEditingController();
  String _category = '';
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  static const _categories = <(String, String)>[
    ('', 'Todas'),
    ('standard-balls', 'Poké Balls'),
    ('medicine', 'Medicina'),
    ('healing', 'Curación'),
    ('status-cures', 'Estados'),
    ('revival', 'Revivir'),
    ('berries', 'Bayas'),
    ('held-items', 'Equipables'),
    ('choice', 'Elección'),
    ('stat-boosts', 'Estadísticas'),
    ('type-enhancement', 'Potenciadores'),
    ('evolution', 'Evolución'),
    ('mega-stones', 'Megapiedras'),
    ('z-crystals', 'Cristales Z'),
  ];

  List<Map<String, dynamic>> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items
        .where((item) => (item['name'] as String? ?? '').contains(query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<dynamic> entries;
      if (_category.isEmpty) {
        entries = await _service.getResourceList('item', limit: 2000);
      } else {
        final response = await _service.getResource('item-category/$_category');
        entries = response['items'] as List;
      }
      if (!mounted) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(entries);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleItems;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: Text(
          appText(context, 'item_title'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar objetos…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final entry = _categories[index];
                final selected = _category == entry.$1;
                return ChoiceChip(
                  label: Text(entry.$2),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _category = entry.$1);
                    _loadItems();
                  },
                  selectedColor: const Color(0xFF7E62E8),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 12,
                  ),
                  backgroundColor: const Color(0xFF1B2030),
                  side: BorderSide.none,
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _MessageState(
                    icon: Icons.wifi_off_rounded,
                    title: 'No pude cargar los objetos',
                    detail: _error!,
                    onRetry: _loadItems,
                  )
                : visible.isEmpty
                ? const _MessageState(
                    icon: Icons.search_off_rounded,
                    title: 'Sin coincidencias',
                    detail: 'Prueba otra búsqueda o categoría.',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.sizeOf(context).width > 850
                          ? 4
                          : 2,
                      childAspectRatio: 1.25,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) => _ItemTile(
                      entry: visible[index],
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: const Color(0xFF151B2A),
                        builder: (_) => _ItemDetailSheet(
                          name: visible[index]['name'] as String,
                        ),
                      ),
                    ),
                  ),
          ),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Text(
                'La API aporta categorías y disponibilidad por juego; no publica puntos de aparición de todos los objetos.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onTap;

  const _ItemTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rawName = entry['name'] as String? ?? '';
    final name = rawName.replaceAll('-', ' ');
    final id = _idFromUrl(entry['url'] as String? ?? '');
    return Material(
      color: const Color(0xFF171C2B),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF8C72E8).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Image.network(
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/$rawName.png',
                    width: 34,
                    height: 34,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFFC2B5FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleCase(name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '#$id',
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemDetailSheet extends StatefulWidget {
  final String name;
  const _ItemDetailSheet({required this.name});

  @override
  State<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<_ItemDetailSheet> {
  late final Future<Map<String, dynamic>> _item = PokemonService().getResource(
    'item/${widget.name}',
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _item,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final sprite = data?['sprites']?['default'] as String?;
          final effectEntries = data?['effect_entries'] as List? ?? [];
          final spanishEffects = effectEntries.cast<Map>().where((entry) {
            return entry['language']?['name'] == 'es';
          }).toList();
          final englishEffects = effectEntries.cast<Map>().where((entry) {
            return entry['language']?['name'] == 'en';
          }).toList();
          final effect = spanishEffects.isNotEmpty
              ? spanishEffects.first
              : englishEffects.isNotEmpty
              ? englishEffects.first
              : null;
          final flavorEntries = data?['flavor_text_entries'] as List? ?? [];
          final spanishFlavors = flavorEntries.cast<Map>().where((entry) {
            return entry['language']?['name'] == 'es';
          }).toList();
          final flavor = spanishFlavors.isEmpty ? null : spanishFlavors.first;
          final versions = (data?['game_indices'] as List? ?? [])
              .map(
                (entry) => (entry['version']?['name'] as String? ?? '')
                    .replaceAll('-', ' '),
              )
              .toSet()
              .take(8)
              .join(' · ');
          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
            child: snapshot.connectionState != ConnectionState.done
                ? const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : data == null
                ? const Text('No hay datos guardados de este objeto.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (sprite != null)
                            Image.network(sprite, width: 56, height: 56),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _titleCase(
                                (data['name'] as String).replaceAll('-', ' '),
                              ),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoLine(
                        label: 'Categoría',
                        value: _titleCase(
                          (data['category']?['name'] as String? ??
                                  'Sin categoría')
                              .replaceAll('-', ' '),
                        ),
                      ),
                      _InfoLine(
                        label: 'Precio',
                        value: '${data['cost'] ?? 0}₽',
                      ),
                      if (effect != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            (effect['effect'] as String? ?? '').replaceAll(
                              '\n',
                              ' ',
                            ),
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ),
                      if (flavor != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            (flavor['text'] as String? ?? '').replaceAll(
                              '\n',
                              ' ',
                            ),
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      if (versions.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Registrado en: $versions',
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: Colors.white38)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white70)),
        ),
      ],
    ),
  );
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onRetry;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white30, size: 46),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

String _titleCase(String value) => value
    .split(' ')
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

String _idFromUrl(String url) {
  final segments =
      Uri.tryParse(url)?.pathSegments
          .where((part) => part.isNotEmpty)
          .toList() ??
      [];
  return segments.isEmpty ? '—' : segments.last;
}
