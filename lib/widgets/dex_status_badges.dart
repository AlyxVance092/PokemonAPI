import 'package:flutter/material.dart';

import '../services/local_dex_store.dart';

/// Badges de estado (capturado / shiny) que se actualizan en tiempo real
/// escuchando directamente al [LocalDexStore].
class DexStatusBadges extends StatefulWidget {
  final int pokemonId;
  // heroTag kept for API compatibility but no longer used internally
  final String heroTag;

  const DexStatusBadges({
    super.key,
    required this.pokemonId,
    required this.heroTag,
  });

  @override
  State<DexStatusBadges> createState() => _DexStatusBadgesState();
}

class _DexStatusBadgesState extends State<DexStatusBadges> {
  final LocalDexStore _store = LocalDexStore();
  Set<int> _caught = const {};
  Set<int> _shinies = const {};

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _store.getCaughtIds(),
      _store.getShinyIds(),
    ]);
    if (!mounted) return;
    setState(() {
      _caught = results[0];
      _shinies = results[1];
    });
  }

  void _onStoreChanged() => _load();

  @override
  void didUpdateWidget(covariant DexStatusBadges oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pokemonId != widget.pokemonId) _load();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCaught = _caught.contains(widget.pokemonId);
    final isShiny = _shinies.contains(widget.pokemonId);
    if (!isCaught && !isShiny) return const SizedBox.shrink();

    return Positioned(
      left: 10,
      top: 10,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isShiny)
            _Badge(
              tooltip: 'Shiny guardado',
              background: const Color(0xFFFFD166),
              icon: const Icon(
                Icons.auto_awesome,
                size: 13,
                color: Colors.black87,
              ),
            ),
          if (isCaught)
            _Badge(
              tooltip: 'Capturado',
              background: const Color(0xFF78D6A5),
              icon: const Icon(
                Icons.catching_pokemon,
                size: 13,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String tooltip;
  final Color background;
  final Widget icon;

  const _Badge({
    required this.tooltip,
    required this.background,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: background.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: icon,
        ),
      ),
    );
  }
}
