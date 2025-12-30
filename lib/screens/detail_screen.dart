import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon_dto.dart';
import '../utils/colors.dart';
import '../utils/type_effectiveness.dart';
import '../services/pokemon_service.dart';
import '../services/favorites_service.dart';
import '../services/settings_service.dart';
import 'evolution_screen.dart';

class PokemonDetailScreen extends StatefulWidget {
  final PokemonDTO pokemon;

  const PokemonDetailScreen({
    Key? key,
    required this.pokemon,
  }) : super(key: key);

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _favoriteAnimController;
  late Animation<double> _favoriteScaleAnimation;
  String? _description;
  bool _isLoadingDescription = true;
  List<String> _strongAgainstTypes = [];
  bool _isLoadingTypes = true;
  List<Map<String, dynamic>> _moves = [];
  bool _isLoadingMoves = true;
  List<Map<String, dynamic>> _abilities = [];
  bool _isLoadingAbilities = true;
  int _currentBottomIndex = 0;
  
  // Moves filter state
  String _selectedMoveMethod = 'level-up';
  String _moveSortBy = 'level'; // 'level' or 'name'
  static const List<String> _moveMethods = ['level-up', 'machine', 'tutor', 'egg'];
  
  // Favorite state
  bool _isFavorite = false;
  
  // Shiny and Forms state
  bool _isShiny = false;
  List<Map<String, dynamic>> _availableForms = [];
  int _currentPokemonId = 0;
  String _currentFormName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isFavorite = FavoritesService.isFavorite(widget.pokemon.id);
    
