import 'package:flutter/material.dart';

import '../services/app_language.dart';
import 'collection_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'tools_hub_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final AppLanguageController _language = AppLanguageController.instance;
  final List<Widget?> _screens = [const HomeScreen(), null, null, null];

  @override
  void initState() {
    super.initState();
    _language.addListener(_onLanguageChanged);
    _language.load();
  }

  void _onLanguageChanged() => setState(() {});

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      _screens[index] ??= switch (index) {
        1 => const ToolsHubScreen(),
        2 => const CollectionScreen(),
        3 => const ExploreScreen(),
        _ => const HomeScreen(),
      };
    });
  }

  @override
  void dispose() {
    _language.removeListener(_onLanguageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens
            .map((screen) => screen ?? const SizedBox.shrink())
            .toList(),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: const Color(0xFF111827),
        indicatorColor: const Color(0xFF8B6CFF).withOpacity(0.25),
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.catching_pokemon_outlined),
            selectedIcon: const Icon(Icons.catching_pokemon),
            label: _language.text('nav_dex'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_mosaic_outlined),
            selectedIcon: const Icon(Icons.auto_awesome_mosaic),
            label: _language.text('nav_tools'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.collections_bookmark_outlined),
            selectedIcon: const Icon(Icons.collections_bookmark),
            label: _language.text('nav_collection'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.public_outlined),
            selectedIcon: const Icon(Icons.public),
            label: _language.text('nav_explore'),
          ),
        ],
      ),
    );
  }
}
