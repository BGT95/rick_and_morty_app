import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rick_and_morty/features/characters/domain/character.dart';

part 'hive_service.g.dart';

@riverpod
Future<HiveService> hiveService(Ref ref) async {
  final service = HiveService();
  await service.init();
  return service;
}

class HiveService {
  static const String favoritesBoxName = 'favorites';
  static const String cacheBoxName = 'characters_cache';

  Box<dynamic>? _favoritesBox;
  Box<dynamic>? _cacheBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _favoritesBox = await Hive.openBox<dynamic>(favoritesBoxName);
    _cacheBox = await Hive.openBox<dynamic>(cacheBoxName);
  }

  // Favorites
  Future<void> addToFavorites(Character character) async {
    try {
      final json = character.toJson();
      await _favoritesBox?.put(
        character.id.toString(),
        json,
      );
    } catch (e) {
      print('Ошибка при добавлении в избранное: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(int characterId) async {
    await _favoritesBox?.delete(characterId.toString());
  }

  bool isFavorite(int characterId) {
    return _favoritesBox?.containsKey(characterId.toString()) ?? false;
  }

  List<Character> getFavorites() {
    try {
      final favorites = _favoritesBox?.values.toList() ?? [];
      return favorites
          .map((json) {
            if (json is Map) {
              return Character.fromJson(
                Map<String, dynamic>.from(
                  json.map((key, value) => MapEntry(key.toString(), value)),
                ),
              );
            }
            throw Exception('Неверный формат данных в избранном');
          })
          .toList();
    } catch (e) {
      print('Ошибка при загрузке избранного: $e');
      return [];
    }
  }

  // Cache
  Future<void> cacheCharacters(List<Character> characters, int page) async {
    try {
      for (var character in characters) {
        final json = character.toJson();
        await _cacheBox?.put(
          '${character.id}_page_$page',
          json,
        );
      }
    } catch (e) {
      print('Ошибка при кэшировании: $e');
      // Не пробрасываем ошибку, так как кэш не критичен
    }
  }

  List<Character> getCachedCharacters(int page) {
    try {
      final cached = _cacheBox?.values.toList() ?? [];
      return cached
          .map((json) {
            if (json is Map) {
              return Character.fromJson(
                Map<String, dynamic>.from(
                  json.map((key, value) => MapEntry(key.toString(), value)),
                ),
              );
            }
            throw Exception('Неверный формат данных в кэше');
          })
          .toList();
    } catch (e) {
      print('Ошибка при загрузке кэша: $e');
      return [];
    }
  }

  Future<void> clearCache() async {
    await _cacheBox?.clear();
  }

  Future<void> clearAllData() async {
    await _favoritesBox?.clear();
    await _cacheBox?.clear();
  }

  Future<void> deleteAndReinitialize() async {
    await Hive.deleteBoxFromDisk(favoritesBoxName);
    await Hive.deleteBoxFromDisk(cacheBoxName);
    await init();
  }
}
