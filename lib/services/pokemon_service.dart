import 'package:dio/dio.dart';
import '../models/pokemon_model.dart';

/// Servicio que realiza peticiones de red usando el paquete Dio
/// para obtener datos de la PokeAPI
class PokemonService {
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
  Future<Pokemon> getPokemon(String idOrName) async {
    try {
      // http.get equivalente con Dio: _dio.get(...)
      final Response response = await _dio.get('pokemon/$idOrName');

      // Convierte la respuesta JSON en un objeto Pokemon personalizado
      return Pokemon.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Pokémon "$idOrName" no encontrado');
      }
      throw Exception('Error de red: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtiene una lista de Pokémon (para el explorador)
  Future<List<Map<String, dynamic>>> getPokemonList({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final Response response = await _dio.get(
        'pokemon',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final results = response.data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception('Error al obtener lista: ${e.message}');
    }
  }
}
