import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'settings_service.dart';
import '../models/pokemon_dto.dart';

class PokemonService {
  static HttpLink httpLink = HttpLink(
    'https://beta.pokeapi.co/graphql/v1beta',
  );

  static ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    ),
  );

  static const String _pokemonsQuery = r'''
    query GetPokemons($limit: Int!, $offset: Int!) {
      pokemon_v2_pokemon(
        limit: $limit, 
        offset: $offset, 
        order_by: {id: asc},
        where: {id: {_lte: 1025}, is_default: {_eq: true}}
      ) {
        id
        name
        height
        weight
        pokemon_v2_pokemontypes {
          pokemon_v2_type {
            name
          }
        }
        pokemon_v2_pokemonstats {
          stat_id
          base_stat
        }
      }
    }
  ''';

  static const String _searchPokemonQuery = r'''
    query SearchPokemon($name: String!) {
      pokemon_v2_pokemon(where: {name: {_ilike: $name}}, order_by: {id: asc}) {
        id
        name
        height
        weight
        pokemon_v2_pokemontypes {
          pokemon_v2_type {
            name
          }
        }
        pokemon_v2_pokemonstats {
          stat_id
          base_stat
        }
      }
    }
  ''';

  /// Fetch paginated list of Pokemon
  static Future<List<PokemonDTO>> getPokemons({
    required int limit,
    required int offset,
  }) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(_pokemonsQuery),
        variables: {'limit': limit, 'offset': offset},
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await client.value.query(options);

      if (result.hasException) {
        print('Error fetching pokemons: ${result.exception}');
        return [];
      }

      final List<dynamic> pokemonList = result.data?['pokemon_v2_pokemon'] ?? [];
      return pokemonList.map((json) => PokemonDTO.fromJson(json)).toList();
    } catch (e) {
      print('Exception fetching pokemons: $e');
      return [];
    }
  }

  /// Search Pokemon by name
  static Future<List<PokemonDTO>> searchPokemons(String searchQuery) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(_searchPokemonQuery),
        variables: {'name': '%$searchQuery%'},
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await client.value.query(options);

      if (result.hasException) {
        print('Error searching pokemons: ${result.exception}');
        return [];
      }

      final List<dynamic> pokemonList = result.data?['pokemon_v2_pokemon'] ?? [];
      return pokemonList.map((json) => PokemonDTO.fromJson(json)).toList();
    } catch (e) {
      print('Exception searching pokemons: $e');
      return [];
    }
  }

  /// Get Pokemon by list of IDs (for favorites)
  static Future<List<PokemonDTO>> getPokemonsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    
    try {
      final idsString = ids.join(', ');
      final query = '''
        query GetPokemonsByIds {
          pokemon_v2_pokemon(where: {id: {_in: [$idsString]}}, order_by: {id: asc}) {
            id
            name
            height
            weight
            pokemon_v2_pokemontypes {
              pokemon_v2_type {
                name
              }
            }
            pokemon_v2_pokemonstats {
              stat_id
              base_stat
            }
          }
        }
      ''';

      final QueryOptions options = QueryOptions(
        document: gql(query),
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await client.value.query(options);

      if (result.hasException) {
        print('Error fetching pokemons by ids: ${result.exception}');
        return [];
      }

      final List<dynamic> pokemonList = result.data?['pokemon_v2_pokemon'] ?? [];
      return pokemonList.map((json) => PokemonDTO.fromJson(json)).toList();
    } catch (e) {
      print('Exception fetching pokemons by ids: $e');
      return [];
    }
  }

  /// Get filtered Pokemon
  static Future<List<PokemonDTO>> getFilteredPokemons({
    required List<String> types,
    required List<int> generations,
    required double minHeight,
    required double maxHeight,
    required double minWeight,
    required double maxWeight,
  }) async {
    try {
      final query = _buildFilteredQuery(
        types, generations, minHeight, maxHeight, minWeight, maxWeight,
      );

      final QueryOptions options = QueryOptions(
        document: gql(query),
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await client.value.query(options);

      if (result.hasException) {
        print('Error fetching filtered pokemons: ${result.exception}');
        return [];
      }

      final List<dynamic> pokemonList = result.data?['pokemon_v2_pokemon'] ?? [];
      return pokemonList.map((json) => PokemonDTO.fromJson(json)).toList();
    } catch (e) {
      print('Exception fetching filtered pokemons: $e');
      return [];
    }
  }

  static String _buildFilteredQuery(
    List<String> types,
    List<int> generations,
    double minHeight,
    double maxHeight,
    double minWeight,
    double maxWeight,
  ) {
    List<String> conditions = [];

    // Type filter
    if (types.isNotEmpty) {
      final typeConditions = types.map((type) => 
        'pokemon_v2_pokemontypes: {pokemon_v2_type: {name: {_eq: "$type"}}}'
      ).join(', ');
      conditions.add('_and: [{$typeConditions}]');
    }

    // Generation filter (based on ID ranges)
    if (generations.isNotEmpty) {
      List<String> idRanges = [];
      for (int gen in generations) {
        switch (gen) {
          case 1: idRanges.add('{id: {_gte: 1, _lte: 151}}'); break;
          case 2: idRanges.add('{id: {_gte: 152, _lte: 251}}'); break;
          case 3: idRanges.add('{id: {_gte: 252, _lte: 386}}'); break;
          case 4: idRanges.add('{id: {_gte: 387, _lte: 493}}'); break;
          case 5: idRanges.add('{id: {_gte: 494, _lte: 649}}'); break;
          case 6: idRanges.add('{id: {_gte: 650, _lte: 721}}'); break;
          case 7: idRanges.add('{id: {_gte: 722, _lte: 809}}'); break;
          case 8: idRanges.add('{id: {_gte: 810, _lte: 905}}'); break;
        }
      }
      if (idRanges.isNotEmpty) {
        conditions.add('_or: [${idRanges.join(', ')}]');
      }
    }

    // Height filter
    if (minHeight > 0 || maxHeight < 200) {
      conditions.add('height: {_gte: ${minHeight.round()}, _lte: ${maxHeight.round()}}');
    }

    // Weight filter
    if (minWeight > 0 || maxWeight < 1000) {
      conditions.add('weight: {_gte: ${minWeight.round()}, _lte: ${maxWeight.round()}}');
    }

    String whereClause = conditions.isNotEmpty ? 'where: {${conditions.join(', ')}}' : '';

    return '''
      query GetFilteredPokemons {
        pokemon_v2_pokemon($whereClause, order_by: {id: asc}, limit: 500) {
          id
          name
          height
          weight
          pokemon_v2_pokemontypes {
            pokemon_v2_type {
              name
            }
          }
          pokemon_v2_pokemonstats {
            stat_id
            base_stat
          }
        }
      }
    ''';
  }

  /// Get a single Pokemon by ID
  static Future<PokemonDTO?> getPokemonById(int id) async {
    try {
      final pokemons = await getPokemonsByIds([id]);
      return pokemons.isNotEmpty ? pokemons.first : null;
    } catch (e) {
      print('Exception fetching pokemon by id: $e');
      return null;
    }
  }

  /// Get a single Pokemon by exact name
  static Future<PokemonDTO?> getPokemonByName(String name) async {
    try {
      final query = r'''
        query GetPokemonByName($name: String!) {
          pokemon_v2_pokemon(where: {name: {_eq: $name}}) {
            id
            name
            height
            weight
            pokemon_v2_pokemontypes {
              pokemon_v2_type {
                name
              }
            }
            pokemon_v2_pokemonstats {
              stat_id
              base_stat
            }
          }
        }
      ''';

      final QueryOptions options = QueryOptions(
        document: gql(query),
        variables: {'name': name},
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await client.value.query(options);

      if (result.hasException) {
        print('Error fetching pokemon by name: ${result.exception}');
        return null;
      }

      final List<dynamic> pokemonList = result.data?['pokemon_v2_pokemon'] ?? [];
      return pokemonList.isNotEmpty ? PokemonDTO.fromJson(pokemonList.first) : null;
    } catch (e) {
      print('Exception fetching pokemon by name: $e');
      return null;
    }
  }

  static String getPokemonDescriptionQuery(int languageId) {
    return '''
      query GetPokemonDescription(\$id: Int!) {
        pokemon_v2_pokemonspecies(where: {id: {_eq: \$id}}) {
          pokemon_v2_pokemonspeciesflavortexts(
            where: {language_id: {_eq: $languageId}}
            order_by: {version_id: desc}
            limit: 1
          ) {
            flavor_text
          }
        }
      }
    ''';
  }

  static Future<String?> getPokemonDescription(int pokemonId) async {
    try {
      final languageId = SettingsService.currentLanguageId;
      final QueryOptions options = QueryOptions(
        document: gql(getPokemonDescriptionQuery(languageId)),
        variables: {'id': pokemonId},
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await client.value.query(options);

      if (result.hasException) {
        print('Error fetching description: ${result.exception.toString()}');
        return null;
      }

      final species = result.data?['pokemon_v2_pokemonspecies'] as List?;
      if (species != null && species.isNotEmpty) {
        final flavorTexts = species[0]['pokemon_v2_pokemonspeciesflavortexts'] as List?;
        if (flavorTexts != null && flavorTexts.isNotEmpty) {
          final flavorText = flavorTexts[0]['flavor_text'] as String?;
          // Limpiar el texto (remover saltos de línea y caracteres especiales)
          return flavorText
              ?.replaceAll('\n', ' ')
              ?.replaceAll('\f', ' ')
              ?.replaceAll('  ', ' ')
              ?.trim();
        }
      }

      return null;
    } catch (e) {
      print('Exception fetching description: $e');
      return null;
    }
  }

  static const String getTypeDamageRelationsQuery = r'''
    query GetTypeDamageRelations($typeName: String!) {
      pokemon_v2_type(where: {name: {_eq: $typeName}}) {
        id
      }
      pokemon_v2_typeefficacy(where: {damage_type_id: {_eq: $typeId}, damage_factor: {_eq: 200}}) {
        target_type_id
        pokemon_v2_typeByTargetTypeId {
          name
        }
      }
    }
  ''';

  static Future<List<String>> getStrongAgainstTypes(List<String> pokemonTypes) async {
    try {
      Set<String> strongAgainst = {};
      
      for (String typeName in pokemonTypes) {
        // First, get the type ID
        final QueryOptions typeIdOptions = QueryOptions(
          document: gql(r'''
            query GetTypeId($typeName: String!) {
              pokemon_v2_type(where: {name: {_eq: $typeName}}) {
                id
              }
            }
          '''),
          variables: {'typeName': typeName},
        );

        final QueryResult typeIdResult = await client.value.query(typeIdOptions);
        
        if (!typeIdResult.hasException && typeIdResult.data != null) {
          final types = typeIdResult.data?['pokemon_v2_type'] as List?;
          if (types != null && types.isNotEmpty) {
            final typeId = types[0]['id'];
            
            // Now get the type efficacies
            final QueryOptions efficacyOptions = QueryOptions(
              document: gql(r'''
                query GetTypeEfficacies($typeId: Int!) {
                  pokemon_v2_typeefficacy(where: {damage_type_id: {_eq: $typeId}, damage_factor: {_eq: 200}}) {
                    target_type_id
                  }
                }
              '''),
              variables: {'typeId': typeId},
            );

            final QueryResult efficacyResult = await client.value.query(efficacyOptions);
            
            if (!efficacyResult.hasException && efficacyResult.data != null) {
              final efficacies = efficacyResult.data?['pokemon_v2_typeefficacy'] as List?;
              if (efficacies != null) {
                // Get the target type IDs and fetch their names
                for (var efficacy in efficacies) {
                  final targetTypeId = efficacy['target_type_id'] as int?;
                  if (targetTypeId != null) {
                    // Fetch the target type name
                    final QueryOptions targetTypeOptions = QueryOptions(
                      document: gql(r'''
                        query GetTargetType($targetTypeId: Int!) {
                          pokemon_v2_type(where: {id: {_eq: $targetTypeId}}) {
                            name
                          }
                        }
                      '''),
                      variables: {'targetTypeId': targetTypeId},
                    );
                    
                    final QueryResult targetTypeResult = await client.value.query(targetTypeOptions);
                    
                    if (!targetTypeResult.hasException && targetTypeResult.data != null) {
                      final targetTypes = targetTypeResult.data?['pokemon_v2_type'] as List?;
                      if (targetTypes != null && targetTypes.isNotEmpty) {
                        final targetTypeName = targetTypes[0]['name'] as String?;
                        if (targetTypeName != null) {
                          strongAgainst.add(targetTypeName);
                        }
                      }
                    }
                  }
                }
              }
            } else {
              print('Error fetching efficacies for type $typeName: ${efficacyResult.exception}');
            }
          }
        } else {
          print('Error fetching type ID for $typeName: ${typeIdResult.exception}');
        }
      }

      return strongAgainst.toList();
    } catch (e) {
      print('Exception fetching type relations: $e');
      return [];
    }
  }

  static const String getPokemonMovesQuery = r'''
    query GetPokemonMoves($pokemonId: Int!) {
      pokemon_v2_pokemonmove(
        where: {pokemon_id: {_eq: $pokemonId}},
        order_by: {level: asc}
      ) {
        level
        pokemon_v2_movelearnmethod {
          name
        }
        pokemon_v2_versiongroup {
          name
          id
        }
        pokemon_v2_move {
          id
          name
          power
          pp
          accuracy
          pokemon_v2_type {
            name
          }
          pokemon_v2_movedamageclass {
            name
          }
        }
      }
    }
  ''';

  static Future<List<Map<String, dynamic>>> getPokemonMoves(int pokemonId) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(getPokemonMovesQuery),
        variables: {'pokemonId': pokemonId},
      );

      final QueryResult result = await client.value.query(options);

      if (!result.hasException && result.data != null) {
        final moves = result.data?['pokemon_v2_pokemonmove'] as List?;
        if (moves != null) {
          // Use a Set to track unique moves (by move id + method + version)
          Set<String> seenMoves = {};
          List<Map<String, dynamic>> uniqueMoves = [];
          
          for (var moveData in moves) {
            final move = moveData['pokemon_v2_move'];
            final moveId = move['id'];
            final method = moveData['pokemon_v2_movelearnmethod']?['name'] as String? ?? 'unknown';
            final versionGroupId = moveData['pokemon_v2_versiongroup']?['id'] ?? 0;
            final level = moveData['level'] as int? ?? 0;
            
            // Create unique key
            final key = '${moveId}_${method}_$versionGroupId';
            
            if (!seenMoves.contains(key)) {
              seenMoves.add(key);
              uniqueMoves.add({
                'id': moveId,
                'name': move['name'] as String,
                'power': move['power'],
                'pp': move['pp'],
                'accuracy': move['accuracy'],
                'type': move['pokemon_v2_type']?['name'] as String?,
                'damageClass': move['pokemon_v2_movedamageclass']?['name'] as String?,
                'level': level,
                'method': method,
                'versionGroup': moveData['pokemon_v2_versiongroup']?['name'] as String? ?? 'unknown',
                'versionGroupId': versionGroupId,
              });
            }
          }
          return uniqueMoves;
        }
      }
      return [];
    } catch (e) {
      print('Exception fetching moves: $e');
      return [];
    }
  }

  static const String getPokemonAbilitiesQuery = r'''
    query GetPokemonAbilities($pokemonId: Int!) {
      pokemon_v2_pokemonability(where: {pokemon_id: {_eq: $pokemonId}}) {
        is_hidden
        pokemon_v2_ability {
          name
          pokemon_v2_abilityeffecttexts(where: {language_id: {_eq: 9}}, limit: 1) {
            short_effect
          }
        }
      }
    }
  ''';

  static Future<List<Map<String, dynamic>>> getPokemonAbilities(int pokemonId) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(getPokemonAbilitiesQuery),
        variables: {'pokemonId': pokemonId},
      );

      final QueryResult result = await client.value.query(options);

      if (!result.hasException && result.data != null) {
        final abilities = result.data?['pokemon_v2_pokemonability'] as List?;
        if (abilities != null) {
          return abilities.map((abilityData) {
            final ability = abilityData['pokemon_v2_ability'];
            final effectTexts = ability['pokemon_v2_abilityeffecttexts'] as List?;
            String shortEffect = 'No effect description available.';
            
            if (effectTexts != null && effectTexts.isNotEmpty) {
              shortEffect = effectTexts[0]['short_effect'] as String? ?? shortEffect;
              // Truncar a máximo 160 caracteres
              if (shortEffect.length > 160) {
                shortEffect = '${shortEffect.substring(0, 157)}...';
              }
            }
            
            return {
              'name': ability['name'] as String,
              'isHidden': abilityData['is_hidden'] as bool,
              'shortEffect': shortEffect,
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Exception fetching abilities: $e');
      return [];
    }
  }

  static const String getPokemonFormsQuery = r'''
    query GetPokemonForms($speciesId: Int!) {
      pokemon_v2_pokemon(where: {pokemon_species_id: {_eq: $speciesId}}, order_by: {id: asc}) {
        id
        name
        is_default
        pokemon_v2_pokemonforms {
          form_name
          name
        }
        pokemon_v2_pokemontypes {
          pokemon_v2_type {
            name
          }
        }
      }
    }
  ''';

  static Future<List<Map<String, dynamic>>> getPokemonForms(int speciesId) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(getPokemonFormsQuery),
        variables: {'speciesId': speciesId},
      );

      final QueryResult result = await client.value.query(options);

      if (!result.hasException && result.data != null) {
        final pokemons = result.data?['pokemon_v2_pokemon'] as List?;
        if (pokemons != null) {
          return pokemons.map((pokemon) {
            final forms = pokemon['pokemon_v2_pokemonforms'] as List?;
            final types = (pokemon['pokemon_v2_pokemontypes'] as List?)
                ?.map((t) => t['pokemon_v2_type']['name'] as String)
                .toList() ?? [];
            
            String formName = '';
            if (forms != null && forms.isNotEmpty) {
              formName = forms[0]['form_name'] as String? ?? '';
            }
            
            return {
              'id': pokemon['id'] as int,
              'name': pokemon['name'] as String,
              'form_name': formName,
              'is_default': pokemon['is_default'] as bool? ?? false,
              'types': types,
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Exception fetching forms: $e');
      return [];
    }
  }

  static String getEvolutionChainQuery = r'''
    query getEvolutionChain($pokemonId: Int!) {
      pokemon_v2_pokemonspecies(where: {id: {_eq: $pokemonId}}) {
        pokemon_v2_evolutionchain {
          pokemon_v2_pokemonspecies(order_by: {order: asc}) {
            id
            name
            order
            evolves_from_species_id
            pokemon_v2_pokemonevolutions {
              min_level
              min_happiness
              time_of_day
              pokemon_v2_evolutiontrigger {
                name
              }
              pokemon_v2_item {
                name
              }
            }
            pokemon_v2_pokemons {
              id
              name
              pokemon_v2_pokemonforms {
                id
                name
                form_name
                pokemon_id
              }
            }
          }
        }
      }
    }
  ''';

  static const String getPokemonByLocationQuery = r'''
    query GetPokemonByLocation($locationName: String!) {
      pokemon_v2_location(where: {name: {_ilike: $locationName}}) {
        id
        name
        pokemon_v2_locationareas {
          pokemon_v2_encounters(distinct_on: pokemon_id) {
            pokemon_id
          }
        }
      }
    }
  ''';

  static Future<List<int>> getPokemonIdsByLocation(String locationName) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(getPokemonByLocationQuery),
        variables: {'locationName': '%$locationName%'},
        fetchPolicy: FetchPolicy.cacheFirst,
      );

      final QueryResult result = await client.value.query(options);

      if (result.hasException) {
        print('Error fetching pokemon by location: ${result.exception}');
        return [];
      }

      final locations = result.data?['pokemon_v2_location'] as List?;
      if (locations == null || locations.isEmpty) return [];

      Set<int> pokemonIds = {};
      for (var location in locations) {
        final areas = location['pokemon_v2_locationareas'] as List?;
        if (areas != null) {
          for (var area in areas) {
            final encounters = area['pokemon_v2_encounters'] as List?;
            if (encounters != null) {
              for (var encounter in encounters) {
                final pokemonId = encounter['pokemon_id'] as int?;
                if (pokemonId != null && pokemonId <= 251) {
                  pokemonIds.add(pokemonId);
                }
              }
            }
          }
        }
      }

      final sortedIds = pokemonIds.toList()..sort();
      return sortedIds.take(10).toList();
    } catch (e) {
      print('Exception fetching pokemon by location: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getEvolutionChain(int pokemonId) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(getEvolutionChainQuery),
        variables: {'pokemonId': pokemonId},
      );

      final QueryResult result = await client.value.query(options);

      if (!result.hasException && result.data != null) {
        final species = result.data?['pokemon_v2_pokemonspecies'] as List?;
        if (species != null && species.isNotEmpty) {
          final evolutionChain = species[0]['pokemon_v2_evolutionchain'];
          if (evolutionChain != null) {
            final chainSpecies = evolutionChain['pokemon_v2_pokemonspecies'] as List;
            
            return chainSpecies.map((speciesData) {
              // Get all forms for this Pokemon
              final pokemons = speciesData['pokemon_v2_pokemons'] as List;
              List<Map<String, dynamic>> forms = [];
              
              if (pokemons.isNotEmpty) {
                for (var pokemon in pokemons) {
                  final pokemonForms = pokemon['pokemon_v2_pokemonforms'] as List;
                  for (var form in pokemonForms) {
                    final formName = form['form_name'] as String?;
                    // Filter out the base form (we'll show it in evolution)
                    if (formName != null && formName.isNotEmpty && formName != 'normal') {
                      forms.add({
                        'id': form['pokemon_id'],
                        'name': form['name'],
                        'form_name': formName,
                      });
                    }
                  }
                }
              }
              
              // Extract evolution details
              final evolutions = speciesData['pokemon_v2_pokemonevolutions'] as List?;
              String triggerDescription = '';
              
              if (evolutions != null && evolutions.isNotEmpty) {
                final evo = evolutions[0];
                final minLevel = evo['min_level'] as int?;
                final minHappiness = evo['min_happiness'] as int?;
                final timeOfDay = evo['time_of_day'] as String?;
                final triggerName = evo['pokemon_v2_evolutiontrigger']?['name'] as String?;
                final itemName = evo['pokemon_v2_item']?['name'] as String?;
                
                if (triggerName != null) {
                  switch (triggerName) {
                    case 'level-up':
                      if (minLevel != null) {
                        triggerDescription = 'Level $minLevel';
                      } else if (minHappiness != null) {
                        triggerDescription = 'Friendship';
                        if (timeOfDay != null && timeOfDay.isNotEmpty) {
                          triggerDescription += ' (${timeOfDay == 'day' ? 'Day' : 'Night'})';
                        }
                      } else if (timeOfDay != null && timeOfDay.isNotEmpty) {
                        triggerDescription = 'Level up (${timeOfDay == 'day' ? 'Day' : 'Night'})';
                      } else {
                        triggerDescription = 'Level up';
                      }
                      break;
                    case 'trade':
                      triggerDescription = 'Trade';
                      if (itemName != null) {
                        final formattedItem = itemName.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
                        triggerDescription += ' ($formattedItem)';
                      }
                      break;
                    case 'use-item':
                      if (itemName != null) {
                        final formattedItem = itemName.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
                        triggerDescription = formattedItem;
                      } else {
                        triggerDescription = 'Use item';
                      }
                      break;
                    default:
                      triggerDescription = triggerName.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
                  }
                }
              }
              
              return {
                'id': speciesData['id'],
                'name': speciesData['name'] as String,
                'order': speciesData['order'],
                'evolves_from': speciesData['evolves_from_species_id'],
                'trigger': triggerDescription,
                'forms': forms,
              };
            }).toList();
          }
        }
      }
      return [];
    } catch (e) {
      print('Exception fetching evolution chain: $e');
      return [];
    }
  }
}
