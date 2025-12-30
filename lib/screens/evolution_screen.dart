import 'package:flutter/material.dart';
import '../models/pokemon_dto.dart';
import '../services/pokemon_service.dart';
import '../utils/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'detail_screen.dart';

class EvolutionScreen extends StatefulWidget {
  final PokemonDTO pokemon;

  const EvolutionScreen({Key? key, required this.pokemon}) : super(key: key);

  @override
  State<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends State<EvolutionScreen> {
  List<Map<String, dynamic>> _evolutionChain = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvolutionChain();
  }

  Future<void> _loadEvolutionChain() async {
    final chain = await PokemonService.getEvolutionChain(widget.pokemon.id);
    if (mounted) {
      setState(() {
        _evolutionChain = chain;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = PokemonTypeColors.getColorByType(
      widget.pokemon.types.isNotEmpty ? widget.pokemon.types[0] : 'normal',
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Evolution Chain',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _evolutionChain.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.catching_pokemon,
                        size: 80,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Does not evolve',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This Pokémon has no evolution chain',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : _evolutionChain.length == 1
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.catching_pokemon,
                            size: 80,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Does not evolve',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.pokemon.capitalizedName} is a standalone Pokémon',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _buildEvolutionTree(),
                    ),
    );
  }

  Widget _buildEvolutionTree() {
    // Group evolutions by their evolves_from_species_id
    Map<int?, List<Map<String, dynamic>>> evolutionsByParent = {};
    
    for (var evo in _evolutionChain) {
      final evolvesFrom = evo['evolves_from'] as int?;
      if (!evolutionsByParent.containsKey(evolvesFrom)) {
        evolutionsByParent[evolvesFrom] = [];
      }
      evolutionsByParent[evolvesFrom]!.add(evo);
    }
    
    // Find the base Pokemon (evolves_from is null)
    final basePokemon = _evolutionChain.firstWhere(
      (evo) => evo['evolves_from'] == null,
      orElse: () => _evolutionChain.first,
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _buildEvolutionLevel(basePokemon, evolutionsByParent),
    );
  }

  List<Widget> _buildEvolutionLevel(
    Map<String, dynamic> pokemon,
    Map<int?, List<Map<String, dynamic>>> evolutionsByParent,
  ) {
    List<Widget> widgets = [];
    
    // Add the current Pokemon
    widgets.add(Center(child: _buildEvolutionStage(pokemon)));
    
    // Find evolutions that evolve from this Pokemon
    final pokemonId = pokemon['id'] as int;
    final evolutions = evolutionsByParent[pokemonId] ?? [];
    
    if (evolutions.isEmpty) {
      // Check for forms
      if (pokemon['forms'] != null && (pokemon['forms'] as List).isNotEmpty) {
        widgets.addAll(_buildFormsList(pokemon['forms'] as List));
      }
      return widgets;
    }
    
    // Add arrow
    widgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Icon(
          Icons.arrow_downward,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
    
    if (evolutions.length == 1) {
      // Single evolution - show trigger and continue chain
      final evo = evolutions.first;
      final trigger = evo['trigger'] as String?;
      
      if (trigger != null && trigger.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                trigger,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }
      
      widgets.addAll(_buildEvolutionLevel(evo, evolutionsByParent));
    } else {
      // Multiple evolutions (branching) - show in a wrap/grid
      widgets.add(
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 16,
          children: evolutions.map((evo) {
            final trigger = evo['trigger'] as String?;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trigger != null && trigger.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trigger,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                _buildEvolutionStageCompact(evo),
              ],
            );
          }).toList(),
        ),
      );
    }
    
    return widgets;
  }

  Widget _buildEvolutionStageCompact(Map<String, dynamic> evolutionData) {
    final name = evolutionData['name'] as String;
    final id = evolutionData['id'] as int;

    return GestureDetector(
      onTap: () => _navigateToPokemon(id),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.network(
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
              width: 60,
              height: 60,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, size: 20),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              name[0].toUpperCase() + name.substring(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '#${id.toString().padLeft(3, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFormsList(List forms) {
    if (forms.isEmpty) return [];
    
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Different Forms',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 15,
        runSpacing: 15,
        children: forms.map((form) => _buildFormCard(form)).toList(),
      ),
    ];
  }

  Widget _buildFormCard(Map<String, dynamic> formData) {
    final name = formData['name'] as String;
    final id = formData['id'] as int;
    final formName = formData['form_name'] as String;

    return GestureDetector(
      onTap: () => _navigateToPokemonByName(name),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
        children: [
          Image.network(
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: const Icon(Icons.error, size: 30),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            formName[0].toUpperCase() + formName.substring(1).replaceAll('-', ' '),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildEvolutionStage(Map<String, dynamic> evolutionData) {
    final name = evolutionData['name'] as String;
    final id = evolutionData['id'] as int;

    return GestureDetector(
      onTap: () => _navigateToPokemon(id),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
        children: [
          Image.network(
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
            width: 100,
            height: 100,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 100,
                height: 100,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            name[0].toUpperCase() + name.substring(1),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '#${id.toString().padLeft(3, '0')}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _navigateToPokemon(int pokemonId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      // Fetch Pokemon data using the service
      final pokemon = await PokemonService.getPokemonById(pokemonId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (pokemon != null) {
          // Navigate to detail screen and remove all previous routes
          // This ensures that pressing back goes to home
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => PokemonDetailScreen(pokemon: pokemon),
            ),
            (route) => route.isFirst, // Keep only the home screen
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading Pokemon: $e')),
        );
      }
    }
  }

  Future<void> _navigateToPokemonByName(String pokemonName) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      // Fetch Pokemon data by exact name using the service
      final pokemon = await PokemonService.getPokemonByName(pokemonName);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (pokemon != null) {
          // Navigate to detail screen and remove all previous routes
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => PokemonDetailScreen(pokemon: pokemon),
            ),
            (route) => route.isFirst, // Keep only the home screen
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pokemon form not found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading Pokemon: $e')),
        );
      }
    }
  }
}
