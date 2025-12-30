import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/pokemon_service.dart';
import '../services/settings_service.dart';
import '../utils/colors.dart';

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({Key? key}) : super(key: key);

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> 
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  
  int _score = 0;
  int _totalQuestions = 0;
  int? _correctPokemonId;
  String? _correctPokemonName;
  List<Map<String, dynamic>> _options = [];
  bool _isLoading = true;
  bool _hasAnswered = false;
  int? _selectedOptionIndex;
  bool _isCorrect = false;
  
  late AnimationController _revealController;
  late Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeInOut,
    );
    _loadNewQuestion();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _loadNewQuestion() async {
    setState(() {
      _isLoading = true;
      _hasAnswered = false;
      _selectedOptionIndex = null;
      _options = [];
    });
    _revealController.reset();

    try {
      // Get 4 random Pokemon IDs (1-1025)
      Set<int> randomIds = {};
      while (randomIds.length < 4) {
        randomIds.add(_random.nextInt(1025) + 1);
      }

      final idsString = randomIds.join(', ');
      final query = '''
        query GetRandomPokemons {
          pokemon_v2_pokemon(where: {id: {_in: [$idsString]}, is_default: {_eq: true}}) {
            id
            name
          }
        }
      ''';

      final QueryOptions options = QueryOptions(
        document: gql(query),
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final result = await PokemonService.client.value.query(options);

      if (!result.hasException && result.data != null) {
        final List<dynamic> pokemonList = result.data?['pokemon_v2_pokemon'] ?? [];
        
        if (pokemonList.length >= 4) {
          // Create list of options
          final optionsList = List<Map<String, dynamic>>.from(
            pokemonList.map((p) => {'id': p['id'], 'name': p['name']})
          );

          // Pick a random correct answer FIRST
          final correctIndex = _random.nextInt(optionsList.length);
          final correct = optionsList[correctIndex];
          
          // Then shuffle options for display
          optionsList.shuffle(_random);
          
          setState(() {
            _correctPokemonId = correct['id'];
            _correctPokemonName = correct['name'];
            _options = optionsList;
            _isLoading = false;
          });
        } else {
          // Retry if we didn't get enough Pokemon
          _loadNewQuestion();
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading trivia: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectAnswer(int index) {
    if (_hasAnswered) return;

    final selectedPokemon = _options[index];
    final isCorrect = selectedPokemon['id'] == _correctPokemonId;

    setState(() {
      _hasAnswered = true;
      _selectedOptionIndex = index;
      _isCorrect = isCorrect;
      _totalQuestions++;
      if (isCorrect) {
        _score++;
      }
    });

    _revealController.forward();
  }

  String _capitalize(String name) {
    return name[0].toUpperCase() + name.substring(1);
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
              child: Row(
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
                  Expanded(
                    child: Text(
                      SettingsService.tr('whosThat'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Score badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '$_score/$_totalQuestions',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _correctPokemonId == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                SettingsService.tr('errorLoading'),
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadNewQuestion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                ),
                                child: Text(SettingsService.tr('tryAgain'), style: const TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : _buildQuizContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizContent() {
    return Column(
      children: [
        // Pokemon silhouette area
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Question mark background
                if (!_hasAnswered)
                  Positioned(
                    right: 20,
                    top: 20,
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.withOpacity(0.15),
                      ),
                    ),
                  ),
                // Pokemon image (silhouette or revealed)
                AnimatedBuilder(
                  animation: _revealAnimation,
                  builder: (context, child) {
                    return ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color.lerp(
                          AppColors.textPrimary,
                          Colors.transparent,
                          _revealAnimation.value,
                        )!,
                        BlendMode.srcATop,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$_correctPokemonId.png',
                        height: 220,
                        width: 220,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => CachedNetworkImage(
                          imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$_correctPokemonId.png',
                          height: 180,
                          width: 180,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    );
                  },
                ),
                // Answer feedback
                if (_hasAnswered)
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _isCorrect ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isCorrect 
                            ? "${SettingsService.tr('correct')} ${_capitalize(_correctPokemonName!)}"
                            : "${SettingsService.tr('itsName')} ${_capitalize(_correctPokemonName!)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Options
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: _options.length,
            itemBuilder: (context, index) {
              final option = _options[index];
              final isCorrectOption = option['id'] == _correctPokemonId;
              final isSelected = _selectedOptionIndex == index;
              
              Color buttonColor = Colors.amber.shade600;
              Color textColor = Colors.white;
              
              if (_hasAnswered) {
                if (isCorrectOption) {
                  buttonColor = Colors.green;
                } else if (isSelected) {
                  buttonColor = Colors.red;
                } else {
                  buttonColor = Colors.grey.shade300;
                  textColor = AppColors.textSecondary;
                }
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Material(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(16),
                  elevation: isSelected ? 8 : 2,
                  child: InkWell(
                    onTap: _hasAnswered ? null : () => _selectAnswer(index),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        _capitalize(option['name']),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // Next button
        if (_hasAnswered)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loadNewQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      SettingsService.tr('nextPokemon'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
