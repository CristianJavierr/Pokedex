import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokemon_card.dart';
import '../utils/colors.dart';
import 'detail_screen.dart';
import 'filter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  final List<Pokemon> _allPokemons = [];
  int _currentOffset = 0;
  final int _limit = 50;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  
  // Filter state
  Map<String, dynamic> _filters = {
    'types': <String>[],
    'generations': <int>[],
    'heightRange': const RangeValues(0, 200),
    'weightRange': const RangeValues(0, 1000),
  };
  bool _hasActiveFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore &&
        _searchQuery.isEmpty) {
      _loadMorePokemons();
    }
  }

  void _loadMorePokemons() {
    setState(() {
      _isLoadingMore = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pokédex',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the advanced search to find Pokémon by\ntype, weakness, ability and more!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.searchBar,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search a pokémon',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppColors.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: _hasActiveFilters ? Colors.blue : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune,
                            color: _hasActiveFilters ? Colors.white : AppColors.textSecondary,
                          ),
                          onPressed: _openFilters,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Lista de Pokémon
            Expanded(
              child: _buildPokemonList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPokemonList() {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    if (_hasActiveFilters) {
      return _buildFilteredResults();
    }

    return Query(
      options: QueryOptions(
        document: gql(PokemonService.getPokemonsQuery),
        variables: {
          'limit': _limit,
          'offset': _currentOffset,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result, {fetchMore, refetch}) {
        if (result.hasException && _allPokemons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading Pokémon',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentOffset = 0;
                      _allPokemons.clear();
                    });
                    refetch?.call();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (result.isLoading && _allPokemons.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!result.isLoading && result.data != null) {
          final List<dynamic> pokemonList =
              result.data?['pokemon_v2_pokemon'] ?? [];

          if (pokemonList.isNotEmpty) {
            final newPokemons =
                pokemonList.map((json) => Pokemon.fromJson(json)).toList();

            // Agregar solo los nuevos pokémon que no estén ya en la lista
            for (var pokemon in newPokemons) {
              if (!_allPokemons.any((p) => p.id == pokemon.id)) {
                _allPokemons.add(pokemon);
              }
            }

            if (pokemonList.length < _limit) {
              _hasMore = false;
            }

            if (_isLoadingMore) {
              _currentOffset += _limit;
              _isLoadingMore = false;
            }
          } else {
            _hasMore = false;
          }
        }

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _allPokemons.length + (_hasMore ? 2 : 0),
          itemBuilder: (context, index) {
            if (index >= _allPokemons.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final pokemon = _allPokemons[index];
            return PokemonCard(
              pokemon: pokemon,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PokemonDetailScreen(pokemon: pokemon),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return Query(
      options: QueryOptions(
        document: gql(PokemonService.searchPokemonQuery),
        variables: {
          'name': '%$_searchQuery%',
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result, {fetchMore, refetch}) {
        if (result.hasException) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error searching Pokémon',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (result.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final List<dynamic> pokemonList =
            result.data?['pokemon_v2_pokemon'] ?? [];

        if (pokemonList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Pokémon found',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final pokemons =
            pokemonList.map((json) => Pokemon.fromJson(json)).toList();

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: pokemons.length,
          itemBuilder: (context, index) {
            final pokemon = pokemons[index];
            return PokemonCard(
              pokemon: pokemon,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PokemonDetailScreen(pokemon: pokemon),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openFilters() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(currentFilters: _filters),
      ),
    );

    if (result != null) {
      setState(() {
        _filters = result;
        _hasActiveFilters = (result['types'] as List).isNotEmpty ||
            (result['generations'] as List).isNotEmpty ||
            result['heightRange'] != const RangeValues(0, 200) ||
            result['weightRange'] != const RangeValues(0, 1000);
      });
    }
  }

  Widget _buildFilteredResults() {
    final types = _filters['types'] as List<String>;
    final generations = _filters['generations'] as List<int>;
    final heightRange = _filters['heightRange'] as RangeValues;
    final weightRange = _filters['weightRange'] as RangeValues;

    final query = PokemonService.getFilteredPokemonsQuery(
      types,
      generations,
      heightRange.start,
      heightRange.end,
      weightRange.start,
      weightRange.end,
    );

    return Query(
      options: QueryOptions(
        document: gql(query),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result, {fetchMore, refetch}) {
        if (result.hasException) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading filtered Pokémon',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => refetch?.call(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (result.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final List<dynamic> pokemonList =
            result.data?['pokemon_v2_pokemon'] ?? [];

        if (pokemonList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.filter_alt_off,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Pokémon match your filters',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters = {
                        'types': <String>[],
                        'generations': <int>[],
                        'heightRange': const RangeValues(0, 200),
                        'weightRange': const RangeValues(0, 1000),
                      };
                      _hasActiveFilters = false;
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          );
        }

        final pokemons =
            pokemonList.map((json) => Pokemon.fromJson(json)).toList();

        return Column(
          children: [
            // Filter summary
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${pokemons.length} Pokémon found',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _filters = {
                          'types': <String>[],
                          'generations': <int>[],
                          'heightRange': const RangeValues(0, 200),
                          'weightRange': const RangeValues(0, 1000),
                        };
                        _hasActiveFilters = false;
                      });
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: pokemons.length,
                itemBuilder: (context, index) {
                  final pokemon = pokemons[index];
                  return PokemonCard(
                    pokemon: pokemon,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PokemonDetailScreen(pokemon: pokemon),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
