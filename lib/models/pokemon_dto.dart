class PokemonStatsDTO {
  final int hp;
  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;

  PokemonStatsDTO({
    required this.hp,
    required this.attack,
    required this.defense,
    required this.specialAttack,
    required this.specialDefense,
    required this.speed,
  });
}

class PokemonDTO {
  final int id;
  final String name;
  final List<String> types;
  final String imageUrl;
  final String? description;
  final int height; // en decímetros
  final int weight; // en hectogramos
  final PokemonStatsDTO? stats;

  PokemonDTO({
    required this.id,
    required this.name,
    required this.types,
    required this.imageUrl,
    this.description,
    required this.height,
    required this.weight,
    this.stats,
  });

  factory PokemonDTO.fromJson(Map<String, dynamic> json) {
    PokemonStatsDTO? stats;
    if (json['pokemon_v2_pokemonstats'] != null) {
      final statsList = json['pokemon_v2_pokemonstats'] as List;
      final statsMap = <int, int>{};
      for (var stat in statsList) {
        statsMap[stat['stat_id']] = stat['base_stat'];
      }
      stats = PokemonStatsDTO(
        hp: statsMap[1] ?? 0,
        attack: statsMap[2] ?? 0,
        defense: statsMap[3] ?? 0,
        specialAttack: statsMap[4] ?? 0,
        specialDefense: statsMap[5] ?? 0,
        speed: statsMap[6] ?? 0,
      );
    }

    return PokemonDTO(
      id: json['id'],
      name: json['name'],
      types: (json['pokemon_v2_pokemontypes'] as List)
          .map((type) => type['pokemon_v2_type']['name'] as String)
          .toList(),
      imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${json['id']}.png',
      description: null, // Se cargará por separado
      height: json['height'] ?? 0,
      weight: json['weight'] ?? 0,
      stats: stats,
    );
  }

  // Convertir altura de decímetros a metros
  String get heightInMeters {
    return '${(height / 10).toStringAsFixed(1)} m';
  }

  // Convertir altura a pies y pulgadas
  String get heightInFeet {
    double totalInches = height * 3.937; // decímetros a pulgadas
    int feet = totalInches ~/ 12;
    int inches = (totalInches % 12).round();
    return '$feet\'${inches.toString().padLeft(2, '0')}"';
  }

  // Convertir peso de hectogramos a kilogramos
  String get weightInKg {
    return '${(weight / 10).toStringAsFixed(1)} kg';
  }

  // Convertir peso a libras
  String get weightInLbs {
    return '${(weight * 0.220462).toStringAsFixed(1)} lbs';
  }

  String get formattedId {
    return '#${id.toString().padLeft(3, '0')}';
  }

  String get capitalizedName {
    return name[0].toUpperCase() + name.substring(1);
  }
}
