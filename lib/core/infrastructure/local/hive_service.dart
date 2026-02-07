import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../utils/logger.dart';

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

  late Box<dynamic> _favoritesBox;
  late Box<dynamic> _cacheBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _favoritesBox = await Hive.openBox<dynamic>(favoritesBoxName);
    _cacheBox = await Hive.openBox<dynamic>(cacheBoxName);
  }

  /// Рекурсивно конвертирует вложенные Map и List из Hive
  /// в типы, совместимые с `fromJson`.
  static dynamic deepConvert(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (key, val) => MapEntry(key.toString(), deepConvert(val)),
      );
    }
    if (value is List) {
      return value.map(deepConvert).toList();
    }
    return value;
  }

  // ── Favorites ──

  Future<void> saveFavorite(String id, Map<String, dynamic> json) async {
    try {
      await _favoritesBox.put(id, json);
    } catch (e) {
      AppLogger.error('Ошибка при сохранении в избранное', error: e);
      rethrow;
    }
  }

  Future<void> removeFavorite(String id) async {
    await _favoritesBox.delete(id);
  }

  bool containsFavorite(String id) {
    return _favoritesBox.containsKey(id);
  }

  List<Map<String, dynamic>> getAllFavorites() {
    try {
      return _favoritesBox.values
          .whereType<Map>()
          .map((json) => deepConvert(json) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      AppLogger.error('Ошибка при загрузке избранного', error: e);
      return [];
    }
  }

  // ── Cache ──

  Future<void> cacheItems(
    List<Map<String, dynamic>> items,
    int page,
  ) async {
    try {
      for (final json in items) {
        final id = json['id'];
        await _cacheBox.put('page_${page}_$id', json);
      }
    } catch (e) {
      AppLogger.error('Ошибка при кэшировании', error: e);
    }
  }

  List<Map<String, dynamic>> getCachedItems(int page) {
    try {
      final prefix = 'page_${page}_';
      return _cacheBox.keys
          .where((key) => key.toString().startsWith(prefix))
          .map((key) => _cacheBox.get(key))
          .whereType<Map>()
          .map((json) => deepConvert(json) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      AppLogger.error('Ошибка при загрузке кэша', error: e);
      return [];
    }
  }

  Future<void> clearCache() async {
    await _cacheBox.clear();
  }

  Future<void> clearAllData() async {
    await _favoritesBox.clear();
    await _cacheBox.clear();
  }
}
