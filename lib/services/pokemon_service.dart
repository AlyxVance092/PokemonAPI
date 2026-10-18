import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pokemon_model.dart';

/// Servicio que realiza peticiones de red usando el paquete Dio
/// para obtener datos de la PokeAPI
class PokemonService {
  static const _cacheIndexKey = 'pokeapi_offline_cache_index_v1';
  static const _pokemonSnapshotIndexKey = 'pokemon_offline_snapshot_index_v1';
  static const _maxCachedResponses = 60;
  static const _maxPokemonSnapshots = 80;
  static const _maxPokemonMemoryCache = 36;
  static const _maxPendingPokemonSnapshotWrites = 6;
  static const _apiCacheMaxAge = Duration(days: 7);
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static Future<void> _cacheWriteQueue = Future<void>.value();
  static Future<void> _pokemonSnapshotWriteQueue = Future<void>.value();
  static int _pendingPokemonSnapshotWrites = 0;
  static final Map<String, Pokemon> _pokemonMemoryCache = {};
  static final Map<String, Future<Pokemon>> _pokemonLoads = {};
  static final Set<String> _backgroundCacheRefreshes = {};

  // Instancia de Dio configurada con la URL base
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://pokeapi.co/api/v2/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Realiza una petición GET para obtener un Pokémon por su ID o nombre.
  /// Usa Future para manejo asíncrono de la respuesta.
  Future<Pokemon> getPokemon(String idOrName, {bool includeMoves = false}) {
    final key = idOrName.trim().toLowerCase();
    final cached = _pokemonMemoryCache[key];
    if (cached != null && (!includeMoves || cached.movesLoaded)) {
      return Future.value(cached);
    }

    final requestKey = includeMoves ? '$key|with-moves' : key;
    final pending = _pokemonLoads[requestKey];
    if (pending != null) return pending;

    late final Future<Pokemon> request;
    request = _loadPokemon(key, includeMoves: includeMoves).whenComplete(() {
      _pokemonLoads.remove(requestKey);
    });
    _pokemonLoads[requestKey] = request;
    return request;
  }

