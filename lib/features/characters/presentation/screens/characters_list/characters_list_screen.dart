import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rick_and_morty/core/presentation/theme/app_theme.dart';
import 'package:rick_and_morty/core/presentation/widgets/character_card.dart';
import 'package:rick_and_morty/features/characters/presentation/providers/characters_provider.dart';

class CharactersListScreen extends HookConsumerWidget {
  const CharactersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charactersAsync = ref.watch(charactersListProvider);
    final scrollController = useScrollController();
    final notifier = ref.read(charactersListProvider.notifier);

    useEffect(() {
      void onScroll() {
        // Загружаем больше, когда прокрутили до 90% списка
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent * 0.9) {
          notifier.loadMore();
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rick and Morty'),
            charactersAsync.when(
              data: (characters) => Text(
                'Загружено: ${characters.length}',
                style: const TextStyle(fontSize: 12),
              ),
              loading: () => const Text(
                'Загрузка...',
                style: TextStyle(fontSize: 12),
              ),
              error: (_, __) => const Text(
                'Ошибка',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeModeEnum.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: charactersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка: $error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(charactersListProvider.notifier).refresh();
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (characters) {
          if (characters.isEmpty) {
            return const Center(
              child: Text('Нет персонажей'),
            );
          }

          final hasMore = notifier.hasMoreToShow;
          
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(charactersListProvider.notifier).refresh();
            },
            child: GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: characters.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == characters.length) {
                  // Loading indicator at the end (только если есть еще персонажи)
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final character = characters[index];
                return CharacterCard(
                  character: character,
                  onTap: () {
                    // TODO: Navigate to detail screen
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
