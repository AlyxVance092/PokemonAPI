// Modelo de datos para representar un Pokémon
// Convierte la respuesta JSON de la PokeAPI en un objeto Dart

class Pokemon {
  final int id;
  final int speciesId;
  final String name;
  final int height;
  final int weight;
  final int baseExperience;
  final List<PokemonType> types;
  final List<PokemonStat> stats;
  final List<PokemonAbility> abilities;
  final List<PokemonMove> moves;
  final bool movesLoaded;
  final PokemonSprites sprites;

  Pokemon({
    required this.id,
    required this.speciesId,
    required this.name,
    required this.height,
    required this.weight,
    required this.baseExperience,
    required this.types,
    required this.stats,
    required this.abilities,
    this.moves = const [],
    this.movesLoaded = false,
    required this.sprites,
  });

  /// Factory constructor: convierte un Map (JSON) en un objeto Pokemon
  factory Pokemon.fromJson(
    Map<String, dynamic> json, {
    bool includeMoves = false,
  }) {
    final species = json['species'] as Map<String, dynamic>?;
    final speciesUrl = species?['url'] as String?;
    final speciesId = speciesUrl == null
        ? json['id'] as int
        : int.parse(
            Uri.parse(speciesUrl).pathSegments
                .where((segment) => segment.isNotEmpty)
                .last,
          );

    return Pokemon(
      id: json['id'] as int,
      speciesId: speciesId,
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
      moves: includeMoves
          ? (json['moves'] as List? ?? const [])
                .map(
                  (move) => PokemonMove.fromJson(move as Map<String, dynamic>),
                )
                .toList()
          : const [],
      movesLoaded: includeMoves,
      sprites: PokemonSprites.fromJson(json['sprites'] as Map<String, dynamic>),
    );
  }
}

class PokemonType {
  final String name;

  PokemonType({required this.name});

  factory PokemonType.fromJson(Map<String, dynamic> json) {
    return PokemonType(name: json['type']['name'] as String);
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

class PokemonMove {
  final String name;
  final String url;

  PokemonMove({required this.name, required this.url});

  factory PokemonMove.fromJson(Map<String, dynamic> json) {
    final move = json['move'] as Map<String, dynamic>;
    return PokemonMove(
      name: move['name'] as String,
      url: move['url'] as String,
    );
  }
}

class PokemonSprites {
  final String? frontDefault;
  final String? frontShiny;
  final String? officialArtwork;
  final String? officialArtworkShiny;
  final String? homeArtwork;
  final String? homeArtworkShiny;
  final String? animated;
  final String? animatedShiny;

  PokemonSprites({
    this.frontDefault,
    this.frontShiny,
    this.officialArtwork,
    this.officialArtworkShiny,
    this.homeArtwork,
    this.homeArtworkShiny,
    this.animated,
    this.animatedShiny,
  });

  factory PokemonSprites.fromJson(Map<String, dynamic> json) {
    final other = json['other'] as Map<String, dynamic>?;
    final officialArt = other?['official-artwork'] as Map<String, dynamic>?;
    final home = other?['home'] as Map<String, dynamic>?;
    final showDown = other?['showdown'] as Map<String, dynamic>?;

    return PokemonSprites(
      frontDefault: json['front_default'] as String?,
      frontShiny: json['front_shiny'] as String?,
      officialArtwork: officialArt?['front_default'] as String?,
      officialArtworkShiny: officialArt?['front_shiny'] as String?,
      homeArtwork: home?['front_default'] as String?,
      homeArtworkShiny: home?['front_shiny'] as String?,
      animated: showDown?['front_default'] as String?,
      animatedShiny: showDown?['front_shiny'] as String?,
    );
  }
}
