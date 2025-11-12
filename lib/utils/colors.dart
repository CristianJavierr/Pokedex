import 'package:flutter/material.dart';

class PokemonTypeColors {
  static const Map<String, Color> typeColors = {
    'grass': Color(0xFF78C850),
    'poison': Color(0xFFA040A0),
    'fire': Color(0xFFF08030),
    'water': Color(0xFF6890F0),
    'bug': Color(0xFFA8B820),
    'normal': Color(0xFFA8A878),
    'electric': Color(0xFFF8D030),
    'ground': Color(0xFFE0C068),
    'fairy': Color(0xFFEE99AC),
    'fighting': Color(0xFFC03028),
    'psychic': Color(0xFFF85888),
    'rock': Color(0xFFB8A038),
    'ghost': Color(0xFF705898),
    'ice': Color(0xFF98D8D8),
    'dragon': Color(0xFF7038F8),
    'dark': Color(0xFF705848),
    'steel': Color(0xFFB8B8D0),
    'flying': Color(0xFFA890F0),
  };

  static Color getColorByType(String type) {
    return typeColors[type.toLowerCase()] ?? Colors.grey;
  }
}

class AppColors {
  static const Color background = Color(0xFFF5F5F5);
  static const Color searchBar = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2E3156);
  static const Color textSecondary = Color(0xFF6B7280);
}
