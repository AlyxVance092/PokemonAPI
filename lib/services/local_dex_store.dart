import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Datos personales que siempre deben estar disponibles sin conexión.
class LocalDexStore {
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static const _caughtKey = 'dex_caught_ids';
  static const _shinyKey = 'dex_shiny_ids';
  static const _teamsKey = 'dex_teams_v1';
  static const _huntKey = 'dex_shiny_hunt_v1';

  Future<Set<int>> getCaughtIds() => _readIds(_caughtKey);

  Future<Set<int>> getShinyIds() => _readIds(_shinyKey);

  Future<bool> toggleCaught(int pokemonId) async {
    final ids = await _readIds(_caughtKey);
    if (!ids.add(pokemonId)) ids.remove(pokemonId);
    await _writeIds(_caughtKey, ids);
    return ids.contains(pokemonId);
  }

  Future<bool> setCaught(int pokemonId, bool isCaught) async {
    final ids = await _readIds(_caughtKey);
    if (isCaught) {
      ids.add(pokemonId);
    } else {
      ids.remove(pokemonId);
    }
    await _writeIds(_caughtKey, ids);
    return isCaught;
  }

  Future<bool> setShiny(int pokemonId, bool isShiny) async {
    final ids = await _readIds(_shinyKey);
    if (isShiny) {
      ids.add(pokemonId);
    } else {
      ids.remove(pokemonId);
    }
    await _writeIds(_shinyKey, ids);
    return isShiny;
  }

  Future<List<Map<String, dynamic>>> getTeams() async {
    final value = await _preferences.getString(_teamsKey);
    if (value == null) return [];
    try {
      return (jsonDecode(value) as List)
          .whereType<Map>()
          .map((team) => Map<String, dynamic>.from(team))
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> saveTeams(List<Map<String, dynamic>> teams) async {
    await _preferences.setString(_teamsKey, jsonEncode(teams));
  }

  Future<Map<String, dynamic>> getHuntSettings() async {
    final value = await _preferences.getString(_huntKey);
    if (value == null) return {'count': 0, 'target': null, 'odds': 4096};
    try {
      return Map<String, dynamic>.from(jsonDecode(value) as Map);
    } on FormatException {
      return {'count': 0, 'target': null, 'odds': 4096};
    }
  }

  Future<void> saveHuntSettings(Map<String, dynamic> settings) async {
    await _preferences.setString(_huntKey, jsonEncode(settings));
  }

  Future<Set<int>> _readIds(String key) async {
    final values = await _preferences.getStringList(key) ?? const <String>[];
    return values.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> _writeIds(String key, Set<int> ids) =>
      _preferences.setStringList(key, ids.map((id) => '$id').toList());
}
