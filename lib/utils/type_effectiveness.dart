/// Type effectiveness chart for Pokemon type matchups
/// Returns the damage multiplier when attacking type attacks defending type
class TypeEffectiveness {
  // All Pokemon types
  static const List<String> allTypes = [
    'normal', 'fire', 'water', 'electric', 'grass', 'ice',
    'fighting', 'poison', 'ground', 'flying', 'psychic', 'bug',
    'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy'
  ];

  // Type effectiveness chart: attacking type -> defending type -> multiplier
  // Only storing non-1.0 multipliers for efficiency
  static const Map<String, Map<String, double>> _chart = {
    'normal': {'rock': 0.5, 'ghost': 0, 'steel': 0.5},
    'fire': {'fire': 0.5, 'water': 0.5, 'grass': 2, 'ice': 2, 'bug': 2, 'rock': 0.5, 'dragon': 0.5, 'steel': 2},
    'water': {'fire': 2, 'water': 0.5, 'grass': 0.5, 'ground': 2, 'rock': 2, 'dragon': 0.5},
    'electric': {'water': 2, 'electric': 0.5, 'grass': 0.5, 'ground': 0, 'flying': 2, 'dragon': 0.5},
    'grass': {'fire': 0.5, 'water': 2, 'grass': 0.5, 'poison': 0.5, 'ground': 2, 'flying': 0.5, 'bug': 0.5, 'rock': 2, 'dragon': 0.5, 'steel': 0.5},
    'ice': {'fire': 0.5, 'water': 0.5, 'grass': 2, 'ice': 0.5, 'ground': 2, 'flying': 2, 'dragon': 2, 'steel': 0.5},
    'fighting': {'normal': 2, 'ice': 2, 'poison': 0.5, 'flying': 0.5, 'psychic': 0.5, 'bug': 0.5, 'rock': 2, 'ghost': 0, 'dark': 2, 'steel': 2, 'fairy': 0.5},
    'poison': {'grass': 2, 'poison': 0.5, 'ground': 0.5, 'rock': 0.5, 'ghost': 0.5, 'steel': 0, 'fairy': 2},
    'ground': {'fire': 2, 'electric': 2, 'grass': 0.5, 'poison': 2, 'flying': 0, 'bug': 0.5, 'rock': 2, 'steel': 2},
    'flying': {'electric': 0.5, 'grass': 2, 'fighting': 2, 'bug': 2, 'rock': 0.5, 'steel': 0.5},
    'psychic': {'fighting': 2, 'poison': 2, 'psychic': 0.5, 'dark': 0, 'steel': 0.5},
    'bug': {'fire': 0.5, 'grass': 2, 'fighting': 0.5, 'poison': 0.5, 'flying': 0.5, 'psychic': 2, 'ghost': 0.5, 'dark': 2, 'steel': 0.5, 'fairy': 0.5},
    'rock': {'fire': 2, 'ice': 2, 'fighting': 0.5, 'ground': 0.5, 'flying': 2, 'bug': 2, 'steel': 0.5},
    'ghost': {'normal': 0, 'psychic': 2, 'ghost': 2, 'dark': 0.5},
    'dragon': {'dragon': 2, 'steel': 0.5, 'fairy': 0},
    'dark': {'fighting': 0.5, 'psychic': 2, 'ghost': 2, 'dark': 0.5, 'fairy': 0.5},
    'steel': {'fire': 0.5, 'water': 0.5, 'electric': 0.5, 'ice': 2, 'rock': 2, 'steel': 0.5, 'fairy': 2},
    'fairy': {'fire': 0.5, 'fighting': 2, 'poison': 0.5, 'dragon': 2, 'dark': 2, 'steel': 0.5},
  };

  /// Get the effectiveness multiplier when [attackingType] attacks [defendingType]
  static double getEffectiveness(String attackingType, String defendingType) {
    final attacking = attackingType.toLowerCase();
    final defending = defendingType.toLowerCase();
    
    if (_chart.containsKey(attacking) && _chart[attacking]!.containsKey(defending)) {
      return _chart[attacking]![defending]!;
    }
    return 1.0;
  }

  /// Calculate damage multipliers for a Pokemon with given types when attacked
  /// Returns a map of attacking type -> multiplier
  static Map<String, double> getDefensiveMatchups(List<String> defenderTypes) {
    Map<String, double> matchups = {};
    
    for (final attackingType in allTypes) {
      double multiplier = 1.0;
      for (final defenderType in defenderTypes) {
        multiplier *= getEffectiveness(attackingType, defenderType.toLowerCase());
      }
      matchups[attackingType] = multiplier;
    }
    
    return matchups;
  }

  /// Get types grouped by their effectiveness multiplier against the defender
  static Map<double, List<String>> getGroupedDefensiveMatchups(List<String> defenderTypes) {
    final matchups = getDefensiveMatchups(defenderTypes);
    Map<double, List<String>> grouped = {
      4.0: [],
      2.0: [],
      1.0: [],
      0.5: [],
      0.25: [],
      0.0: [],
    };
    
    for (final entry in matchups.entries) {
      final multiplier = entry.value;
      if (multiplier == 4.0) {
        grouped[4.0]!.add(entry.key);
      } else if (multiplier == 2.0) {
        grouped[2.0]!.add(entry.key);
      } else if (multiplier == 0.5) {
        grouped[0.5]!.add(entry.key);
      } else if (multiplier == 0.25) {
        grouped[0.25]!.add(entry.key);
      } else if (multiplier == 0.0) {
        grouped[0.0]!.add(entry.key);
      }
      // Skip 1.0 multiplier as it's neutral
    }
    
    return grouped;
  }
}
