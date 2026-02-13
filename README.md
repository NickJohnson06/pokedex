# Personal Pokedex App

A feature-rich, Pokedex application built with Flutter that allows you to manage your own Pokemon collection. It combines local data management with remote PokeAPI integration to provide a seamless experience.

## Features

### 🔍 **Extensive Browsing & Search**
- **Smart Search**: Find Pokemon by Name, Type (e.g. "Fire"), or Dex Number (e.g. "#004").
- **Advanced Filtering**: Filter by Generation (Gen 1-9), Type, and Favorites.
- **Flexible Sorting**: Sort your collection by Dex Number, Name, Type, or Favorites (Ascending/Descending).
- **View Options**: Toggle between List and Grid views for your preferred browsing style.

### 📝 **Collection Management**
- **Catch 'Em All**: Add new Pokemon to your personal collection.
- **Edit & Collaborate**: Update details or release Pokemon (delete).
- **Favorites**: Star your favorite Pokemon for quick access.
- **Persistence**: All data is saved locally using SQLite (`sqflite`), so your collection is always available offline.

### 🎨 **Beautiful & Dynamic UI**
- **Dynamic Theming**: The app's color scheme adapts to the type of the Pokemon (e.g., Red for Fire, Blue for Water).
- **Dark Mode Support**: Fully optimized for both Light and Dark themes.
- **Hero Animations**: Smooth transitions between list and detail views.
- **Daily Pokemon**: A featured Pokemon widget to discover new favorites every day.

### 📊 **Detailed Insights**
- **Stats Visualization**: View Base Stats (HP, Attack, Defense, etc.) with toggleable **Radar Charts** or **Bar Graphs**.
- **Comprehensive Info**: See Height, Weight, Types, and Dex Number.
- **Automated Data Fetching**: While you can manually add Pokemon, the app intelligently fetches official data and stats from [PokeAPI](https://pokeapi.co/) when available.

## Technical Highlights
This project demonstrates modern Flutter development practices:
- **State Management**: Uses `Provider` for reactive UI updates.
- **Local Database**: `sqflite` for robust data persistence.
- **Networking**: `http` for fetching remote data from PokeAPI.
- **Charts**: `fl_chart` for visualizing stats.
- **Architecture**: Clean separation of concerns with Repositories, Services, and Controllers.

## Getting Started

1. **Get Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

3. **Explore!**
   Start adding Pokemon or let the app fetch data for you.

