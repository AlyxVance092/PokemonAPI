import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

/// Punto de entrada principal de la aplicación PokéDex
/// Práctica: Consumo de API con Dart/Flutter usando el paquete Dio
/// API utilizada: https://pokeapi.co/api/v2/pokemon/1/
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokéDex - PokeAPI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B6B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
