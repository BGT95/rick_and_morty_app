import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rick_and_morty/features/characters/domain/character.dart';
import 'package:rick_and_morty/features/characters/infrastructure/repos/characters_repository.dart';

part 'characters_provider.g.dart';

@riverpod
class CharactersList extends _$CharactersList {
  int _currentPage = 1;
  bool _hasMore = true;
  List<Character> _allLoadedCharacters = [];
  int _displayedCount = 0;
  static const int _itemsPerLoad = 10; // Количество персонажей за раз

  @override
  Future<List<Character>> build() async {
    final repository = ref.watch(charactersRepositoryProvider);
    final result = await repository.getCharacters(page: 1);

    return result.fold(
      (error) => throw Exception(error),
      (response) {
        _hasMore = response.info.next != null;
        _allLoadedCharacters = response.results;
        _displayedCount = _itemsPerLoad;
        
        // Возвращаем только первые 10 персонажей
        return _allLoadedCharacters.take(_displayedCount).toList();
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading) return;
    
    // Если есть загруженные, но не отображенные персонажи
    if (_displayedCount < _allLoadedCharacters.length) {
      _displayedCount += _itemsPerLoad;
      final newDisplayedCount = _displayedCount > _allLoadedCharacters.length 
          ? _allLoadedCharacters.length 
          : _displayedCount;
      
      state = AsyncData(_allLoadedCharacters.take(newDisplayedCount).toList());
      return;
    }

    // Если нужно загрузить новую страницу с API
    if (!_hasMore) return;

    final repository = ref.watch(charactersRepositoryProvider);
    _currentPage++;

    final result = await repository.getCharacters(page: _currentPage);

    result.fold(
      (error) => throw Exception(error),
      (response) {
        _hasMore = response.info.next != null;
        _allLoadedCharacters.addAll(response.results);
        _displayedCount += _itemsPerLoad;
        
        final newDisplayedCount = _displayedCount > _allLoadedCharacters.length 
            ? _allLoadedCharacters.length 
            : _displayedCount;
        
        state = AsyncData(_allLoadedCharacters.take(newDisplayedCount).toList());
      },
    );
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    _allLoadedCharacters = [];
    _displayedCount = 0;
    ref.invalidateSelf();
  }

  // Проверка, есть ли еще персонажи для отображения
  bool get hasMoreToShow {
    return _displayedCount < _allLoadedCharacters.length || _hasMore;
  }
}

@riverpod
class FavoriteCharacters extends _$FavoriteCharacters {
  @override
  List<Character> build() {
    final repository = ref.watch(charactersRepositoryProvider);
    return repository.getFavorites();
  }

  Future<void> toggleFavorite(Character character) async {
    final repository = ref.read(charactersRepositoryProvider);
    final isFavorite = repository.isFavorite(character.id);

    if (isFavorite) {
      await repository.removeFromFavorites(character.id);
    } else {
      await repository.addToFavorites(character);
    }

    // Refresh the state
    state = repository.getFavorites();
  }

  bool isFavorite(int characterId) {
    return state.any((char) => char.id == characterId);
  }

  List<Character> getSorted(String sortBy) {
    final sorted = [...state];
    switch (sortBy) {
      case 'name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'status':
        sorted.sort((a, b) => a.status.compareTo(b.status));
        break;
      case 'species':
        sorted.sort((a, b) => a.species.compareTo(b.species));
        break;
    }
    return sorted;
  }
}
