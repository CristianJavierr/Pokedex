import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon.dart';
import '../utils/colors.dart';

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;
  final VoidCallback? onTap;

  const PokemonCard({
    Key? key,
    required this.pokemon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color cardColor = PokemonTypeColors.getColorByType(pokemon.types.first);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre y número
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pokemon.capitalizedName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    pokemon.formattedId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tipos
              ...pokemon.types.map((type) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTypeIcon(type),
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          type.capitalize(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
              const Spacer(),
              // Imagen del Pokémon
              Align(
                alignment: Alignment.bottomRight,
                child: Hero(
                  tag: 'pokemon_${pokemon.id}',
                  child: CachedNetworkImage(
                    imageUrl: pokemon.imageUrl,
                    height: 100,
                    width: 100,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none, // Para mantener el estilo pixelado
                    placeholder: (context, url) => const SizedBox(
                      height: 100,
                      width: 100,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.catching_pokemon,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department;
      case 'water':
        return Icons.water_drop;
      case 'grass':
        return Icons.grass;
      case 'electric':
        return Icons.bolt;
      case 'poison':
        return Icons.science;
      case 'flying':
        return Icons.air;
      case 'bug':
        return Icons.bug_report;
      case 'normal':
        return Icons.circle;
      case 'ground':
        return Icons.terrain;
      case 'fairy':
        return Icons.auto_awesome;
      case 'fighting':
        return Icons.sports_mma;
      case 'psychic':
        return Icons.psychology;
      case 'rock':
        return Icons.landscape;
      case 'ghost':
        return Icons.nights_stay;
      case 'ice':
        return Icons.ac_unit;
      case 'dragon':
        return Icons.android;
      case 'dark':
        return Icons.dark_mode;
      case 'steel':
        return Icons.shield;
      default:
        return Icons.circle;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
