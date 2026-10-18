import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pokemon_model.dart';
import '../services/app_language.dart';
import '../screens/pokemon_detail_screen.dart';
import '../services/pokemon_service.dart';
import '../widgets/animated_pokemon_sprite.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<List<dynamic>> _regions;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _regions = PokemonService().getResourceList('region', limit: 30);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F0F1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF111827),
      title: Text(
        appText(context, 'explore_title'),
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
      ),
      bottom: TabBar(
        controller: _tabs,
        indicatorColor: const Color(0xFF87DBBB),
        tabs: [
          Tab(
            icon: const Icon(Icons.map_outlined),
            text: appText(context, 'regions'),
          ),
          Tab(
            icon: const Icon(Icons.workspace_premium_outlined),
            text: appText(context, 'trainers'),
          ),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabs,
      children: [
        _RegionsList(
          future: _regions,
          onRetry: () => setState(
            () => _regions = PokemonService().getResourceList(
              'region',
              limit: 30,
            ),
          ),
        ),
        const _TrainerArchive(),
      ],
    ),
  );
}

class _RegionsList extends StatelessWidget {
  final Future<List<dynamic>> future;
  final VoidCallback onRetry;
  const _RegionsList({required this.future, required this.onRetry});

  static const _colors = <String, Color>{
    'kanto': Color(0xFF62A7D8),
    'johto': Color(0xFFE5B85C),
    'hoenn': Color(0xFF4FC3B2),
    'sinnoh': Color(0xFF8F8FE8),
    'unova': Color(0xFF7E8AA1),
    'kalos': Color(0xFFDF78A4),
    'alola': Color(0xFFF4A86B),
    'galar': Color(0xFF7FAF83),
    'hisui': Color(0xFFC5A277),
    'paldea': Color(0xFFDA6E72),
  };

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const Center(child: CircularProgressIndicator());
      if (!snapshot.hasData) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 40, color: Colors.white30),
              const SizedBox(height: 8),
              const Text('No pude cargar las regiones.'),
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
        );
      }
      final regions = snapshot.data!;
      return GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.sizeOf(context).width > 850 ? 3 : 2,
          childAspectRatio: 1.38,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: regions.length,
        itemBuilder: (context, index) {
          final region = regions[index] as Map<String, dynamic>;
          final name = region['name'] as String;
          final color = _colors[name] ?? Colors.teal;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PokemapsRegionScreen(
                    regionName: name,
                    regionUrl: region['url'] as String,
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(22),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.72), const Color(0xFF171D2D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: color.withOpacity(0.32)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -18,
                      bottom: -32,
                      child: Icon(
                        Icons.public_rounded,
                        size: 132,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.explore_outlined,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          const Spacer(),
                          Text(
                            _title(name),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Abrir mapa de lugares',
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
        },
      );
    },
  );
}

class PokemapsRegionScreen extends StatelessWidget {
  final String regionName;
  final String regionUrl;

  const PokemapsRegionScreen({
    super.key,
    required this.regionName,
    required this.regionUrl,
  });

  static const _allMaps = _PokemapsEntry(
    title: 'Catálogo completo de mapas',
    games: 'Regiones y juegos disponibles',
    url: 'https://pokemaps.net/maps',
  );

