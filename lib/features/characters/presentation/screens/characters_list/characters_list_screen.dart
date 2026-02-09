import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/presentation/theme/app_theme.dart';
import '../../providers/characters_provider.dart';
import '../../widgets/character_card.dart';
import '../character_detail/character_detail_screen.dart';

class CharactersListScreen extends HookConsumerWidget {
  const CharactersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charactersAsync = ref.watch(charactersListProvider);
    final isLoading = ref.watch(isLoadingMoreProvider);
    final scrollController = useScrollController();
    final searchController = useTextEditingController();
    final isSearchOpen = useState(false);
    final activeStatus = ref.watch(statusFilterProvider);

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
        title: isSearchOpen.value
            ? _SearchField(
                controller: searchController,
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).set(v),
                onClose: () {
                  isSearchOpen.value = false;
                  searchController.clear();
                  ref.read(searchQueryProvider.notifier).clear();
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rick and Morty'),
                  charactersAsync.when(
                    data: (c) => Text(
                      'Загружено: ${c.length}',
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
          if (!isSearchOpen.value)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => isSearchOpen.value = true,
            ),
          IconButton(
            icon: Icon(
              ref.watch(themeModeProvider).valueOrNull == ThemeModeEnum.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Фильтр по статусу ──
          _StatusFilterBar(
            active: activeStatus,
            onSelected: (s) => ref.read(statusFilterProvider.notifier).set(s),
          ),

          // ── Список ──
          Expanded(
            child: charactersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text('Ошибка: $error',
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(charactersListProvider.notifier)
                          .refresh(),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
              data: (characters) {
                if (characters.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Ничего не найдено'),
                      ],
                    ),
                  );
                }

                final hasMore = ref.watch(hasMoreToShowProvider);

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(charactersListProvider.notifier)
                      .refresh(),
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount:
                        characters.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == characters.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : TextButton(
                                    onPressed: () => ref
                                        .read(charactersListProvider
                                            .notifier)
                                        .loadMore(),
                                    child:
                                        const Text('Загрузить ещё'),
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
                            builder: (_) => CharacterDetailScreen(
                                character: character),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Поисковое поле ──

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.titleMedium,
      decoration: InputDecoration(
        hintText: 'Поиск по имени...',
        border: InputBorder.none,
        suffixIcon: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ),
    );
  }
}

// ── Фильтр по статусу ──

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.active,
    required this.onSelected,
  });

  final String active;
  final ValueChanged<String> onSelected;

  static const _statuses = [
    ('', 'Все'),
    ('alive', 'Alive'),
    ('dead', 'Dead'),
    ('unknown', 'Unknown'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = _statuses[index];
          final isActive = active == value;
          return FilterChip(
            selected: isActive,
            label: Text(label),
            selectedColor: colorScheme.primaryContainer,
            checkmarkColor: colorScheme.onPrimaryContainer,
            onSelected: (_) => onSelected(isActive ? '' : value),
          );
        },
      ),
    );
  }
}
