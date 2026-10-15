// Modelo de datos para representar un Pokémon
// Convierte la respuesta JSON de la PokeAPI en un objeto Dart

class Pokemon {
  final int id;
  final String name;
  final int height;
  final int weight;
  final int baseExperience;
  final List<PokemonType> types;
  final List<PokemonStat> stats;
  final List<PokemonAbility> abilities;
  final PokemonSprites sprites;

  Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.baseExperience,
    required this.types,
    required this.stats,
    required this.abilities,
    required this.sprites,
  });

  /// Factory constructor: convierte un Map (JSON) en un objeto Pokemon
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    return Pokemon(
      id: json['id'] as int,
      name: (json['name'] as String).toUpperCase(),
      height: json['height'] as int,
      weight: json['weight'] as int,
      baseExperience: json['base_experience'] as int? ?? 0,
      types: (json['types'] as List)
          .map((t) => PokemonType.fromJson(t as Map<String, dynamic>))
          .toList(),
      stats: (json['stats'] as List)
          .map((s) => PokemonStat.fromJson(s as Map<String, dynamic>))
          .toList(),
      abilities: (json['abilities'] as List)
          .map((a) => PokemonAbility.fromJson(a as Map<String, dynamic>))
          .toList(),
      sprites: PokemonSprites.fromJson(
          json['sprites'] as Map<String, dynamic>),
    );
  }
}

class PokemonType {
  final String name;

  PokemonType({required this.name});

  factory PokemonType.fromJson(Map<String, dynamic> json) {
    return PokemonType(
      name: json['type']['name'] as String,
    );
  }
}

class PokemonStat {
  final String name;
  final int baseStat;

  PokemonStat({required this.name, required this.baseStat});

  factory PokemonStat.fromJson(Map<String, dynamic> json) {
    return PokemonStat(
      name: json['stat']['name'] as String,
      baseStat: json['base_stat'] as int,
    );
  }
}

class PokemonAbility {
  final String name;
  final bool isHidden;

  PokemonAbility({required this.name, required this.isHidden});

  factory PokemonAbility.fromJson(Map<String, dynamic> json) {
    return PokemonAbility(
      name: json['ability']['name'] as String,
      isHidden: json['is_hidden'] as bool,
    );
  }
}

class PokemonSprites {
  final String? frontDefault;
  final String? officialArtwork;

  PokemonSprites({this.frontDefault, this.officialArtwork});

  factory PokemonSprites.fromJson(Map<String, dynamic> json) {
    final other = json['other'] as Map<String, dynamic>?;
    final officialArt = other?['official-artwork'] as Map<String, dynamic>?;

    return PokemonSprites(
      frontDefault: json['front_default'] as String?,
      officialArtwork: officialArt?['front_default'] as String?,
    );
  }
}