  static const _mapsByRegion = <String, List<_PokemapsEntry>>{
    'kanto': [
      _PokemapsEntry(
        title: 'Kanto',
        games: 'Rojo, Azul y Amarillo',
        url: 'https://pokemaps.net/maps/rby/kanto',
      ),
      _PokemapsEntry(
        title: 'Kanto',
        games: 'Rojo Fuego y Verde Hoja',
        url: 'https://pokemaps.net/maps/frlg/kanto',
      ),
      _PokemapsEntry(
        title: 'Islas Sete',
        games: 'Rojo Fuego y Verde Hoja',
        url: 'https://pokemaps.net/maps/frlg/sevii',
      ),
    ],
    'johto': [
      _PokemapsEntry(
        title: 'Johto y Kanto',
        games: 'Oro, Plata y Cristal',
        url: 'https://pokemaps.net/maps/gsc/johto',
      ),
      _PokemapsEntry(
        title: 'Johto y Kanto',
        games: 'HeartGold y SoulSilver',
        url: 'https://pokemaps.net/maps/hgss/johto',
      ),
    ],
    'hoenn': [
      _PokemapsEntry(
        title: 'Hoenn',
        games: 'Rubí, Zafiro y Esmeralda',
        url: 'https://pokemaps.net/maps/rse/hoenn',
      ),
    ],
    'sinnoh': [
      _PokemapsEntry(
        title: 'Sinnoh',
        games: 'Diamante, Perla y Platino',
        url: 'https://pokemaps.net/maps/dpp/sinnoh',
      ),
    ],
    'hisui': [
      _PokemapsEntry(
        title: 'Hisui',
        games: 'Leyendas Pokémon: Arceus',
        url: 'https://pokemaps.net/maps/la/hisui',
      ),
    ],
    'paldea': [
      _PokemapsEntry(
        title: 'Paldea',
        games: 'Escarlata y Púrpura',
        url: 'https://pokemaps.net/maps/sv/paldea',
      ),
      _PokemapsEntry(
        title: 'Noroteo',
        games: 'El tesoro oculto del Área Cero · Parte 1',
        url: 'https://pokemaps.net/maps/sv/kitakami',
      ),
      _PokemapsEntry(
        title: 'Academia Arándano',
        games: 'El tesoro oculto del Área Cero · Parte 2',
        url: 'https://pokemaps.net/maps/sv/blueberry',
      ),
    ],
    'kalos': [
      _PokemapsEntry(
        title: 'Ciudad Luminalia',
        games: 'Leyendas Pokémon: Z-A',
        url: 'https://pokemaps.net/maps/lza/lumiose',
      ),
    ],
  };

  Future<void> _openMap(BuildContext context, _PokemapsEntry map) async {
    try {
      final opened = await launchUrl(
        Uri.parse(map.url),
        mode: LaunchMode.inAppBrowserView,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir PokéMaps.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir PokéMaps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maps = _mapsByRegion[regionName] ?? const <_PokemapsEntry>[];
    final title = _title(regionName);
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: Text('$title · mapas'),
        actions: [
          IconButton(
            tooltip: 'Todos los mapas',
            onPressed: () => _openMap(context, _allMaps),
            icon: const Icon(Icons.public_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF263D5C), Color(0xFF2E285D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.explore_rounded,
                  color: Color(0xFF8DE0BE),
                  size: 30,
                ),
                const SizedBox(height: 12),
                Text(
                  'Mapas interactivos de $title',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Abre el mapa del juego para explorar rutas, zonas y los Pokémon que aparecen en cada lugar.',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (maps.isEmpty)
            _PokemapsCard(
              entry: _allMaps,
              onTap: () => _openMap(context, _allMaps),
            )
          else
            for (final map in maps)
              _PokemapsCard(entry: map, onTap: () => _openMap(context, map)),
          const SizedBox(height: 8),
          _PokemapsCard(
            entry: _allMaps,
            onTap: () => _openMap(context, _allMaps),
            compact: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Mapas interactivos proporcionados por PokéMaps. Necesitan conexión a internet y se abren en una vista del navegador.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RegionMapScreen(
                  regionName: regionName,
                  regionUrl: regionUrl,
                ),
              ),
            ),
            icon: const Icon(Icons.travel_explore_rounded, size: 18),
            label: const Text('Ver también los encuentros de PokéAPI'),
          ),
        ],
      ),
    );
  }
}

class _PokemapsEntry {
  final String title;
  final String games;
  final String url;

  const _PokemapsEntry({
    required this.title,
    required this.games,
    required this.url,
  });
}

