import 'package:flutter/material.dart';

import 'services/app_language.dart';
import 'screens/app_shell.dart';

/// Punto de entrada principal de la aplicación PokéDex
/// Práctica: Consumo de API con Dart/Flutter usando el paquete Dio
/// API utilizada: https://pokeapi.co/api/v2/pokemon/1/
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache
    ..maximumSize = 96
    ..maximumSizeBytes = 16 * 1024 * 1024;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLanguageScope(
      notifier: AppLanguageController.instance,
      child: MaterialApp(
        title: 'PokéDex - PokeAPI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF6B6B),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const AppShell(),
      ),
    );
  }
}
