import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon.dart';
import '../utils/colors.dart';
import '../services/pokemon_service.dart';
import 'evolution_screen.dart';

class PokemonDetailScreen extends StatefulWidget {
  final Pokemon pokemon;

  const PokemonDetailScreen({
    Key? key,
    required this.pokemon,
  }) : super(key: key);

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _description;
  bool _isLoadingDescription = true;
  List<String> _strongAgainstTypes = [];
  bool _isLoadingTypes = true;
  List<Map<String, dynamic>> _moves = [];
  bool _isLoadingMoves = true;
  int _currentBottomIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDescription();
    _loadStrongAgainstTypes();
    _loadMoves();
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

  @override
  void dispose() {
    _tabController.dispose();
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
            // Tarjeta blanca con información CON CURVA
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
            // Badges de tipos (encima de todo)
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
            // Tab Bar (encima de todo)
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
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Stats'),
                      Tab(text: 'Moves'),
                    ],
                  ),
                ),
              ),
            ),
            // Header (al final para que esté encima de todo)
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
                  label: 'Details',
                  index: 0,
                ),
                _buildBottomNavItem(
                  icon: 'assets/icons/evolution.svg',
                  label: 'Evolution',
                  index: 1,
                ),
                _buildBottomNavItem(
                  icon: 'assets/icons/location.svg',
                  label: 'Location',
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
            const SnackBar(content: Text('Location coming soon...')),
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
          // Botón back y número en la misma línea con el nombre
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                '${widget.pokemon.capitalizedName} ${widget.pokemon.formattedId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 28), // Para balancear con el botón
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPokemonImage() {
    return Hero(
      tag: 'pokemon_${widget.pokemon.id}',
      child: Center(
        child: CachedNetworkImage(
          imageUrl: widget.pokemon.imageUrl,
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
                  _description ?? 'No description available.',
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
                  'Height',
                  widget.pokemon.heightInFeet,
                  widget.pokemon.heightInMeters,
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                child: _buildStatItem(
                  'Weight',
                  widget.pokemon.weightInLbs,
                  widget.pokemon.weightInKg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Strong against
          Text(
            'Strong against',
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
                      'No super effective types',
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    //print('Pokemon stats: ${widget.pokemon.stats}');
    if (widget.pokemon.stats == null) {
      return const Center(
        child: Text('No stats available'),
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
        ],
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
      return const Center(
        child: Text('No moves available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _moves.length,
      itemBuilder: (context, index) {
        final move = _moves[index];
        final moveName = (move['name'] as String)
            .split('-')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
        final moveType = move['type'] as String?;
        final movePower = move['power'];
        final moveAccuracy = move['accuracy'];
        final movePP = move['pp'];
        final damageClass = move['damageClass'] as String?;

        final typeColor = moveType != null 
            ? PokemonTypeColors.getColorByType(moveType)
            : Colors.grey;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: typeColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        moveName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (moveType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          moveType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (damageClass != null) ...[
                      _buildMoveInfo(
                        'Class',
                        damageClass[0].toUpperCase() + damageClass.substring(1),
                        typeColor,
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (movePower != null) ...[
                      _buildMoveInfo(
                        'Power',
                        movePower.toString(),
                        typeColor,
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (moveAccuracy != null) ...[
                      _buildMoveInfo(
                        'Accuracy',
                        '$moveAccuracy%',
                        typeColor,
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (movePP != null)
                      _buildMoveInfo(
                        'PP',
                        movePP.toString(),
                        typeColor,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

// Clipper para crear una ola en la parte superior de la tarjeta blanca
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
