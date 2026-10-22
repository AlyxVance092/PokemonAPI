import 'package:flutter/material.dart';

import '../services/app_language.dart';
import '../widgets/pokedex_intro.dart';
import '../widgets/pokeball_painter.dart';
import 'collection_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'tools_hub_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _menuOpen = false;
  final AppLanguageController _language = AppLanguageController.instance;
  final List<Widget?> _screens = [const HomeScreen(), null, null, null];
  late final AnimationController _menuAnimationController;

  @override
  void initState() {
    super.initState();
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 520),
      vsync: this,
    )..addStatusListener(_onMenuAnimationStatus);
    _language.addListener(_onLanguageChanged);
    _language.load();
  }

  void _onLanguageChanged() => setState(() {});

  void _onMenuAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !_menuOpen && mounted) {
      setState(() {});
    }
  }

  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
    if (_menuOpen) {
      _menuAnimationController.forward();
    } else {
      _menuAnimationController.reverse();
    }
  }

  void _closeMenu() {
    if (!_menuOpen) return;
    setState(() => _menuOpen = false);
    _menuAnimationController.reverse();
  }

  void _onPokeballPressed() {
    if (_menuOpen) {
      _selectSection(0);
    } else {
      _toggleMenu();
    }
  }

  void _selectSection(int index) {
    setState(() {
      _selectedIndex = index;
      _screens[index] ??= switch (index) {
        1 => const ToolsHubScreen(),
        2 => const CollectionScreen(),
        3 => const ExploreScreen(),
        _ => const HomeScreen(),
      };
      _menuOpen = false;
    });
    _menuAnimationController.reverse();
  }

  @override
  void dispose() {
    _language.removeListener(_onLanguageChanged);
    _menuAnimationController
      ..removeStatusListener(_onMenuAnimationStatus)
      ..dispose();
    super.dispose();
  }

  Widget _radialMenuAction({
    required int index,
    required int order,
    required double centerX,
    required double centerFromBottom,
    required double horizontalOffset,
    required double rise,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    const actionWidth = 88.0;
    const actionHeight = 76.0;
    final animation = CurvedAnimation(
      parent: _menuAnimationController,
      curve: Interval(
        order * 0.13,
        0.62 + order * 0.18,
        curve: Curves.easeOutBack,
      ),
    );

    return Positioned(
      left: centerX + horizontalOffset - actionWidth / 2,
      bottom: centerFromBottom + rise - actionHeight + 24,
      child: AnimatedBuilder(
        animation: _menuAnimationController,
        builder: (context, child) {
          final progress = animation.value.clamp(0.0, 1.0).toDouble();
          return IgnorePointer(
            ignoring: !_menuOpen || progress < 0.78,
            child: Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(
                  -horizontalOffset * (1 - progress),
                  rise * (1 - progress),
                ),
                child: Transform.scale(
                  scale: 0.72 + progress * 0.28,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: SizedBox(
          width: actionWidth,
          height: actionHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'section-menu-$index',
                tooltip: label,
                onPressed: () => _selectSection(index),
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 5,
                child: Icon(icon, size: 19),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xE61A2030),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.42)),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pokeballButton() => FloatingActionButton(
    heroTag: 'pokeball-section-menu',
    tooltip: _menuOpen ? 'Ir a Pokédex' : 'Abrir menú',
    onPressed: _onPokeballPressed,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    elevation: 0,
    child: RotationTransition(
      turns: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _menuAnimationController,
          curve: Curves.easeInOutBack,
        ),
      ),
      child: const SizedBox(
        width: 48,
        height: 48,
        child: CustomPaint(painter: PokeballPainter()),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final showActions = _menuOpen || _menuAnimationController.isAnimating;

    final appScaffold = Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens
                .map((screen) => screen ?? const SizedBox.shrink())
                .toList(),
          ),
          if (showActions && _menuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                behavior: HitTestBehavior.opaque,
                child: ColoredBox(color: Colors.black.withOpacity(0.28)),
              ),
            ),
          Positioned.fill(
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final centerX = constraints.maxWidth / 2;
                  const bottom = 12.0;
                  const buttonCenterFromBottom = bottom + 28;
                  final showActions =
                      _menuOpen || _menuAnimationController.isAnimating;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (showActions) ...[
                        _radialMenuAction(
                          index: 1,
                          order: 0,
                          centerX: centerX,
                          centerFromBottom: buttonCenterFromBottom,
                          horizontalOffset: -86,
                          rise: 78,
                          label: _language.text('nav_tools'),
                          icon: Icons.auto_awesome_mosaic_rounded,
                          color: const Color(0xFF6488FF),
                        ),
                        _radialMenuAction(
                          index: 2,
                          order: 1,
                          centerX: centerX,
                          centerFromBottom: buttonCenterFromBottom,
                          horizontalOffset: 0,
                          rise: 132,
                          label: _language.text('nav_collection'),
                          icon: Icons.collections_bookmark_rounded,
                          color: const Color(0xFFE9579D),
                        ),
                        _radialMenuAction(
                          index: 3,
                          order: 2,
                          centerX: centerX,
                          centerFromBottom: buttonCenterFromBottom,
                          horizontalOffset: 86,
                          rise: 78,
                          label: _language.text('nav_explore'),
                          icon: Icons.public_rounded,
                          color: const Color(0xFF35C9A5),
                        ),
                      ],
                      Positioned(
                        left: centerX - 28,
                        bottom: bottom,
                        child: _pokeballButton(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );

    return PokedexIntro(child: appScaffold);
  }
}
