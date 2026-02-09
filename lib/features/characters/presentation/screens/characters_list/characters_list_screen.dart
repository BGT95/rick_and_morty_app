import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/presentation/theme/app_theme.dart';
import '../../widgets/character_card.dart';
import '../../providers/characters_provider.dart';
import '../character_detail/character_detail_screen.dart';

class CharactersListScreen extends HookConsumerWidget {
  const CharactersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charactersAsync = ref.watch(charactersListProvider);
    final isLoading = ref.watch(isLoadingMoreProvider);
    final scrollController = useScrollController();

    useEffect(() {
      void onScroll() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent * 0.9) {
          ref.read(charactersListProvider.notifier).loadMore();
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
              ref.watch(themeModeProvider).valueOrNull == ThemeModeEnum.dark
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Ошибка: $error',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(charactersListProvider.notifier).refresh(),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (characters) {
          if (characters.isEmpty) {
            return const Center(child: Text('Нет персонажей'));
          }

          final hasMore = ref.watch(hasMoreToShowProvider);

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(charactersListProvider.notifier).refresh(),
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: () => ref
                                  .read(charactersListProvider.notifier)
                                  .loadMore(),
                              child: const Text('Загрузить ещё'),
                            ),
                    ),
                  );
                }

                final character = characters[index];
                return CharacterCard(
                  character: character,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CharacterDetailScreen(character: character),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
