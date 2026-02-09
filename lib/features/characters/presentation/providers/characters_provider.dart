import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/infrastructure/local/hive_service.dart';
import '../../domain/character.dart';
import '../../infrastructure/repos/characters_repository.dart';

part 'characters_provider.g.dart';

// ── Вспомогательные провайдеры ──

@riverpod
class IsLoadingMore extends _$IsLoadingMore {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

@riverpod
class HasMoreToShow extends _$HasMoreToShow {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

// ── Поиск и фильтры ──

@riverpod
class SearchQuery extends _$SearchQuery {
  Timer? _debounce;

  @override
  String build() => '';

  void set(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (state != value) {
        state = value;
      }
    });
  }

  /// Немедленная установка (без debounce) — для очистки.
  void clear() {
    _debounce?.cancel();
    state = '';
  }
}

@riverpod
class StatusFilter extends _$StatusFilter {
  @override
  String build() => ''; // '', 'alive', 'dead', 'unknown'

  void set(String value) => state = value;
}

// ── Список персонажей ──

@riverpod
class CharactersList extends _$CharactersList {
  int _currentPage = 1;
  bool _hasMore = true;
  List<Character> _allLoadedCharacters = [];
  int _displayedCount = 0;
  static const int _itemsPerLoad = 10;

  @override
  Future<List<Character>> build() async {
    final repository = ref.watch(charactersRepositoryProvider);
    final query = ref.watch(searchQueryProvider);
    final status = ref.watch(statusFilterProvider);

    final result = await repository.getCharacters(
      page: 1,
      name: query.isEmpty ? null : query,
      status: status.isEmpty ? null : status,
    );

    return result.fold(
      (error) => throw Exception(error),
      (response) {
        _hasMore = response.info.next != null;
        _allLoadedCharacters = List<Character>.from(response.results);
        _displayedCount = _allLoadedCharacters.length < _itemsPerLoad
            ? _allLoadedCharacters.length
            : _itemsPerLoad;
        _syncHasMore();
        return _allLoadedCharacters.take(_displayedCount).toList();
      },
    );
  }

  void _syncHasMore() {
    ref.read(hasMoreToShowProvider.notifier).set(
          _displayedCount < _allLoadedCharacters.length || _hasMore,
        );
  }

  Future<void> loadMore() async {
    if (state.isLoading || ref.read(isLoadingMoreProvider)) return;

    if (_displayedCount < _allLoadedCharacters.length) {
      _displayedCount = (_displayedCount + _itemsPerLoad)
          .clamp(0, _allLoadedCharacters.length);
      state = AsyncData(
        _allLoadedCharacters.take(_displayedCount).toList(),
      );
      _syncHasMore();
      return;
    }

    if (!_hasMore) return;

    ref.read(isLoadingMoreProvider.notifier).set(true);
    _currentPage++;

    try {
      final repository = ref.read(charactersRepositoryProvider);
      final query = ref.read(searchQueryProvider);
      final status = ref.read(statusFilterProvider);

      final result = await repository.getCharacters(
        page: _currentPage,
        name: query.isEmpty ? null : query,
        status: status.isEmpty ? null : status,
      );

      result.fold(
        (error) => _currentPage--,
        (response) {
          _hasMore = response.info.next != null;
          _allLoadedCharacters = [
            ..._allLoadedCharacters,
            ...response.results,
          ];
          _displayedCount = (_displayedCount + _itemsPerLoad)
              .clamp(0, _allLoadedCharacters.length);
          state = AsyncData(
            _allLoadedCharacters.take(_displayedCount).toList(),
          );
        },
      );
    } catch (_) {
      _currentPage--;
    } finally {
      ref.read(isLoadingMoreProvider.notifier).set(false);
      _syncHasMore();
    }
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    _allLoadedCharacters = [];
    _displayedCount = 0;
    ref.read(hasMoreToShowProvider.notifier).set(true);
    ref.invalidateSelf();
  }
}

// ── Избранное ──

@riverpod
class FavoriteCharacters extends _$FavoriteCharacters {
  @override
  List<Character> build() {
    final hiveAsync = ref.watch(hiveServiceProvider);
    return hiveAsync.when(
      data: (hive) =>
          hive.getAllFavorites().map(Character.fromJson).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  Future<void> toggleFavorite(Character character) async {
    final hiveService = ref.read(hiveServiceProvider).requireValue;
    final id = character.id.toString();

    if (hiveService.containsFavorite(id)) {
      await hiveService.removeFavorite(id);
    } else {
      await hiveService.saveFavorite(id, character.toJson());
    }

    state = hiveService
        .getAllFavorites()
        .map(Character.fromJson)
        .toList();
  }
}

/// Проверка, является ли персонаж избранным.
@riverpod
bool isFavorite(Ref ref, int characterId) {
  final favorites = ref.watch(favoriteCharactersProvider);
  return favorites.any((c) => c.id == characterId);
}

/// Отсортированный список избранных.
@riverpod
List<Character> sortedFavorites(Ref ref, String sortBy) {
  final favorites = ref.watch(favoriteCharactersProvider);
  final sorted = [...favorites];
  switch (sortBy) {
    case 'name':
      sorted.sort((a, b) => a.name.compareTo(b.name));
    case 'status':
      sorted.sort((a, b) => a.status.compareTo(b.status));
    case 'species':
      sorted.sort((a, b) => a.species.compareTo(b.species));
  }
  return sorted;
}