  Future<Pokemon> _loadPokemon(
    String idOrName, {
    required bool includeMoves,
  }) async {
    final snapshot = await _readPokemonSnapshot(idOrName);
    if (snapshot != null) {
      try {
        final pokemon = Pokemon.fromJson(snapshot, includeMoves: includeMoves);
        _rememberPokemon(idOrName, pokemon);
        return pokemon;
      } catch (_) {
        // A malformed local snapshot is replaced with the API response.
      }
    }

    try {
      final data = await getResource('pokemon/${idOrName.toLowerCase()}');
      final pokemon = Pokemon.fromJson(data, includeMoves: includeMoves);
      _rememberPokemon(idOrName, pokemon);
      unawaited(_savePokemonSnapshot(data));
      return pokemon;
    } on DioException catch (e) {
      final snapshot = await _readPokemonSnapshot(idOrName.toLowerCase());
      if (snapshot != null) {
        return Pokemon.fromJson(snapshot, includeMoves: includeMoves);
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Pokémon "$idOrName" no encontrado');
      }
      throw Exception('Error de red: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Lee la rareza de la especie para resaltar legendarios y míticos.
  Future<Map<String, bool>> getPokemonRarity(int pokemonId) async {
    try {
      final data = await getResource('pokemon-species/$pokemonId');
      return {
        'legendary': data['is_legendary'] as bool? ?? false,
        'mythical': data['is_mythical'] as bool? ?? false,
      };
    } on DioException catch (e) {
      throw Exception('Error al obtener la rareza: ${e.message}');
    }
  }

  /// Obtiene una lista de Pokémon (para el explorador)
  Future<List<Map<String, dynamic>>> getPokemonList({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final data = await _requestData(
        'pokemon',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final results = data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception('Error al obtener lista: ${e.message}');
    }
  }

  /// Obtiene un recurso de la API y conserva una copia local para usarla sin red.
  Future<Map<String, dynamic>> getResource(String path) async {
    final data = await _requestData(path);
    return Map<String, dynamic>.from(data);
  }

  Future<List<dynamic>> getResourceList(
    String path, {
    int? limit,
    int offset = 0,
  }) async {
    final data = await _requestData(
      path,
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset > 0) 'offset': offset,
      },
    );
    return List<dynamic>.from(data['results'] as List);
  }

  Future<Map<String, dynamic>> getResourceByUrl(String url) async {
    final uri = Uri.parse(url);
    final versionIndex = uri.pathSegments.indexOf('v2');
    final path = versionIndex >= 0
        ? uri.pathSegments.skip(versionIndex + 1).join('/')
        : uri.pathSegments.join('/');
    return getResource(path);
  }

  Future<List<Map<String, dynamic>>> getPokemonEncounters(int pokemonId) async {
    try {
      final data = await _requestData('pokemon/$pokemonId/encounters');
      return List<Map<String, dynamic>>.from(data as List);
    } on DioException catch (e) {
      throw Exception('Error al obtener ubicaciones: ${e.message}');
    }
  }

  Future<dynamic> _requestData(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final query = queryParameters ?? const <String, dynamic>{};
    final descriptor = jsonEncode({'path': path, 'query': query});
    final cacheKey =
        'pokeapi_cache_${base64Url.encode(utf8.encode(descriptor)).replaceAll('=', '')}';
    final cached = await _readCachedResponse(cacheKey);
    if (cached != null && !cached.isExpired) {
      if (cached.isLegacy) {
        _refreshCacheInBackground(cacheKey, path, queryParameters);
      }
      return cached.data;
    }

    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      if (!RegExp(r'^pokemon/[^/]+$').hasMatch(path)) {
        unawaited(_cacheResponse(cacheKey, response.data));
      }
      return response.data;
    } catch (_) {
      if (cached != null) return cached.data;
      rethrow;
    }
  }

  Future<_CachedApiResponse?> _readCachedResponse(String key) async {
    final encoded = await _preferences.getString(key);
    if (encoded == null) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map && decoded['__dex_cache_version'] == 1) {
        final savedAt = decoded['saved_at'] as int?;
        if (savedAt == null) {
          await _preferences.remove(key);
          return null;
        }
        final isExpired =
            DateTime.now().millisecondsSinceEpoch - savedAt >
            _apiCacheMaxAge.inMilliseconds;
        return _CachedApiResponse(decoded['data'], isExpired: isExpired);
      }

      // Read older entries immediately and refresh them quietly in the background.
      return _CachedApiResponse(decoded, isLegacy: true);
    } on FormatException {
      await _preferences.remove(key);
      return null;
    }
  }

  void _refreshCacheInBackground(
    String cacheKey,
    String path,
    Map<String, dynamic>? queryParameters,
  ) {
    if (!_backgroundCacheRefreshes.add(cacheKey)) return;
    unawaited(() async {
      try {
        final response = await _dio.get(path, queryParameters: queryParameters);
        await _cacheResponse(cacheKey, response.data);
      } catch (_) {
        // Keep the previous offline response if the background refresh fails.
      } finally {
        _backgroundCacheRefreshes.remove(cacheKey);
      }
    }());
  }

  static void _rememberPokemon(String key, Pokemon pokemon) {
    for (final alias in {key, '${pokemon.id}', pokemon.name.toLowerCase()}) {
      if (!pokemon.movesLoaded &&
          _pokemonMemoryCache[alias]?.movesLoaded == true) {
        continue;
      }
      _pokemonMemoryCache.remove(alias);
      _pokemonMemoryCache[alias] = pokemon;
    }
    while (_pokemonMemoryCache.length > _maxPokemonMemoryCache * 3) {
      _pokemonMemoryCache.remove(_pokemonMemoryCache.keys.first);
    }
  }

  Future<void> _cacheResponse(String key, dynamic value) async {
    try {
      final encoded = jsonEncode({
        '__dex_cache_version': 1,
        'saved_at': DateTime.now().millisecondsSinceEpoch,
        'data': value,
      });
      if (encoded.length > 250000) return;
      _cacheWriteQueue = _cacheWriteQueue.then((_) async {
        try {
          await _preferences.setString(key, encoded);
          final keys = await _preferences.getStringList(_cacheIndexKey) ?? [];
          keys.remove(key);
          keys.add(key);
          while (keys.length > _maxCachedResponses) {
            await _preferences.remove(keys.removeAt(0));
          }
          await _preferences.setStringList(_cacheIndexKey, keys);
        } catch (_) {
          // A cache write failure must not block subsequent requests.
        }
      });
      await _cacheWriteQueue;
    } catch (_) {
      // Offline storage is best-effort; a successful API response stays usable.
    }
  }

  Future<void> _savePokemonSnapshot(Map<String, dynamic> value) async {
    // Scroll paging can fetch many full API payloads quickly. Keep a strict
    // bound on queued platform writes so those JSON strings cannot pile up.
    if (_pendingPokemonSnapshotWrites >= _maxPendingPokemonSnapshotWrites) {
      return;
    }
    _pendingPokemonSnapshotWrites++;

    final id = '${value['id']}';
    final name = value['name'] as String?;
    try {
      final snapshot = Map<String, dynamic>.from(value);
      final moves = snapshot['moves'];
      if (moves is List) {
        // Detail screens need only move names and URLs. The API's nested
        // version-group data makes every snapshot much larger than necessary.
        snapshot['moves'] = moves
            .map((entry) {
              final move = (entry as Map<String, dynamic>)['move'];
              if (move is! Map<String, dynamic>)
                return const <String, dynamic>{};
              return <String, dynamic>{
                'move': <String, dynamic>{
                  'name': move['name'],
                  'url': move['url'],
                },
              };
            })
            .where((entry) => entry.isNotEmpty)
            .toList();
      }
      final encodedValue = jsonEncode(snapshot);
      final write = _pokemonSnapshotWriteQueue.then((_) async {
        try {
          await _preferences.setString('pokemon_data_$id', encodedValue);
          await _preferences.setString('pokemon_alias_$id', id);
          if (name != null)
            await _preferences.setString('pokemon_alias_$name', id);
          final entries =
              await _preferences.getStringList(_pokemonSnapshotIndexKey) ?? [];
          entries.removeWhere((entry) => entry.startsWith('$id|'));
          entries.add('$id|${name ?? id}');
          while (entries.length > _maxPokemonSnapshots) {
            final old = entries.removeAt(0).split('|');
            if (old.isNotEmpty) {
              await _preferences.remove('pokemon_data_${old.first}');
              await _preferences.remove('pokemon_alias_${old.first}');
            }
            if (old.length > 1)
              await _preferences.remove('pokemon_alias_${old[1]}');
          }
          await _preferences.setStringList(_pokemonSnapshotIndexKey, entries);
        } catch (_) {
          // A preference write failure must not discard the loaded Pokémon.
        }
      });
      _pokemonSnapshotWriteQueue = write;
      await write;
    } catch (_) {
      // A cache failure must not discard the loaded Pokémon.
    } finally {
      _pendingPokemonSnapshotWrites--;
    }
  }

  Future<Map<String, dynamic>?> _readPokemonSnapshot(String alias) async {
    try {
      final id = await _preferences.getString('pokemon_alias_$alias');
      if (id == null) return null;
      final value = await _preferences.getString('pokemon_data_$id');
      if (value == null) return null;
      return Map<String, dynamic>.from(jsonDecode(value) as Map);
    } catch (_) {
      return null;
    }
  }
}

class _CachedApiResponse {
  final dynamic data;
  final bool isExpired;
  final bool isLegacy;

  const _CachedApiResponse(
    this.data, {
    this.isExpired = false,
    this.isLegacy = false,
  });
}
