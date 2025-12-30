import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _favoritesKey = 'pokemon_favorites';
  static SharedPreferences? _prefs;
  static Set<int> _favorites = {};

  /// Inicializa el servicio cargando los favoritos desde SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFavorites();
  }

  /// Carga los favoritos desde SharedPreferences
  static void _loadFavorites() {
    final List<String>? favList = _prefs?.getStringList(_favoritesKey);
    if (favList != null) {
      _favorites = favList.map((id) => int.parse(id)).toSet();
    }
  }

  /// Guarda los favoritos en SharedPreferences
  static Future<void> _saveFavorites() async {
    await _prefs?.setStringList(
      _favoritesKey,
      _favorites.map((id) => id.toString()).toList(),
    );
  }

  /// Verifica si un Pokémon es favorito
  static bool isFavorite(int pokemonId) {
    return _favorites.contains(pokemonId);
  }

  /// Agrega o quita un Pokémon de favoritos
  /// Retorna true si ahora es favorito, false si se quitó
  static Future<bool> toggleFavorite(int pokemonId) async {
    if (_favorites.contains(pokemonId)) {
      _favorites.remove(pokemonId);
    } else {
      _favorites.add(pokemonId);
    }
    await _saveFavorites();
    return _favorites.contains(pokemonId);
  }

  /// Obtiene la lista de IDs de Pokémon favoritos
  static Set<int> getFavorites() {
    return Set.from(_favorites);
  }

  /// Obtiene el número total de favoritos
  static int get count => _favorites.length;
}
