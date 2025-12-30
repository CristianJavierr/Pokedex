import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService {
  static const String _languageKey = 'app_language';
  static SharedPreferences? _prefs;
  
  // Language IDs from PokeAPI
  static const Map<String, int> languageIds = {
    'en': 9,  // English
    'es': 7,  // Spanish
  };

  static const Map<String, String> languageNames = {
    'en': 'English',
    'es': 'Español',
  };

  static const Map<String, String> languageFlags = {
    'en': '🇺🇸',
    'es': '🇪🇸',
  };

  // Translations for UI
  static const Map<String, Map<String, String>> translations = {
    'en': {
      'settings': 'Settings',
      'language': 'Language',
      'languageDesc': 'Select the language for Pokémon descriptions',
      'about': 'About',
      'version': 'Version',
      'developer': 'Developer',
      'details': 'Details',
      'evolution': 'Evolution',
      'location': 'Location',
      'locationSoon': 'Location coming soon...',
      'about_tab': 'About',
      'stats': 'Stats',
      'moves': 'Moves',
      'height': 'Height',
      'weight': 'Weight',
      'strongAgainst': 'Strong against',
      'noSuperEffective': 'No super effective types',
      'abilities': 'Abilities',
      'noAbilities': 'No abilities available',
      'hidden': 'Hidden',
      'weakX4': 'Weak x4',
      'weakX2': 'Weak x2',
      'resistX2': 'Resist x½',
      'resistX4': 'Resist x¼',
      'immune': 'Immune',
      'noTypeMatchups': 'No special type matchups',
      'statsOverview': 'Stats Overview',
      'noStatsAvailable': 'No stats available',
      'noMovesAvailable': 'No moves available',
      'sortBy': 'Sort by:',
      'level': 'Level',
      'name': 'Name',
      'moves_count': 'moves',
      'levelUp': 'Level Up',
      'tmhm': 'TM/HM',
      'tutor': 'Tutor',
      'egg': 'Egg',
      'noDescription': 'No description available.',
      'normal': 'Normal',
      'shiny': 'Shiny',
      'forms': 'Forms',
      'class': 'Class',
      'power': 'Power',
      'acc': 'Acc',
      'pp': 'PP',
      // Trivia
      'whosThat': "Who's That Pokémon?",
      'errorLoading': 'Error loading question',
      'tryAgain': 'Try Again',
      'correct': "Correct! It's",
      'itsName': "It's",
      'nextPokemon': 'Next Pokémon',
      // Map
      'kantoMap': 'Kanto Map',
      'cities': 'Cities',
      'landmarks': 'Landmarks',
      'pokemonFound': 'Pokémon found here:',
      'eliteFourArea': 'Elite Four & Champion area - Prepare your best team!',
      'exploreKanto': 'Explore the Kanto region',
    },
    'es': {
      'settings': 'Configuración',
      'language': 'Idioma',
      'languageDesc': 'Selecciona el idioma para las descripciones de Pokémon',
      'about': 'Acerca de',
      'version': 'Versión',
      'developer': 'Desarrollador',
      'details': 'Detalles',
      'evolution': 'Evolución',
      'location': 'Ubicación',
      'locationSoon': 'Ubicación próximamente...',
      'about_tab': 'Info',
      'stats': 'Estadísticas',
      'moves': 'Movimientos',
      'height': 'Altura',
      'weight': 'Peso',
      'strongAgainst': 'Fuerte contra',
      'noSuperEffective': 'Sin tipos super efectivos',
      'abilities': 'Habilidades',
      'noAbilities': 'Sin habilidades disponibles',
      'hidden': 'Oculta',
      'weakX4': 'Débil x4',
      'weakX2': 'Débil x2',
      'resistX2': 'Resiste x½',
      'resistX4': 'Resiste x¼',
      'immune': 'Inmune',
      'noTypeMatchups': 'Sin matchups de tipo especiales',
      'statsOverview': 'Resumen de Estadísticas',
      'noStatsAvailable': 'Sin estadísticas disponibles',
      'noMovesAvailable': 'Sin movimientos disponibles',
      'sortBy': 'Ordenar por:',
      'level': 'Nivel',
      'name': 'Nombre',
      'moves_count': 'movimientos',
      'levelUp': 'Por Nivel',
      'tmhm': 'MT/MO',
      'tutor': 'Tutor',
      'egg': 'Huevo',
      'noDescription': 'Descripción no disponible.',
      'normal': 'Normal',
      'shiny': 'Shiny',
      'forms': 'Formas',
      'class': 'Clase',
      'power': 'Poder',
      'acc': 'Prec',
      'pp': 'PP',
      // Trivia
      'whosThat': '¿Quién es ese Pokémon?',
      'errorLoading': 'Error al cargar pregunta',
      'tryAgain': 'Intentar de nuevo',
      'correct': '¡Correcto! Es',
      'itsName': 'Es',
      'nextPokemon': 'Siguiente Pokémon',
      // Map
      'kantoMap': 'Mapa de Kanto',
      'cities': 'Ciudades',
      'landmarks': 'Lugares',
      'pokemonFound': 'Pokémon encontrados aquí:',
      'eliteFourArea': 'Área del Alto Mando y Campeón - ¡Prepara tu mejor equipo!',
      'exploreKanto': 'Explora la región de Kanto',
    },
  };

  static String _currentLanguage = 'en';
  static final ValueNotifier<String> languageNotifier = ValueNotifier('en');

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _currentLanguage = _prefs?.getString(_languageKey) ?? 'en';
    languageNotifier.value = _currentLanguage;
  }

  static String get currentLanguage => _currentLanguage;
  
  static int get currentLanguageId => languageIds[_currentLanguage] ?? 9;

  static Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    languageNotifier.value = languageCode;
    await _prefs?.setString(_languageKey, languageCode);
  }

  static String getLanguageName(String code) {
    return languageNames[code] ?? 'English';
  }

  static String getLanguageFlag(String code) {
    return languageFlags[code] ?? '🇺🇸';
  }

  static String tr(String key) {
    return translations[_currentLanguage]?[key] ?? translations['en']?[key] ?? key;
  }
}
