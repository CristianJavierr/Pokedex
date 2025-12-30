import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pokemon_dto.dart';
import '../services/pokemon_service.dart';
import '../services/favorites_service.dart';
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
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);
  final ScrollController _scrollController = ScrollController();
  final List<PokemonDTO> _allPokemons = [];
  int _currentOffset = 0;
  final int _limit = 50;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Search results
  List<PokemonDTO> _searchResults = [];
  bool _isSearching = false;
  
  // Filter state
  Map<String, dynamic> _filters = {
    'types': <String>[],
    'generations': <int>[],
    'heightRange': const RangeValues(0, 200),
    'weightRange': const RangeValues(0, 1000),
  };
  bool _hasActiveFilters = false;
  bool _showFavoritesOnly = false;
  List<PokemonDTO> _filteredPokemons = [];
  List<PokemonDTO> _favoritePokemons = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialPokemons();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPokemons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final pokemons = await PokemonService.getPokemons(
      limit: _limit,
      offset: 0,
    );

    if (mounted) {
      setState(() {
        _allPokemons.addAll(pokemons);
        _isLoading = false;
        _hasMore = pokemons.length >= _limit;
        _currentOffset = _limit;
      });
    }
  }

  /// cambio de texto con debounce para evitar consultas excesivas
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (mounted) {
        setState(() {
          _searchQuery = value;
        });
        if (value.isNotEmpty) {
          _performSearch(value);
        }
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    final results = await PokemonService.searchPokemons(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore &&
        _searchQuery.isEmpty &&
        !_hasActiveFilters &&
        !_showFavoritesOnly) {
      _loadMorePokemons();
    }
  }

  Future<void> _loadMorePokemons() async {
    setState(() {
      _isLoadingMore = true;
    });

    final pokemons = await PokemonService.getPokemons(
      limit: _limit,
      offset: _currentOffset,
    );

    if (mounted) {
      setState(() {
        for (var pokemon in pokemons) {
          if (!_allPokemons.any((p) => p.id == pokemon.id)) {
            _allPokemons.add(pokemon);
          }
        }
        _isLoadingMore = false;
        _hasMore = pokemons.length >= _limit && _allPokemons.length < 1025;
        _currentOffset += _limit;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final favoriteIds = FavoritesService.getFavorites();
    if (favoriteIds.isEmpty) {
      setState(() {
        _favoritePokemons = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final pokemons = await PokemonService.getPokemonsByIds(favoriteIds.toList());

    if (mounted) {
      setState(() {
        _favoritePokemons = pokemons;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFilteredPokemons() async {
    final types = _filters['types'] as List<String>;
    final generations = _filters['generations'] as List<int>;
    final heightRange = _filters['heightRange'] as RangeValues;
    final weightRange = _filters['weightRange'] as RangeValues;

    setState(() {
      _isLoading = true;
    });

    final pokemons = await PokemonService.getFilteredPokemons(
      types: types,
      generations: generations,
      minHeight: heightRange.start,
      maxHeight: heightRange.end,
      minWeight: weightRange.start,
      maxWeight: weightRange.end,
    );

    if (mounted) {
      setState(() {
        _filteredPokemons = pokemons;
        _isLoading = false;
      });
    }
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
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: AppColors.textPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Pokédex',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
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
                            onChanged: _onSearchChanged,
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
                          color: _showFavoritesOnly ? Colors.red : Colors.white,
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
                            _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                            color: _showFavoritesOnly ? Colors.white : AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _showFavoritesOnly = !_showFavoritesOnly;
                            });
                            if (_showFavoritesOnly) {
                              _loadFavorites();
                            }
                          },
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

    if (_showFavoritesOnly) {
      return _buildFavoritesResults();
    }

    if (_hasActiveFilters) {
      return _buildFilteredResults();
    }

    if (_isLoading && _allPokemons.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _allPokemons.isEmpty) {
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
                _loadInitialPokemons();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
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
          isFavorite: FavoritesService.isFavorite(pokemon.id),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PokemonDetailScreen(pokemon: pokemon),
              ),
            ).then((_) => setState(() {})); // Refrescar favoritos al volver
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty) {
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

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final pokemon = _searchResults[index];
        return PokemonCard(
          pokemon: pokemon,
          isFavorite: FavoritesService.isFavorite(pokemon.id),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PokemonDetailScreen(pokemon: pokemon),
              ),
            ).then((_) => setState(() {}));
          },
        );
      },
    );
  }

  Widget _buildFavoritesResults() {
    final favoriteIds = FavoritesService.getFavorites();
    
    if (favoriteIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on a Pokémon\nto add it to your favorites',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Favorites header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_favoritePokemons.length} Favorite${_favoritePokemons.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showFavoritesOnly = false;
                  });
                },
                child: const Text(
                  'Show All',
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
            itemCount: _favoritePokemons.length,
            itemBuilder: (context, index) {
              final pokemon = _favoritePokemons[index];
              return PokemonCard(
                pokemon: pokemon,
                isFavorite: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PokemonDetailScreen(pokemon: pokemon),
                    ),
                  ).then((_) {
                    _loadFavorites();
                    setState(() {});
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilteredResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredPokemons.isEmpty) {
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

    return Column(
      children: [
        // Filter info header
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
              Row(
                children: [
                  const Icon(Icons.filter_alt, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_filteredPokemons.length} result${_filteredPokemons.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
                child: const Text(
                  'Clear Filters',
                  style: TextStyle(
                    color: Colors.blue,
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
            itemCount: _filteredPokemons.length,
            itemBuilder: (context, index) {
              final pokemon = _filteredPokemons[index];
              return PokemonCard(
                pokemon: pokemon,
                isFavorite: FavoritesService.isFavorite(pokemon.id),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PokemonDetailScreen(pokemon: pokemon),
                    ),
                  ).then((_) => setState(() {}));
                },
              );
            },
          ),
        ),
      ],
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
      
      if (_hasActiveFilters) {
        _loadFilteredPokemons();
      }
    }
  }
}
