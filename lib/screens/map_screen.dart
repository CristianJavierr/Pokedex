import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/colors.dart';
import '../services/settings_service.dart';
import '../services/pokemon_service.dart';
import 'detail_screen.dart';

/// Data model for a location on a Pokemon map
class MapLocation {
  final String nameEn;
  final String nameEs;
  final double x;
  final double y;
  final Color color;
  final bool isCity;
  final List<int> pokemonIds;

  const MapLocation({
    required this.nameEn,
    required this.nameEs,
    required this.x,
    required this.y,
    required this.color,
    this.isCity = true,
    this.pokemonIds = const [],
  });

  String getName(int languageId) => languageId == 7 ? nameEs : nameEn;
}

/// Region data
enum Region { kanto, johto }

class RegionData {
  final String nameEn;
  final String nameEs;
  final String mapUrl;
  final double aspectRatio;
  final List<MapLocation> locations;
  final bool isLocal;

  const RegionData({
    required this.nameEn,
    required this.nameEs,
    required this.mapUrl,
    required this.aspectRatio,
    required this.locations,
    this.isLocal = false,
  });

  String getName(int languageId) => languageId == 7 ? nameEs : nameEn;
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TransformationController _transformationController = TransformationController();
  MapLocation? _selectedLocation;
  Region _currentRegion = Region.kanto;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    // Delay marker rendering until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isMapReady = true);
      }
    });
  }

  // Region data
  static final Map<Region, RegionData> _regions = {
    Region.kanto: RegionData(
      nameEn: 'Kanto',
      nameEs: 'Kanto',
      mapUrl: 'https://archives.bulbagarden.net/media/upload/8/86/Kanto_Town_Map_RBY.png',
      aspectRatio: 160 / 144,
      locations: _kantoLocations,
    ),
    Region.johto: RegionData(
      nameEn: 'Johto',
      nameEs: 'Johto',
      mapUrl: 'assets/images/Johto_Town_Map_GSC.png',
      aspectRatio: 160 / 144,
      locations: _johtoLocations,
      isLocal: true,
    ),
  };

  // =====================
  // KANTO LOCATIONS
  // =====================
  static const List<MapLocation> _kantoLocations = [
    MapLocation(
      nameEn: 'Pallet Town',
      nameEs: 'Pueblo Paleta',
      x: 0.225,
      y: 0.67,
      color: Color(0xFFFFFFFF),
      pokemonIds: [16, 19, 21, 29, 32],
    ),
    MapLocation(
      nameEn: 'Viridian City',
      nameEs: 'Ciudad Verde',
      x: 0.225,
      y: 0.50,
      color: Color(0xFF7FFFD4),
      pokemonIds: [16, 19, 21, 56, 84],
    ),
    MapLocation(
      nameEn: 'Viridian Forest',
      nameEs: 'Bosque Verde',
      x: 0.225,
      y: 0.28,
      color: Color(0xFF228B22),
      isCity: false,
      pokemonIds: [10, 11, 13, 14, 25],
    ),
    MapLocation(
      nameEn: 'Pewter City',
      nameEs: 'Ciudad Plateada',
      x: 0.225,
      y: 0.20,
      color: Color(0xFF808080),
      pokemonIds: [74, 95],
    ),
    MapLocation(
      nameEn: 'Mt. Moon',
      nameEs: 'Monte Luna',
      x: 0.425,
      y: 0.165,
      color: Color(0xFF483D8B),
      isCity: false,
      pokemonIds: [35, 41, 46, 74],
    ),
    MapLocation(
      nameEn: 'Cerulean City',
      nameEs: 'Ciudad Celeste',
      x: 0.625,
      y: 0.165,
      color: Color(0xFF4169E1),
      pokemonIds: [54, 60, 118, 120],
    ),
    MapLocation(
      nameEn: 'Rock Tunnel',
      nameEs: 'Túnel Roca',
      x: 0.825,
      y: 0.22,
      color: Color(0xFF8B4513),
      isCity: false,
      pokemonIds: [41, 66, 74, 95],
    ),
    MapLocation(
      nameEn: 'Vermilion City',
      nameEs: 'Ciudad Carmín',
      x: 0.625,
      y: 0.555,
      color: Color(0xFFFF6347),
      pokemonIds: [25, 26, 81, 82, 100],
    ),
    MapLocation(
      nameEn: 'Lavender Town',
      nameEs: 'Pueblo Lavanda',
      x: 0.825,
      y: 0.335,
      color: Color(0xFFE6E6FA),
      pokemonIds: [92, 93, 104],
    ),
    MapLocation(
      nameEn: 'Celadon City',
      nameEs: 'Ciudad Azulona',
      x: 0.475,
      y: 0.335,
      color: Color(0xFF8FBC8F),
      pokemonIds: [43, 44, 69, 70, 102, 133],
    ),
    MapLocation(
      nameEn: 'Fuchsia City',
      nameEs: 'Ciudad Fucsia',
      x: 0.525,
      y: 0.78,
      color: Color(0xFFFF00FF),
      pokemonIds: [48, 88, 109, 114, 123, 127],
    ),
    MapLocation(
      nameEn: 'Saffron City',
      nameEs: 'Ciudad Azafrán',
      x: 0.625,
      y: 0.335,
      color: Color(0xFFFFD700),
      pokemonIds: [63, 64, 65, 122],
    ),
    MapLocation(
      nameEn: 'Seafoam Islands',
      nameEs: 'Islas Espuma',
      x: 0.38,
      y: 0.88,
      color: Color(0xFF00CED1),
      isCity: false,
      pokemonIds: [86, 87, 90, 116, 117, 144],
    ),
    MapLocation(
      nameEn: 'Cinnabar Island',
      nameEs: 'Isla Canela',
      x: 0.225,
      y: 0.88,
      color: Color(0xFFFF4500),
      pokemonIds: [58, 77, 126, 137, 138, 140, 142],
    ),
    MapLocation(
      nameEn: 'Victory Road',
      nameEs: 'Camino Victoria',
      x: 0.125,
      y: 0.28,
      color: Color(0xFF9932CC),
      isCity: false,
      pokemonIds: [66, 67, 95, 105, 112],
    ),
    MapLocation(
      nameEn: 'Indigo Plateau',
      nameEs: 'Meseta Añil',
      x: 0.125,
      y: 0.175,
      color: Color(0xFF4B0082),
      pokemonIds: [],
    ),
  ];

  // =====================
  // JOHTO LOCATIONS
  // =====================
  static const List<MapLocation> _johtoLocations = [
    MapLocation(
      nameEn: 'New Bark Town',
      nameEs: 'Pueblo Primavera',
      x: 0.875,
      y: 0.52,
      color: Color(0xFFFFFFFF),
      pokemonIds: [152, 155, 158], // Starters
    ),
    MapLocation(
      nameEn: 'Cherrygrove City',
      nameEs: 'Ciudad Cerezo',
      x: 0.72,
      y: 0.52,
      color: Color(0xFFFFB6C1), // Light pink
      pokemonIds: [161, 163, 165, 167], // Sentret, Hoothoot, Ledyba, Spinarak
    ),
    MapLocation(
      nameEn: 'Violet City',
      nameEs: 'Ciudad Malva',
      x: 0.72,
      y: 0.28,
      color: Color(0xFF8A2BE2), // Blue violet
      pokemonIds: [16, 17, 21, 22], // Pidgey, Pidgeotto, Spearow, Fearow
    ),
    MapLocation(
      nameEn: 'Azalea Town',
      nameEs: 'Pueblo Azalea',
      x: 0.42,
      y: 0.52,
      color: Color(0xFFFFFFFF),
      pokemonIds: [10, 11, 14, 15], // Caterpie, Metapod, Kakuna, Beedrill
    ),
    MapLocation(
      nameEn: 'Goldenrod City',
      nameEs: 'Ciudad Trigal',
      x: 0.42,
      y: 0.28,
      color: Color(0xFFFFD700), // Gold
      pokemonIds: [35, 173, 175, 122], // Clefairy, Cleffa, Togepi, Mr. Mime
    ),
    MapLocation(
      nameEn: 'Ecruteak City',
      nameEs: 'Ciudad Iris',
      x: 0.42,
      y: 0.12,
      color: Color(0xFF9370DB), // Medium purple
      pokemonIds: [92, 93, 200], // Gastly, Haunter, Misdreavus
    ),
    MapLocation(
      nameEn: 'Olivine City',
      nameEs: 'Ciudad Olivo',
      x: 0.18,
      y: 0.38,
      color: Color(0xFFC0C0C0), // Silver
      pokemonIds: [81, 82, 227], // Magnemite, Magneton, Skarmory
    ),
    MapLocation(
      nameEn: 'Cianwood City',
      nameEs: 'Ciudad Caña',
      x: 0.10,
      y: 0.72,
      color: Color(0xFFDEB887), // Burlywood
      pokemonIds: [66, 67, 236], // Machop, Machoke, Tyrogue
    ),
    MapLocation(
      nameEn: 'Mahogany Town',
      nameEs: 'Pueblo Caoba',
      x: 0.72,
      y: 0.12,
      color: Color(0xFF8B4513), // Saddle brown
      pokemonIds: [86, 87, 220, 221], // Seel, Dewgong, Swinub, Piloswine
    ),
    MapLocation(
      nameEn: 'Blackthorn City',
      nameEs: 'Ciudad Endrino',
      x: 0.875,
      y: 0.12,
      color: Color(0xFF2F4F4F), // Dark slate gray
      pokemonIds: [147, 148, 149], // Dratini, Dragonair, Dragonite
    ),
    MapLocation(
      nameEn: 'Lake of Rage',
      nameEs: 'Lago de la Furia',
      x: 0.72,
      y: 0.04,
      color: Color(0xFFDC143C), // Crimson
      isCity: false,
      pokemonIds: [129, 130], // Magikarp, Gyarados (Red Gyarados!)
    ),
    MapLocation(
      nameEn: 'Ilex Forest',
      nameEs: 'Bosque Azalea',
      x: 0.52,
      y: 0.52,
      color: Color(0xFF228B22), // Forest green
      isCity: false,
      pokemonIds: [43, 44, 46, 47, 48], // Oddish, Gloom, Paras, Parasect, Venonat
    ),
    MapLocation(
      nameEn: 'National Park',
      nameEs: 'Parque Nacional',
      x: 0.52,
      y: 0.18,
      color: Color(0xFF32CD32), // Lime green
      isCity: false,
      pokemonIds: [10, 11, 123, 127, 204], // Bug Contest: Caterpie, Metapod, Scyther, Pinsir, Pineco
    ),
    MapLocation(
      nameEn: 'Bell Tower',
      nameEs: 'Torre Campana',
      x: 0.35,
      y: 0.08,
      color: Color(0xFFFFD700), // Gold
      isCity: false,
      pokemonIds: [250], // Ho-Oh
    ),
    MapLocation(
      nameEn: 'Whirl Islands',
      nameEs: 'Islas Remolino',
      x: 0.18,
      y: 0.58,
      color: Color(0xFF4169E1), // Royal blue
      isCity: false,
      pokemonIds: [86, 87, 116, 117, 249], // Seel, Dewgong, Horsea, Seadra, Lugia
    ),
    MapLocation(
      nameEn: 'Mt. Silver',
      nameEs: 'Monte Plateado',
      x: 0.95,
      y: 0.28,
      color: Color(0xFFC0C0C0), // Silver
      isCity: false,
      pokemonIds: [215, 217, 231, 246], // Sneasel, Ursaring, Phanpy, Larvitar
    ),
  ];

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  RegionData get _currentRegionData => _regions[_currentRegion]!;

  @override
  Widget build(BuildContext context) {
    final languageId = SettingsService.currentLanguageId;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentRegionData.getName(languageId)} ${languageId == 7 ? "Mapa" : "Map"}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map, color: Colors.white),
            onPressed: _resetZoom,
            tooltip: 'Reset zoom',
          ),
        ],
      ),
      body: Column(
        children: [
          // Region dropdown selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Region>(
                  value: _currentRegion,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2d3a4a),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  items: Region.values.map((region) {
                    final data = _regions[region]!;
                    return DropdownMenuItem<Region>(
                      value: region,
                      child: Row(
                        children: [
                          Icon(
                            Icons.map,
                            color: _getRegionColor(region),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(data.getName(languageId)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (region) {
                    if (region != null) _switchRegion(region);
                  },
                ),
              ),
            ),
          ),
          
          // Instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              languageId == 7 
                ? 'Toca una ubicación para ver los Pokémon'
                : 'Tap a location to see Pokémon',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          
          // Map with image background
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 5.0,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _currentRegionData.aspectRatio,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Wait for valid constraints before rendering markers
                      final hasValidSize = constraints.maxWidth > 0 && 
                                           constraints.maxHeight > 0 &&
                                           constraints.maxWidth.isFinite &&
                                           constraints.maxHeight.isFinite;
                      
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Background map image
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _currentRegionData.isLocal
                                ? Image.asset(
                                    _currentRegionData.mapUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFF2d3a4a),
                                      child: const Center(
                                        child: Icon(
                                          Icons.map,
                                          color: Colors.white54,
                                          size: 64,
                                        ),
                                      ),
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: _currentRegionData.mapUrl,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => Container(
                                      color: const Color(0xFF2d3a4a),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: const Color(0xFF2d3a4a),
                                      child: const Center(
                                        child: Icon(
                                          Icons.map,
                                          color: Colors.white54,
                                          size: 64,
                                        ),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                          
                          // Location markers - only render when map is ready and constraints are valid
                          if (hasValidSize && _isMapReady)
                          ..._currentRegionData.locations.map((location) {
                            final isSelected = _selectedLocation == location;
                            return Positioned(
                              left: location.x * constraints.maxWidth - 15,
                              top: location.y * constraints.maxHeight - 15,
                              child: GestureDetector(
                                onTap: () => _onLocationTap(location),
                                child: Container(
                                  width: isSelected ? 36 : 30,
                                  height: isSelected ? 36 : 30,
                                  decoration: BoxDecoration(
                                    color: location.color.withOpacity(isSelected ? 0.95 : 0.85),
                                    shape: location.isCity ? BoxShape.rectangle : BoxShape.circle,
                                    borderRadius: location.isCity ? BorderRadius.circular(6) : null,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.black54,
                                      width: isSelected ? 3 : 2,
                                    ),
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: location.color.withOpacity(0.6),
                                        blurRadius: 12,
                                        spreadRadius: 3,
                                      ),
                                    ] : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      location.isCity ? Icons.location_city : Icons.terrain,
                                      color: _getContrastColor(location.color),
                                      size: isSelected ? 18 : 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // Selected location info panel
          if (_selectedLocation != null)
            _buildLocationInfo(_selectedLocation!),
        ],
      ),
    );
  }

  void _switchRegion(Region region) {
    if (region != _currentRegion) {
      setState(() {
        _currentRegion = region;
        _selectedLocation = null;
        _transformationController.value = Matrix4.identity();
        _isMapReady = false;
      });
      // Re-enable markers after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isMapReady = true);
        }
      });
    }
  }

  Color _getRegionColor(Region region) {
    switch (region) {
      case Region.kanto:
        return Colors.red;
      case Region.johto:
        return Colors.amber;
    }
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  Widget _buildLocationInfo(MapLocation location) {
    final languageId = SettingsService.currentLanguageId;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2d3a4a),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: location.color,
                    shape: location.isCity ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: location.isCity ? BorderRadius.circular(6) : null,
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: Icon(
                    location.isCity ? Icons.location_city : Icons.terrain,
                    color: _getContrastColor(location.color),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.getName(languageId),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        location.isCity 
                          ? (languageId == 7 ? 'Ciudad' : 'City')
                          : (languageId == 7 ? 'Lugar' : 'Landmark'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => setState(() => _selectedLocation = null),
                ),
              ],
            ),
            if (location.pokemonIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                SettingsService.tr('pokemonFound'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: location.pokemonIds.length,
                  itemBuilder: (context, index) {
                    final pokemonId = location.pokemonIds[index];
                    return GestureDetector(
                      onTap: () => _navigateToPokemon(pokemonId),
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$pokemonId.png',
                              width: 45,
                              height: 45,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.catching_pokemon, 
                                    size: 40, color: Colors.white54),
                            ),
                            Text(
                              '#${pokemonId.toString().padLeft(3, '0')}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber.withOpacity(0.8),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        SettingsService.tr('eliteFourArea'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onLocationTap(MapLocation location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _navigateToPokemon(int pokemonId) async {
    final pokemon = await PokemonService.getPokemonById(pokemonId);
    if (pokemon != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PokemonDetailScreen(pokemon: pokemon),
        ),
      );
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }
}
