import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pokemon_model.dart';
import '../services/app_language.dart';
import '../screens/pokemon_detail_screen.dart';
import '../services/pokemon_service.dart';

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
      teamLeaderId: 25, // pikachu
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
      teamLeaderId: 444, // garchomp
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
      teamLeaderId: 376, // metagross
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
      teamLeaderId: 637, // volcarona
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
      teamLeaderId: 282, // gardevoir
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
      teamLeaderId: 887, // dragapult
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
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        // Banner superior
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B2D6E), Color(0xFF1E2C4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFD700),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hall de Campeones',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Campeones y rivales de las regiones principales.',
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tarjetas de entrenadores
        for (final trainer in _trainers) ...[
          _TrainerCard(trainer: trainer),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Tarjeta 3D premium de entrenador con efecto holográfico
class _TrainerCard extends StatefulWidget {
  final _TrainerData trainer;
  const _TrainerCard({required this.trainer});

  @override
  State<_TrainerCard> createState() => _TrainerCardState();
}

class _TrainerCardState extends State<_TrainerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _tiltX = 0;
  double _tiltY = 0;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final cx = constraints.maxWidth / 2;
    final cy = constraints.maxHeight / 2;
    setState(() {
      _tiltY = ((details.localPosition.dx - cx) / cx) * 10;
      _tiltX = -((details.localPosition.dy - cy) / cy) * 10;
    });
  }

  void _resetTilt() => setState(() {
    _tiltX = 0;
    _tiltY = 0;
    _isPressed = false;
  });

  void _openSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrainerSheet(trainer: widget.trainer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainer = widget.trainer;
    final leaderId = trainer.teamLeaderId;
    final artUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$leaderId.png';

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: _openSheet,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => _resetTilt(),
          onTapCancel: _resetTilt,
          onPanUpdate: (d) => _onPanUpdate(d, constraints),
          onPanEnd: (_) => _resetTilt(),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_tiltX * math.pi / 180)
              ..rotateY(_tiltY * math.pi / 180)
              ..scale(_isPressed ? 0.97 : 1.0),
            child: Container(
              height: 146,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    trainer.color.withOpacity(0.32),
                    trainer.color.withOpacity(0.08),
                    const Color(0xFF0E1120),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: trainer.color.withOpacity(_isPressed ? 0.7 : 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: trainer.color.withOpacity(0.25),
                    blurRadius: _isPressed ? 28 : 12,
                    spreadRadius: _isPressed ? 2 : 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Efecto holográfico
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.07,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(_tiltY / 15, _tiltX / -15),
                            colors: [Colors.white, Colors.transparent],
                            radius: 0.9,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Pokémon del equipo al fondo (decorativo)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 130,
                    child: Opacity(
                      opacity: 0.85,
                      child: Image.network(
                        artUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.catching_pokemon,
                          size: 80,
                          color: trainer.color.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  // Gradiente para legibilidad del texto
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0E1120).withOpacity(0.0),
                            const Color(0xFF0E1120).withOpacity(0.65),
                          ],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                      ),
                    ),
                  ),
                  // Texto
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 11, 120, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Badge de región
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: trainer.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: trainer.color.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            trainer.region,
                            style: GoogleFonts.outfit(
                              color: trainer.color,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          trainer.name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          trainer.title,
                          style: GoogleFonts.outfit(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Mini sprites del equipo
                        SizedBox(
                          height: 24,
                          child: Row(
                            children: [
                              for (
                                var i = 0;
                                i < math.min(trainer.team.length, 6);
                                i++
                              )
                                _MiniTeamIcon(
                                  pokemonName: trainer.team[i],
                                  color: trainer.color,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Flecha
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: trainer.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: trainer.color.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: trainer.color,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mini ícono de Pokémon para la fila del equipo en la tarjeta de entrenador
class _MiniTeamIcon extends StatelessWidget {
  final String pokemonName;
  final Color color;
  const _MiniTeamIcon({required this.pokemonName, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: FutureBuilder<String>(
          future: _resolveId(pokemonName),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Icon(
                Icons.catching_pokemon_rounded,
                size: 12,
                color: color.withOpacity(0.5),
              );
            }
            return Image.network(
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${snapshot.data}.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.catching_pokemon_rounded,
                size: 12,
                color: color.withOpacity(0.5),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<String> _resolveId(String name) async {
    try {
      final pokemon = await PokemonService().getPokemon(name);
      return '${pokemon.id}';
    } catch (_) {
      return name;
    }
  }
}

class _TrainerData {
  final String name;
  final String title;
  final String story;
  final String game;
  final String region;
  final Color color;
  final int teamLeaderId;
  final List<String> team;
  const _TrainerData({
    required this.name,
    required this.title,
    required this.story,
    required this.game,
    required this.region,
    required this.color,
    required this.teamLeaderId,
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
  Widget build(BuildContext context) {
    final trainer = widget.trainer;
    final leaderId = trainer.teamLeaderId;
    final artUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$leaderId.png';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: trainer.color.withOpacity(0.25), width: 1.5),
      ),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.82,
          child: FutureBuilder<List<Pokemon>>(
            future: _pokemon,
            builder: (context, snapshot) {
              final team = snapshot.data ?? const <Pokemon>[];
              return CustomScrollView(
                slivers: [
                  // Cabecera con imagen del Pokémon líder
                  SliverToBoxAdapter(
                    child: Container(
                      height: 200,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            trainer.color.withOpacity(0.45),
                            trainer.color.withOpacity(0.08),
                            const Color(0xFF111827),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Pokémon líder grande
                          Positioned(
                            right: 0,
                            top: -10,
                            bottom: 0,
                            width: 200,
                            child: Image.network(
                              artUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.catching_pokemon,
                                size: 100,
                                color: trainer.color.withOpacity(0.3),
                              ),
                            ),
                          ),
                          // Gradiente izquierda
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF111827).withOpacity(0.0),
                                    const Color(0xFF111827).withOpacity(0.6),
                                  ],
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                ),
                              ),
                            ),
                          ),
                          // Drag handle
                          Positioned(
                            top: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          // Texto del entrenador
                          Positioned(
                            left: 20,
                            bottom: 20,
                            right: 180,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: trainer.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: trainer.color.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    trainer.game,
                                    style: GoogleFonts.outfit(
                                      color: trainer.color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  trainer.name,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  trainer.title,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 16),
                        // Historia
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_stories_rounded,
                                    color: trainer.color,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    'Historia',
                                    style: GoogleFonts.outfit(
                                      color: trainer.color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                trainer.story,
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Equipo de referencia
                        Row(
                          children: [
                            Icon(
                              Icons.groups_2_rounded,
                              color: trainer.color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Equipo de referencia',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.connectionState != ConnectionState.done)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        for (final pokemon in team)
                          _TeamPokemonTile(
                            pokemon: pokemon,
                            accentColor: trainer.color,
                          ),
                        if (snapshot.hasError)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Los datos del equipo requieren conexión.',
                              style: GoogleFonts.outfit(color: Colors.white54),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Tile premium para cada Pokémon del equipo del entrenador
class _TeamPokemonTile extends StatelessWidget {
  final Pokemon pokemon;
  final Color accentColor;
  const _TeamPokemonTile({required this.pokemon, required this.accentColor});

  static const Map<String, Color> _typeColors = {
    'fire': Color(0xFFFF6B35),
    'water': Color(0xFF4FC3F7),
    'grass': Color(0xFF66BB6A),
    'electric': Color(0xFFFFD54F),
    'psychic': Color(0xFFEC407A),
    'ice': Color(0xFF80DEEA),
    'dragon': Color(0xFF7C4DFF),
    'dark': Color(0xFF5D4037),
    'fairy': Color(0xFFF48FB1),
    'fighting': Color(0xFFFF7043),
    'flying': Color(0xFF90CAF9),
    'poison': Color(0xFFAB47BC),
    'ground': Color(0xFFBCAAA4),
    'rock': Color(0xFF8D6E63),
    'bug': Color(0xFF9CCC65),
    'ghost': Color(0xFF7E57C2),
    'steel': Color(0xFF78909C),
    'normal': Color(0xFFBDBDBD),
  };

  @override
  Widget build(BuildContext context) {
    final typeColor = pokemon.types.isNotEmpty
        ? (_typeColors[pokemon.types.first.name] ?? accentColor)
        : accentColor;
    final imageUrl =
        pokemon.sprites.homeArtwork ??
        pokemon.sprites.officialArtwork ??
        pokemon.sprites.frontDefault;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [typeColor.withOpacity(0.12), Colors.white.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withOpacity(0.22)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PokemonDetailScreen(pokemonId: pokemon.id),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Imagen
                SizedBox(
                  width: 58,
                  height: 58,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.catching_pokemon,
                            color: typeColor.withOpacity(0.5),
                            size: 36,
                          ),
                        )
                      : Icon(
                          Icons.catching_pokemon,
                          color: typeColor.withOpacity(0.5),
                          size: 36,
                        ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${pokemon.id.toString().padLeft(3, '0')}',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _title(pokemon.name.replaceAll('-', ' ')),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 5,
                        children: pokemon.types
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (_typeColors[t.name] ?? accentColor)
                                      .withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  t.name,
                                  style: GoogleFonts.outfit(
                                    color: _typeColors[t.name] ?? accentColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  color: typeColor.withOpacity(0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
