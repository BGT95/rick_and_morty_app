import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rick_and_morty/core/presentation/widgets/character_card.dart';
import 'package:rick_and_morty/features/characters/presentation/providers/characters_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteCharactersProvider);
    final sortBy = ref.watch(_sortByProvider);

    final sortedFavorites =
        ref.read(favoriteCharactersProvider.notifier).getSorted(sortBy);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              ref.read(_sortByProvider.notifier).state = value;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: Text('По имени'),
              ),
              const PopupMenuItem(
                value: 'status',
                child: Text('По статусу'),
              ),
              const PopupMenuItem(
                value: 'species',
                child: Text('По виду'),
              ),
            ],
          ),
        ],
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет избранных персонажей',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Добавьте персонажей в избранное,\nнажав на звездочку',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: sortedFavorites.length,
              itemBuilder: (context, index) {
                final character = sortedFavorites[index];
                return CharacterCard(
                  character: character,
                  onTap: () {
                    // TODO: Navigate to detail screen
                  },
                );
              },
            ),
    );
  }
}

final _sortByProvider = StateProvider<String>((ref) => 'name');