class _PokemapsCard extends StatelessWidget {
  final _PokemapsEntry entry;
  final VoidCallback onTap;
  final bool compact;

  const _PokemapsCard({
    required this.entry,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF171C2B),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF7B68D9).withOpacity(0.18),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.map_rounded, color: Color(0xFFC1B3FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    entry.games,
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              color: Colors.white38,
              size: 19,
            ),
          ],
        ),
      ),
    ),
  );
}

class RegionMapScreen extends StatefulWidget {
  final String regionName;
  final String regionUrl;

  const RegionMapScreen({
    super.key,
    required this.regionName,
    required this.regionUrl,
  });

  @override
  State<RegionMapScreen> createState() => _RegionMapScreenState();
}

class _RegionMapScreenState extends State<RegionMapScreen> {
  late final Future<Map<String, dynamic>> _region = PokemonService()
      .getResourceByUrl(widget.regionUrl);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F0F1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF111827),
      title: Text(
        '${_title(widget.regionName)} · mapa',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
      ),
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _region,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData)
          return const Center(
            child: Text('Esta región no está disponible sin conexión.'),
          );
        final locations = List<Map<String, dynamic>>.from(
          snapshot.data!['locations'] as List? ?? const [],
        );
        locations.sort(
          (a, b) => (a['name'] as String).compareTo(b['name'] as String),
        );
        final columns = 5;
        final rows = math.max(1, (locations.length / columns).ceil());
        final mapWidth = math
            .max(MediaQuery.sizeOf(context).width, 950.0)
            .toDouble();
        final mapHeight = math.max(rows * 128.0 + 120, 420.0).toDouble();
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Explora los lugares y toca un punto para revisar sus zonas y Pokémon disponibles.',
                style: GoogleFonts.outfit(color: Colors.white70, height: 1.3),
              ),
            ),
            SizedBox(
              height: math
                  .min(MediaQuery.sizeOf(context).height * 0.58, 520.0)
                  .toDouble(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InteractiveViewer(
                  minScale: 0.65,
                  maxScale: 2.4,
                  boundaryMargin: const EdgeInsets.all(100),
                  child: SizedBox(
                    width: mapWidth,
                    height: mapHeight,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: Size(mapWidth, mapHeight),
                          painter: _RegionRoutePainter(
                            nodeCount: locations.length,
                            columns: columns,
                          ),
                        ),
                        for (var index = 0; index < locations.length; index++)
                          _LocationMarker(
                            index: index,
                            columns: columns,
                            location: locations[index],
                            onTap: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: const Color(0xFF151B2A),
                              builder: (_) =>
                                  _LocationSheet(location: locations[index]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Text(
                'La API no publica coordenadas cartográficas oficiales; esta vista organiza los lugares en un recorrido interactivo y consulta las zonas reales de cada uno.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _LocationMarker extends StatelessWidget {
  final int index;
  final int columns;
  final Map<String, dynamic> location;
  final VoidCallback onTap;
  const _LocationMarker({
    required this.index,
    required this.columns,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = index ~/ columns;
    final column = row.isEven ? index % columns : columns - 1 - index % columns;
    return Positioned(
      left: 38 + column * 178,
      top: 38 + row * 128,
      width: 155,
      height: 78,
      child: Material(
        color: const Color(0xEE202A3D),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF74CFAD),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF10241C),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _title((location['name'] as String).replaceAll('-', ' ')),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegionRoutePainter extends CustomPainter {
  final int nodeCount;
  final int columns;
  const _RegionRoutePainter({required this.nodeCount, required this.columns});

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFF101B2B);
    canvas.drawRect(Offset.zero & size, background);
    final island = Path()
      ..moveTo(size.width * 0.11, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.03,
        size.width * 0.51,
        size.height * 0.16,
      )
      ..quadraticBezierTo(
        size.width * 0.77,
        size.height * 0.02,
        size.width * 0.91,
        size.height * 0.26,
      )
      ..quadraticBezierTo(
        size.width * 0.96,
        size.height * 0.55,
        size.width * 0.77,
        size.height * 0.77,
      )
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.93,
        size.width * 0.24,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.03,
        size.height * 0.61,
        size.width * 0.11,
        size.height * 0.18,
      )
      ..close();
    canvas.drawPath(island, Paint()..color = const Color(0xFF1A3040));
    canvas.drawPath(
      island,
      Paint()
        ..color = const Color(0xFF3D7A73).withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    final route = Paint()
      ..color = const Color(0xFF8CE0BC).withOpacity(0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path();
    for (var index = 0; index < nodeCount; index++) {
      final row = index ~/ columns;
      final column = row.isEven
          ? index % columns
          : columns - 1 - index % columns;
      final point = Offset(38 + column * 178 + 77, 38 + row * 128 + 39);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        final previousRow = (index - 1) ~/ columns;
        final previousColumn = previousRow.isEven
            ? (index - 1) % columns
            : columns - 1 - (index - 1) % columns;
        final previous = Offset(
          38 + previousColumn * 178 + 77,
          38 + previousRow * 128 + 39,
        );
        path.quadraticBezierTo(
          (previous.dx + point.dx) / 2,
          previous.dy - (row == previousRow ? 0 : 35),
          point.dx,
          point.dy,
        );
      }
    }
    canvas.drawPath(path, route);
    final shine = Paint()..color = Colors.white.withOpacity(0.035);
    for (var index = 0; index < 22; index++) {
      final x = (index * 137.0) % size.width;
      final y = (index * 83.0) % size.height;
      canvas.drawCircle(Offset(x, y), index % 3 + 1.0, shine);
    }
  }

  @override
  bool shouldRepaint(covariant _RegionRoutePainter oldDelegate) =>
      oldDelegate.nodeCount != nodeCount;
}

class _LocationSheet extends StatefulWidget {
  final Map<String, dynamic> location;
  const _LocationSheet({required this.location});

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  late final Future<Map<String, dynamic>> _location = PokemonService()
      .getResourceByUrl(widget.location['url'] as String);
  Map<String, dynamic>? _selectedArea;
  Map<String, dynamic>? _areaDetails;
  bool _areaLoading = false;

  Future<void> _selectArea(Map<String, dynamic> area) async {
    setState(() {
      _selectedArea = area;
      _areaLoading = true;
      _areaDetails = null;
    });
    try {
      final details = await PokemonService().getResourceByUrl(
        area['url'] as String,
      );
      if (!mounted) return;
      setState(() {
        _areaDetails = details;
        _areaLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _areaLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FutureBuilder<Map<String, dynamic>>(
      future: _location,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          );
        if (!snapshot.hasData)
          return const SizedBox(
            height: 180,
            child: Center(child: Text('No hay datos guardados de este lugar.')),
          );
        final areas = List<Map<String, dynamic>>.from(
          snapshot.data!['areas'] as List? ?? const [],
        );
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
            children: [
              Text(
                _title(
                  (widget.location['name'] as String).replaceAll('-', ' '),
                ),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${areas.length} zonas registradas',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 15),
              if (areas.isEmpty)
                const Text(
                  'Este lugar no tiene zonas de encuentro registradas.',
                ),
              Wrap(
                spacing: 7,
                runSpacing: 4,
                children: areas
                    .map(
                      (area) => ChoiceChip(
                        label: Text(
                          _title((area['name'] as String).replaceAll('-', ' ')),
                        ),
                        selected: _selectedArea?['name'] == area['name'],
                        onSelected: (_) =>
                            _selectArea(Map<String, dynamic>.from(area)),
                        selectedColor: const Color(0xFF26755E),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              if (_areaLoading)
                const Center(child: CircularProgressIndicator()),
              if (_selectedArea != null && !_areaLoading)
                _EncounterList(
                  details: _areaDetails,
                  areaName: _selectedArea!['name'] as String,
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _EncounterList extends StatelessWidget {
  final Map<String, dynamic>? details;
  final String areaName;
  const _EncounterList({required this.details, required this.areaName});

  @override
  Widget build(BuildContext context) {
    final encounters = details?['pokemon_encounters'] as List? ?? const [];
    if (details == null)
      return const Text('No se pudo abrir esta zona sin conexión.');
    if (encounters.isEmpty)
      return Text(
        'No hay encuentros Pokémon registrados en ${_title(areaName.replaceAll('-', ' '))}.',
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Encuentros · ${encounters.length}',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 9),
        for (final encounter in encounters.take(36))
          Builder(
            builder: (context) {
              final pokemon = encounter['pokemon'] as Map;
              final name = pokemon['name'] as String;
              final id = _idFromUrl(pokemon['url'] as String);
              final versions =
                  (encounter['version_details'] as List? ?? const [])
                      .map(
                        (detail) =>
                            (detail['version']?['name'] as String? ?? '')
                                .replaceAll('-', ' '),
                      )
                      .take(3)
                      .join(', ');
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.network(
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.catching_pokemon,
                      color: Colors.white38,
                    ),
                  ),
                ),
                title: Text(
                  _title(name.replaceAll('-', ' ')),
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  versions.isEmpty
                      ? 'Versiones registradas en la API'
                      : versions,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PokemonDetailScreen(pokemonId: int.tryParse(id) ?? 1),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _TrainerArchive extends StatelessWidget {
  const _TrainerArchive();

  static const _trainers = <_TrainerData>[
    _TrainerData(
      name: 'Red',
      title: 'El entrenador silencioso',
      story: 'Tras convertirse en leyenda en Kanto, Red se retira a entrenar en la cima del Monte Plateado. Su equipo reúne a sus compañeros más emblemáticos.',
      game: 'Oro HeartGold / Plata SoulSilver',
      region: 'Kanto · Monte Plateado',
      color: Color(0xFFE15F63),
      team: [
        'pikachu',
        'snorlax',
        'lapras',
        'charizard',
        'blastoise',
        'venusaur',
      ],
    ),
    _TrainerData(
      name: 'Cynthia',
      title: 'Campeona de Sinnoh',
      story: 'Investigadora de mitos y campeona, Cynthia conecta las leyendas de Sinnoh con los desafíos de la Liga.',
      game: 'Pokémon Platino',
      region: 'Sinnoh · Liga Pokémon',
      color: Color(0xFF8E7BE8),
      team: [
        'spiritomb',
        'roserade',
        'gastrodon',
        'lucario',
        'milotic',
        'garchomp',
      ],
    ),
    _TrainerData(
      name: 'Steven',
      title: 'Campeón de Hoenn',
      story: 'Steven es un campeón apasionado por los minerales y las piedras raras; su equipo refleja esa afición y su estilo calculador.',
      game: 'Pokémon Rubí Omega / Zafiro Alfa',
      region: 'Hoenn · Liga Pokémon',
      color: Color(0xFF6AA5D8),
      team: [
        'skarmory',
        'claydol',
        'aggron',
        'cradily',
        'armaldo',
        'metagross',
      ],
    ),
    _TrainerData(
      name: 'Alder',
      title: 'Campeón de Teselia',
      story: 'Alder viaja por Teselia para aprender de otros entrenadores y compartir su experiencia; su Volcarona ocupa un lugar especial en su historia.',
      game: 'Pokémon Negro',
      region: 'Teselia · Liga Pokémon',
      color: Color(0xFFD99A5D),
      team: [
        'accelgor',
        'bouffalant',
        'druddigon',
        'escavalier',
        'vanilluxe',
        'volcarona',
      ],
    ),
    _TrainerData(
      name: 'Diantha',
      title: 'Campeona de Kalos',
      story: 'Actriz y campeona, Diantha busca rivales que la ayuden a crecer mientras equilibra su vida pública con la batalla.',
      game: 'Pokémon X / Y',
      region: 'Kalos · Liga Pokémon',
      color: Color(0xFFD878A6),
      team: [
        'hawlucha',
        'tyrantrum',
        'aurorus',
        'gourgeist',
        'goodra',
        'gardevoir',
      ],
    ),
    _TrainerData(
      name: 'Leon',
      title: 'Campeón de Galar',
      story: 'El campeón invicto de Galar convierte cada combate en un espectáculo y lleva la Copa de Campeones a todo el país.',
      game: 'Pokémon Espada / Escudo',
      region: 'Galar · Estadio de Wyndon',
      color: Color(0xFF7BB780),
      team: [
        'aegislash',
        'dragapult',
        'haxorus',
        'mr-rime',
        'rillaboom',
        'charizard',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(15),
    children: [
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF42336E), Color(0xFF18243B)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Perfiles seleccionados de campeones y rivales destacados. Los equipos pertenecen a los juegos indicados; algunas entregas cambian integrantes o niveles.',
          style: GoogleFonts.outfit(color: Colors.white70, height: 1.35),
        ),
      ),
      const SizedBox(height: 12),
      for (final trainer in _trainers)
        Card(
          color: const Color(0xFF171C2B),
          margin: const EdgeInsets.only(bottom: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
            side: BorderSide(color: trainer.color.withOpacity(0.25)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: trainer.color.withOpacity(0.2),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: trainer.color,
              ),
            ),
            title: Text(
              trainer.name,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '${trainer.title}\n${trainer.region}',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
            ),
            isThreeLine: true,
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
            ),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: const Color(0xFF151B2A),
              builder: (_) => _TrainerSheet(trainer: trainer),
            ),
          ),
        ),
    ],
  );
}

class _TrainerData {
  final String name;
  final String title;
  final String story;
  final String game;
  final String region;
  final Color color;
  final List<String> team;
  const _TrainerData({
    required this.name,
    required this.title,
    required this.story,
    required this.game,
    required this.region,
    required this.color,
    required this.team,
  });
}

class _TrainerSheet extends StatefulWidget {
  final _TrainerData trainer;
  const _TrainerSheet({required this.trainer});

  @override
  State<_TrainerSheet> createState() => _TrainerSheetState();
}

class _TrainerSheetState extends State<_TrainerSheet> {
  late final Future<List<Pokemon>> _pokemon = Future.wait(
    widget.trainer.team.map((name) => PokemonService().getPokemon(name)),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.76,
      child: FutureBuilder<List<Pokemon>>(
        future: _pokemon,
        builder: (context, snapshot) {
          final team = snapshot.data ?? const <Pokemon>[];
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: widget.trainer.color.withOpacity(0.2),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: widget.trainer.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.trainer.name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.trainer.title,
                          style: GoogleFonts.outfit(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.trainer.game,
                style: GoogleFonts.outfit(
                  color: widget.trainer.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                widget.trainer.region,
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 11),
              Text(
                widget.trainer.story,
                style: GoogleFonts.outfit(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 17),
              Text(
                'Equipo de referencia',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (snapshot.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              for (final pokemon in team)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: AnimatedPokemonSprite(
                      animatedUrl:
                          pokemon.sprites.homeArtwork ??
                          pokemon.sprites.officialArtwork,
                      staticUrl: pokemon.sprites.frontDefault,
                      size: 50,
                    ),
                  ),
                  title: Text(
                    pokemon.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    pokemon.types.map((type) => type.name).join(' / '),
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: const Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.white30,
                    size: 17,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PokemonDetailScreen(pokemonId: pokemon.id),
                    ),
                  ),
                ),
              if (snapshot.hasError)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Los datos del equipo no se han consultado antes y requieren conexión.',
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

String _title(String value) => value
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _idFromUrl(String url) {
  final segments =
      Uri.tryParse(url)?.pathSegments
          .where((part) => part.isNotEmpty)
          .toList() ??
      [];
  return segments.isEmpty ? '1' : segments.last;
}
