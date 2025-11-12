import 'package:flutter/material.dart';
import '../utils/colors.dart';

class FilterScreen extends StatefulWidget {
  final Map<String, dynamic> currentFilters;

  const FilterScreen({Key? key, required this.currentFilters}) : super(key: key);

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late Set<String> selectedTypes;
  late Set<int> selectedGenerations;
  late RangeValues heightRange;
  late RangeValues weightRange;

  final List<String> pokemonTypes = [
    'normal', 'fire', 'water', 'electric', 'grass', 'ice',
    'fighting', 'poison', 'ground', 'flying', 'psychic', 'bug',
    'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy'
  ];

  final List<Map<String, dynamic>> generations = [
    {'id': 1, 'name': 'Generation I', 'range': '1-151'},
    {'id': 2, 'name': 'Generation II', 'range': '152-251'},
    {'id': 3, 'name': 'Generation III', 'range': '252-386'},
    {'id': 4, 'name': 'Generation IV', 'range': '387-493'},
    {'id': 5, 'name': 'Generation V', 'range': '494-649'},
    {'id': 6, 'name': 'Generation VI', 'range': '650-721'},
    {'id': 7, 'name': 'Generation VII', 'range': '722-809'},
    {'id': 8, 'name': 'Generation VIII', 'range': '810-905'},
  ];

  @override
  void initState() {
    super.initState();
    selectedTypes = Set<String>.from(widget.currentFilters['types'] ?? []);
    selectedGenerations = Set<int>.from(widget.currentFilters['generations'] ?? []);
    heightRange = widget.currentFilters['heightRange'] ?? const RangeValues(0, 200);
    weightRange = widget.currentFilters['weightRange'] ?? const RangeValues(0, 1000);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Filters',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              'Reset',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Types'),
                  const SizedBox(height: 12),
                  _buildTypeGrid(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Generations'),
                  const SizedBox(height: 12),
                  _buildGenerationsList(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Height Range (dm)'),
                  _buildRangeSlider(
                    'Height',
                    heightRange,
                    0,
                    200,
                    (values) => setState(() => heightRange = values),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Weight Range (hg)'),
                  _buildRangeSlider(
                    'Weight',
                    weightRange,
                    0,
                    1000,
                    (values) => setState(() => weightRange = values),
                  ),
                ],
              ),
            ),
          ),
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTypeGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: pokemonTypes.map((type) {
        final isSelected = selectedTypes.contains(type);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedTypes.remove(type);
              } else {
                selectedTypes.add(type);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? PokemonTypeColors.getColorByType(type)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? PokemonTypeColors.getColorByType(type)
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Text(
              type[0].toUpperCase() + type.substring(1),
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenerationsList() {
    return Column(
      children: generations.map((gen) {
        final isSelected = selectedGenerations.contains(gen['id']);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedGenerations.remove(gen['id']);
                } else {
                  selectedGenerations.add(gen['id']);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gen['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${gen['range']}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: Colors.blue),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRangeSlider(
    String label,
    RangeValues values,
    double min,
    double max,
    Function(RangeValues) onChanged,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${values.start.round()}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            Text(
              '${values.end.round()}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: Colors.blue,
          inactiveColor: Colors.blue.withOpacity(0.2),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    final hasFilters = selectedTypes.isNotEmpty ||
        selectedGenerations.isNotEmpty ||
        heightRange != const RangeValues(0, 200) ||
        weightRange != const RangeValues(0, 1000);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              hasFilters
                  ? 'Apply Filters (${_getFilterCount()})'
                  : 'Apply Filters',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _getFilterCount() {
    int count = 0;
    if (selectedTypes.isNotEmpty) count++;
    if (selectedGenerations.isNotEmpty) count++;
    if (heightRange != const RangeValues(0, 200)) count++;
    if (weightRange != const RangeValues(0, 1000)) count++;
    return count;
  }

  void _resetFilters() {
    setState(() {
      selectedTypes.clear();
      selectedGenerations.clear();
      heightRange = const RangeValues(0, 200);
      weightRange = const RangeValues(0, 1000);
    });
  }

  void _applyFilters() {
    Navigator.pop(context, {
      'types': selectedTypes.toList(),
      'generations': selectedGenerations.toList(),
      'heightRange': heightRange,
      'weightRange': weightRange,
    });
  }
}
