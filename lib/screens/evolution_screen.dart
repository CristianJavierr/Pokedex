import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../utils/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'detail_screen.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class EvolutionScreen extends StatefulWidget {
  final Pokemon pokemon;

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
                  child: Text(
                    'No evolution data available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _evolutionChain.length; i++) ...[
                        Center(child: _buildEvolutionStage(_evolutionChain[i])),
                        if (i < _evolutionChain.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Icon(
                              Icons.arrow_downward,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        // Show forms after the last evolution
                        if (i == _evolutionChain.length - 1 && 
                            _evolutionChain[i]['forms'] != null &&
                            (_evolutionChain[i]['forms'] as List).isNotEmpty)
                          ..._buildFormsList(_evolutionChain[i]['forms'] as List),
                      ],
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
      onTap: () => _navigateToPokemon(id),
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
    final minLevel = evolutionData['min_level'];
    final trigger = evolutionData['trigger'] as String?;

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
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 120,
                height: 120,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            name[0].toUpperCase() + name.substring(1),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '#${id.toString().padLeft(3, '0')}',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          if (minLevel != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: PokemonTypeColors.getColorByType(widget.pokemon.types[0]).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Level $minLevel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PokemonTypeColors.getColorByType(widget.pokemon.types[0]),
                ),
              ),
            ),
          ],
          if (trigger != null && trigger.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              trigger[0].toUpperCase() + trigger.substring(1).replaceAll('-', ' '),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
      // Fetch Pokemon data
      final QueryOptions options = QueryOptions(
        document: gql(PokemonService.getPokemonsQuery),
        variables: {
          'limit': 1,
          'offset': pokemonId - 1,
        },
      );

      final QueryResult result = await PokemonService.client.value.query(options);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (!result.hasException && result.data != null) {
          final List<dynamic> pokemonList =
              result.data?['pokemon_v2_pokemon'] ?? [];

          if (pokemonList.isNotEmpty) {
            final pokemon = Pokemon.fromJson(pokemonList[0]);
            
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
