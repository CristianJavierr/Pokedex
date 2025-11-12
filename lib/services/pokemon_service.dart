import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

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

  static const String getPokemonsQuery = r'''
    query GetPokemons($limit: Int!, $offset: Int!) {
      pokemon_v2_pokemon(limit: $limit, offset: $offset, order_by: {id: asc}) {
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

  static const String searchPokemonQuery = r'''
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

  static String getFilteredPokemonsQuery(
    List<String> types,
    List<int> generations,
    double minHeight,
    double maxHeight,
    double minWeight,
    double maxWeight,
  ) {
    String whereClause = '';
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

    if (conditions.isNotEmpty) {
      whereClause = 'where: {${conditions.join(', ')}}';
    }

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

  static const String getPokemonDescriptionQuery = r'''
    query GetPokemonDescription($id: Int!) {
      pokemon_v2_pokemonspecies(where: {id: {_eq: $id}}) {
        pokemon_v2_pokemonspeciesflavortexts(
          where: {language_id: {_eq: 9}}
          order_by: {version_id: desc}
          limit: 1
        ) {
          flavor_text
        }
      }
    }
  ''';

  static Future<String?> getPokemonDescription(int pokemonId) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(getPokemonDescriptionQuery),
        variables: {'id': pokemonId},
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
      pokemon_v2_pokemonmove(where: {pokemon_id: {_eq: $pokemonId}}, limit: 50) {
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
          return moves.map((moveData) {
            final move = moveData['pokemon_v2_move'];
            return {
              'id': move['id'],
              'name': move['name'] as String,
              'power': move['power'],
              'pp': move['pp'],
              'accuracy': move['accuracy'],
              'type': move['pokemon_v2_type']?['name'] as String?,
              'damageClass': move['pokemon_v2_movedamageclass']?['name'] as String?,
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Exception fetching moves: $e');
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
              
              return {
                'id': speciesData['id'],
                'name': speciesData['name'] as String,
                'order': speciesData['order'],
                'evolves_from': speciesData['evolves_from_species_id'],
                'min_level': null,
                'trigger': 'level-up',
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