    // Favorite animation setup
    _favoriteAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _favoriteScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _favoriteAnimController,
      curve: Curves.easeInOut,
    ));
    _currentPokemonId = widget.pokemon.id;
    _loadDescription();
    _loadStrongAgainstTypes();
    _loadMoves();
    _loadAbilities();
    _loadForms();
    
    // Listen for language changes
    SettingsService.languageNotifier.addListener(_onLanguageChange);
  }

  void _onLanguageChange() {
    // Reload description when language changes
    setState(() {
      _isLoadingDescription = true;
    });
    _loadDescription();
  }

  Future<void> _loadForms() async {
    try {
      final forms = await PokemonService.getPokemonForms(widget.pokemon.id);
      if (mounted) {
        setState(() {
          _availableForms = forms;
        });
      }
    } catch (e) {
      // Forms loading failed, no worries
    }
  }

  Future<void> _loadDescription() async {
    final description = await PokemonService.getPokemonDescription(widget.pokemon.id);
    if (mounted) {
      setState(() {
        _description = description;
        _isLoadingDescription = false;
      });
    }
  }

  Future<void> _loadStrongAgainstTypes() async {
    final types = await PokemonService.getStrongAgainstTypes(widget.pokemon.types);
    if (mounted) {
      setState(() {
        _strongAgainstTypes = types;
        _isLoadingTypes = false;
      });
    }
  }

  Future<void> _loadMoves() async {
    final moves = await PokemonService.getPokemonMoves(widget.pokemon.id);
    if (mounted) {
      setState(() {
        _moves = moves;
        _isLoadingMoves = false;
      });
    }
  }

  Future<void> _loadAbilities() async {
    final abilities = await PokemonService.getPokemonAbilities(widget.pokemon.id);
    if (mounted) {
      setState(() {
        _abilities = abilities;
        _isLoadingAbilities = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _favoriteAnimController.dispose();
    SettingsService.languageNotifier.removeListener(_onLanguageChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor =
        PokemonTypeColors.getColorByType(widget.pokemon.types.first);
    final screenHeight = MediaQuery.of(context).size.height;
    final cardTop = screenHeight * 0.24;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // SafeArea solo para el contenido
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
            // Círculo grande de transición (del color del tipo pero más claro)
            Positioned(
              top: cardTop - 200,
              left: MediaQuery.of(context).size.width / 2 - 200,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor.withOpacity(0.3),
                ),
              ),
            ),
            // Tarjeta blanca curva
            Positioned(
              top: cardTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildInfoCard(),
            ),
            // Glow de la Pokeball
            Positioned(
              top: cardTop - 300,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 550,
                    height: 480,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: backgroundColor.withOpacity(0.6),
                          blurRadius: 80,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Pokeball de fondo centrada en la división
            Positioned(
              top: cardTop - 210,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Transform.rotate(
                    angle: -40 * 3.14159 / 180,
                    child: Opacity(
                      opacity: 0.15,
                      child: SvgPicture.asset(
                        'assets/icons/pokeball.svg',
                        width: 450,
                        height: 450,
                        fit: BoxFit.cover,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Imagen del Pokémon en la división
            Positioned(
              top: cardTop - 165,
              left: 0,
              right: 0,
              child: _buildPokemonImage(),
            ),
            // Badges de tipos
            Positioned(
              top: cardTop + 178,
              left: 0,
              right: 0,
              child: Center(
                child: Wrap(
                  spacing: 8,
                  children: widget.pokemon.types.map((type) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    decoration: BoxDecoration(
                      color: PokemonTypeColors.getColorByType(type),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      type.capitalize(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),
            // Tab Bar
            Positioned(
              top: cardTop + 225,
              left: 20,
              right: 20,
              child: SizedBox(
                height: 42,
                child: Container(
                  decoration: BoxDecoration(
                    color: PokemonTypeColors.getColorByType(widget.pokemon.types.first).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: PokemonTypeColors.getColorByType(widget.pokemon.types.first),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    labelPadding: EdgeInsets.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    tabs: [
                      Tab(text: SettingsService.tr('about_tab')),
                      Tab(text: SettingsService.tr('stats')),
                      Tab(text: SettingsService.tr('moves')),
                    ],
                  ),
                ),
              ),
            ),
            // Header (al final para que esté encima
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(context, backgroundColor),
            ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 4,
            bottom: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
                _buildBottomNavItem(
                  icon: 'assets/icons/pokemon.svg',
                  label: SettingsService.tr('details'),
                  index: 0,
                ),
                _buildBottomNavItem(
                  icon: 'assets/icons/evolution.svg',
                  label: SettingsService.tr('evolution'),
                  index: 1,
                ),
                _buildBottomNavItem(
                  icon: 'assets/icons/location.svg',
                  label: SettingsService.tr('location'),
                  index: 2,
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required String icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentBottomIndex == index;
    final color = isSelected 
        ? PokemonTypeColors.getColorByType(widget.pokemon.types.first)
        : AppColors.textSecondary.withOpacity(0.5);

    return InkWell(
      onTap: () {
        if (index == 0) {
          // Ya estamos en Details, no hacer nada
          setState(() {
            _currentBottomIndex = 0;
          });
        } else if (index == 1) {
          // Navegar a Evolution
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EvolutionScreen(pokemon: widget.pokemon),
            ),
          );
        } else if (index == 2) {
          // Location - por implementar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(SettingsService.tr('locationSoon'))),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Primera fila: back, título, favorito - todos alineados al centro
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  '${widget.pokemon.capitalizedName} ${widget.pokemon.formattedId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              ScaleTransition(
                scale: _favoriteScaleAnimation,
                child: IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red.shade300 : Colors.white,
                    size: 28,
                  ),
                  onPressed: () async {
                    final newState = await FavoritesService.toggleFavorite(widget.pokemon.id);
                    setState(() {
                      _isFavorite = newState;
                    });
                    if (newState) {
                      _favoriteAnimController.forward(from: 0);
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          // Segunda fila: botones adicionales (shiny y formas) alineados a la derecha
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Shiny toggle
                  IconButton(
                    icon: Icon(
                      _isShiny ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                      color: _isShiny ? Colors.amber : Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _isShiny = !_isShiny;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Shiny',
                  ),
                  // Forms dropdown
                  if (_availableForms.length > 1) ...[
                    const SizedBox(height: 8),
                    PopupMenuButton<Map<String, dynamic>>(
                      icon: const Icon(Icons.style, color: Colors.white, size: 24),
                      padding: EdgeInsets.zero,
                      tooltip: 'Forms',
                      onSelected: (form) {
                        setState(() {
                          _currentPokemonId = form['id'] as int;
                          _currentFormName = form['form_name'] as String? ?? '';
                        });
                      },
                      itemBuilder: (context) => _availableForms.map((form) {
                        final formName = form['form_name'] as String? ?? '';
                        final displayName = formName.isEmpty
                            ? 'Normal'
                            : formName.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
                        return PopupMenuItem<Map<String, dynamic>>(
                          value: form,
                          child: Row(
                            children: [
                              if (_currentPokemonId == form['id'])
                                Icon(Icons.check, size: 18, color: PokemonTypeColors.getColorByType(widget.pokemon.types.first)),
                              if (_currentPokemonId == form['id'])
                                const SizedBox(width: 8),
                              Text(displayName),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPokemonImage() {
    // Build dynamic image URL based on current form and shiny state
    final int displayId = _currentPokemonId > 0 ? _currentPokemonId : widget.pokemon.id;
    final String baseUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon';
    final String imageUrl = _isShiny
        ? '$baseUrl/shiny/$displayId.png'
        : '$baseUrl/$displayId.png';
    
    return Hero(
      tag: 'pokemon_${widget.pokemon.id}',
      child: Center(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          height: 350,
          width: 350,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (context, url, error) => const Icon(
            Icons.catching_pokemon,
            size: 480,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 265),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildStatsTab(),
                _buildMovesTab(),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          // Descripción
          _isLoadingDescription
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Text(
                  _description ?? SettingsService.tr('noDescription'),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withOpacity(0.7),
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                ),
          const SizedBox(height: 20),
          // Height & Weight
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  SettingsService.tr('height'),
                  widget.pokemon.heightInFeet,
                  widget.pokemon.heightInMeters,
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                child: _buildStatItem(
                  SettingsService.tr('weight'),
                  widget.pokemon.weightInLbs,
                  widget.pokemon.weightInKg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Strong against
          Text(
            SettingsService.tr('strongAgainst'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _isLoadingTypes
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : _strongAgainstTypes.isEmpty
                  ? Text(
                      SettingsService.tr('noSuperEffective'),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _strongAgainstTypes.map((type) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: PokemonTypeColors.getColorByType(type),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type.capitalize(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
          const SizedBox(height: 24),
          // Type Matchups section
          _buildTypeMatchupsSection(),
          const SizedBox(height: 24),
          // Abilities section
          Text(
            SettingsService.tr('abilities'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _isLoadingAbilities
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : _abilities.isEmpty
                  ? Text(
                      SettingsService.tr('noAbilities'),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Column(
                      children: _abilities.map((ability) {
                        final name = (ability['name'] as String)
                            .split('-')
                            .map((word) => word[0].toUpperCase() + word.substring(1))
                            .join(' ');
                        final isHidden = ability['isHidden'] as bool;
                        final shortEffect = ability['shortEffect'] as String;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isHidden
                                ? Colors.purple.withOpacity(0.1)
                                : PokemonTypeColors.getColorByType(widget.pokemon.types.first).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isHidden
                                  ? Colors.purple.withOpacity(0.3)
                                  : PokemonTypeColors.getColorByType(widget.pokemon.types.first).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isHidden)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        SettingsService.tr('hidden'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                shortEffect,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTypeMatchupsSection() {
    final matchups = TypeEffectiveness.getGroupedDefensiveMatchups(widget.pokemon.types);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // x4 Weaknesses
        if (matchups[4.0]!.isNotEmpty) ...[
          _buildMatchupRow(SettingsService.tr('weakX4'), matchups[4.0]!, Colors.red.shade700),
          const SizedBox(height: 12),
        ],
        // x2 Weaknesses
        if (matchups[2.0]!.isNotEmpty) ...[
          _buildMatchupRow(SettingsService.tr('weakX2'), matchups[2.0]!, Colors.orange.shade600),
          const SizedBox(height: 12),
        ],
        // x0.5 Resistances
        if (matchups[0.5]!.isNotEmpty) ...[
          _buildMatchupRow(SettingsService.tr('resistX2'), matchups[0.5]!, Colors.green.shade600),
          const SizedBox(height: 12),
        ],
        // x0.25 Resistances
        if (matchups[0.25]!.isNotEmpty) ...[
          _buildMatchupRow(SettingsService.tr('resistX4'), matchups[0.25]!, Colors.green.shade800),
          const SizedBox(height: 12),
        ],
        // x0 Immunities
        if (matchups[0.0]!.isNotEmpty) ...[
          _buildMatchupRow(SettingsService.tr('immune'), matchups[0.0]!, Colors.grey.shade700),
        ],
        // Show message if no special matchups
        if (matchups[4.0]!.isEmpty && matchups[2.0]!.isEmpty && 
            matchups[0.5]!.isEmpty && matchups[0.25]!.isEmpty && matchups[0.0]!.isEmpty)
          Text(
            SettingsService.tr('noTypeMatchups'),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildMatchupRow(String label, List<String> types, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: types.map((type) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: PokemonTypeColors.getColorByType(type),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                type[0].toUpperCase() + type.substring(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    //print('Pokemon stats: ${widget.pokemon.stats}');
    if (widget.pokemon.stats == null) {
      return Center(
        child: Text(SettingsService.tr('noStatsAvailable')),
      );
    }

    final stats = widget.pokemon.stats!;
    //print('Stats values - HP: ${stats.hp}, ATK: ${stats.attack}, DEF: ${stats.defense}');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        children: [
          _buildStatRow('HP', stats.hp, const Color(0xFFFF5959)),
          const SizedBox(height: 16),
          _buildStatRow('ATK', stats.attack, const Color(0xFFF5AC78)),
          const SizedBox(height: 16),
          _buildStatRow('DEF', stats.defense, const Color(0xFFFAE078)),
          const SizedBox(height: 16),
          _buildStatRow('SATK', stats.specialAttack, const Color(0xFF9DB7F5)),
          const SizedBox(height: 16),
          _buildStatRow('SDEF', stats.specialDefense, const Color(0xFFA7DB8D)),
          const SizedBox(height: 16),
          _buildStatRow('SPD', stats.speed, const Color(0xFFFA92B2)),
          const SizedBox(height: 30),
          // Radar Chart
          Text(
            SettingsService.tr('statsOverview'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildRadarChart(stats),
        ],
      ),
    );
  }

  Widget _buildRadarChart(PokemonStatsDTO stats) {
    final pokemonColor = PokemonTypeColors.getColorByType(widget.pokemon.types.first);
    final maxStat = 255.0;

    return SizedBox(
      height: 180,
      child: RadarChart(
        RadarChartData(
          radarBorderData: BorderSide(color: Colors.grey.shade300, width: 1),
          gridBorderData: BorderSide(color: Colors.grey.shade200, width: 1),
          tickBorderData: BorderSide(color: Colors.transparent),
          tickCount: 5,
          ticksTextStyle: const TextStyle(fontSize: 0),
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          radarShape: RadarShape.polygon,
          getTitle: (index, angle) {
            switch (index) {
              case 0: return RadarChartTitle(text: 'HP');
              case 1: return RadarChartTitle(text: 'ATK');
              case 2: return RadarChartTitle(text: 'DEF');
              case 3: return RadarChartTitle(text: 'SATK');
              case 4: return RadarChartTitle(text: 'SDEF');
              case 5: return RadarChartTitle(text: 'SPD');
              default: return const RadarChartTitle(text: '');
            }
          },
          dataSets: [
            RadarDataSet(
              fillColor: pokemonColor.withOpacity(0.3),
              borderColor: pokemonColor,
              borderWidth: 2,
              entryRadius: 4,
              dataEntries: [
                RadarEntry(value: stats.hp / maxStat * 100),
                RadarEntry(value: stats.attack / maxStat * 100),
                RadarEntry(value: stats.defense / maxStat * 100),
                RadarEntry(value: stats.specialAttack / maxStat * 100),
                RadarEntry(value: stats.specialDefense / maxStat * 100),
                RadarEntry(value: stats.speed / maxStat * 100),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color) {
    // El máximo valor de stat es 255
    final double percentage = value / 255;
    
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Stack(
            children: [
              // Barra de fondo gris
              Container(
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              // Barra de progreso con color
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 22,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        SizedBox(
          width: 40,
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildMovesTab() {
    if (_isLoadingMoves) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_moves.isEmpty) {
      return Center(
        child: Text(SettingsService.tr('noMovesAvailable')),
      );
    }

    // Filter moves by selected method
    final filteredMoves = _moves.where((move) {
      final method = move['method'] as String? ?? '';
      return method == _selectedMoveMethod;
    }).toList();

    // Sort moves
    if (_moveSortBy == 'level') {
      filteredMoves.sort((a, b) => (a['level'] as int).compareTo(b['level'] as int));
    } else {
      filteredMoves.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    }

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Method filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _moveMethods.map((method) {
                    final isSelected = _selectedMoveMethod == method;
                    final displayName = _getMethodDisplayName(method);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedMoveMethod = method);
                          }
                        },
                        selectedColor: PokemonTypeColors.getColorByType(widget.pokemon.types.first),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              // Sort buttons
              Row(
                children: [
                  Text(
                    SettingsService.tr('sortBy'),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _moveSortBy = 'level'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _moveSortBy == 'level'
                            ? PokemonTypeColors.getColorByType(widget.pokemon.types.first)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        SettingsService.tr('level'),
                        style: TextStyle(
                          fontSize: 12,
                          color: _moveSortBy == 'level' ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _moveSortBy = 'name'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _moveSortBy == 'name'
                            ? PokemonTypeColors.getColorByType(widget.pokemon.types.first)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        SettingsService.tr('name'),
                        style: TextStyle(
                          fontSize: 12,
                          color: _moveSortBy == 'name' ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${filteredMoves.length} ${SettingsService.tr('moves_count')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Moves list
        Expanded(
          child: filteredMoves.isEmpty
              ? Center(
                  child: Text(
                    'No ${_getMethodDisplayName(_selectedMoveMethod)} moves',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredMoves.length,
                  itemBuilder: (context, index) => _buildMoveCard(filteredMoves[index]),
                ),
        ),
      ],
    );
  }

  String _getMethodDisplayName(String method) {
    switch (method) {
      case 'level-up':
        return SettingsService.tr('levelUp');
      case 'machine':
        return SettingsService.tr('tmhm');
      case 'tutor':
        return SettingsService.tr('tutor');
      case 'egg':
        return SettingsService.tr('egg');
      default:
        return method[0].toUpperCase() + method.substring(1);
    }
  }

  Widget _buildMoveCard(Map<String, dynamic> move) {
    final moveName = (move['name'] as String)
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    final moveType = move['type'] as String?;
    final movePower = move['power'];
    final moveAccuracy = move['accuracy'];
    final movePP = move['pp'];
    final damageClass = move['damageClass'] as String?;
    final level = move['level'] as int? ?? 0;
    final method = move['method'] as String? ?? '';

    final typeColor = moveType != null
        ? PokemonTypeColors.getColorByType(moveType)
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: typeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Level badge for level-up moves
                if (method == 'level-up' && level > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Lv$level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    moveName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (moveType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      moveType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (damageClass != null) ...[
                  _buildMoveInfo(
                    'Class',
                    damageClass[0].toUpperCase() + damageClass.substring(1),
                    typeColor,
                  ),
                  const SizedBox(width: 14),
                ],
                if (movePower != null) ...[
                  _buildMoveInfo('Power', movePower.toString(), typeColor),
                  const SizedBox(width: 14),
                ],
                if (moveAccuracy != null) ...[
                  _buildMoveInfo('Acc', '$moveAccuracy%', typeColor),
                  const SizedBox(width: 14),
                ],
                if (movePP != null) _buildMoveInfo('PP', movePP.toString(), typeColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String imperial, String metric) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          imperial,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          metric,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeIcon(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}

// Clipper para crear una fokin media luna en la parte superior de la tarjeta blanca
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Comenzar desde arriba a la izquierda
    path.lineTo(0, 40);
    
    // Crear curva de ola suave
    var firstControlPoint = Offset(size.width / 4, 0);
    var firstEndPoint = Offset(size.width / 2, 0);


    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    
    var secondControlPoint = Offset(size.width * 3 / 4, 0);
    var secondEndPoint = Offset(size.width, 40);
    
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    
    // Completar el rectángulo
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
