# 📱 Pokédex App

Una aplicación móvil desarrollada en Flutter que permite explorar y obtener información detallada sobre diferentes especies de Pokémon utilizando la API GraphQL de PokeAPI.

## 🚀 Características Implementadas

### ✅ Fase 1 - Pantalla Principal (HOME)
- **Lista de Pokémon**: Grid responsive con tarjetas de Pokémon
- **Barra de búsqueda**: Búsqueda en tiempo real por nombre
- **Diseño intuitivo**: Interfaz basada en Material Design 3
- **Carga progresiva**: Infinite scroll para cargar más Pokémon
- **Tarjetas con colores**: Cada tarjeta tiene el color del tipo principal del Pokémon
- **Imágenes oficiales**: Sprites de alta calidad desde PokeAPI

## 🛠 Tecnologías Utilizadas

- **Flutter**: Framework de desarrollo móvil multiplataforma
- **Dart**: Lenguaje de programación
- **GraphQL**: Para consultas eficientes a la API
- **PokeAPI (GraphQL)**: `https://beta.pokeapi.co/graphql/v1beta`
- **Paquetes principales**:
  - `graphql_flutter`: Cliente GraphQL para Flutter
  - `cached_network_image`: Caché de imágenes para mejor rendimiento

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                  # Punto de entrada de la aplicación
├── models/
│   └── pokemon.dart          # Modelo de datos de Pokémon
├── screens/
│   └── home_screen.dart      # Pantalla principal con lista
├── widgets/
│   └── pokemon_card.dart     # Widget reutilizable de tarjeta
├── services/
│   └── pokemon_service.dart  # Servicio GraphQL para API
└── utils/
    └── colors.dart           # Colores por tipo de Pokémon

assets/
├── images/                    # Imágenes de la app
└── icons/                     # Iconos personalizados
```

## 🎨 Decisiones de Diseño

### Arquitectura
- **Patrón de widgets reutilizables**: Separación clara entre componentes
- **Modelo de datos**: Clase `Pokemon` con factory constructor para parsear JSON
- **Servicio centralizado**: `PokemonService` maneja todas las consultas GraphQL

### Interfaz de Usuario
1. **Colores dinámicos**: Cada tipo de Pokémon tiene su color característico
2. **Grid responsive**: 2 columnas con aspect ratio 0.75
3. **Search bar**: Con icono de búsqueda y botón de filtros (próximamente)
4. **Hero animations**: Preparado para transiciones entre pantallas

### Consultas GraphQL

#### Query para obtener lista de Pokémon:
```graphql
query GetPokemons($limit: Int!, $offset: Int!) {
  pokemon_v2_pokemon(limit: $limit, offset: $offset, order_by: {id: asc}) {
    id
    name
    pokemon_v2_pokemontypes {
      pokemon_v2_type {
        name
      }
    }
  }
}
```

#### Query para búsqueda:
```graphql
query SearchPokemon($name: String!) {
  pokemon_v2_pokemon(where: {name: {_ilike: $name}}, order_by: {id: asc}) {
    id
    name
    pokemon_v2_pokemontypes {
      pokemon_v2_type {
        name
      }
    }
  }
}
```

## 🚀 Cómo Ejecutar el Proyecto

### Requisitos Previos
- Flutter SDK (>= 3.9.2)
- Dart SDK
- Android Studio / Xcode (para emuladores)
- Editor: VS Code o Android Studio

### Instalación

1. Clonar el repositorio
```bash
git clone <url-del-repo>
cd Pokedex
```

2. Instalar dependencias
```bash
flutter pub get
```

3. Ejecutar la aplicación
```bash
flutter run
```

## 📝 Próximas Características

- [ ] Pantalla de detalle de Pokémon
- [ ] Sistema de filtrado por tipo y generación
- [ ] Animaciones y transiciones
- [ ] Favoritos
- [ ] Modo offline con caché

## 👥 Equipo de Desarrollo

- Desarrollador: [Tu Nombre]
- Curso: Desarrollo Móvil - PUCMM
- Fecha: Noviembre 2025

## 📄 Licencia

Este proyecto es parte de un trabajo académico para PUCMM.
