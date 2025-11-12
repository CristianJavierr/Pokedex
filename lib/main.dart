import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'screens/home_screen.dart';
import 'services/pokemon_service.dart';

void main() async {
  await initHiveForFlutter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: PokemonService.client,
      child: MaterialApp(
        title: 'Pokédex',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.red,
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

