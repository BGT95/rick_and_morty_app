import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/domain/api_response.dart';
import '../../../../core/infrastructure/local/hive_service.dart';
import '../../domain/character.dart';
import '../../domain/episode.dart';
import '../data_sources/characters_remote_data_source.dart';

part 'characters_repository.g.dart';

@riverpod
CharactersRepository charactersRepository(Ref ref) {
  return CharactersRepository(
    remoteDataSource: ref.watch(charactersRemoteDataSourceProvider),
    hiveService: ref.watch(hiveServiceProvider).requireValue,
  );
}

class CharactersRepository {
  CharactersRepository({
    required this.remoteDataSource,
    required this.hiveService,
  });

  final CharactersRemoteDataSource remoteDataSource;
  final HiveService hiveService;

  Future<Either<String, ApiResponse<Character>>> getCharacters({
    int page = 1,
    String? name,
    String? status,
  }) async {
    try {
      final response = await remoteDataSource.getCharacters(
        page: page,
        name: name,
        status: status,
      );

      await hiveService.cacheItems(
        response.results.map((c) => c.toJson()).toList(),
        page,
      );

      return right(response);
    } on DioException catch (e) {
      final cached = _cachedCharacters(page);
      if (cached.isNotEmpty) {
        return right(
          ApiResponse(
            info: const ApiInfo(count: 0, pages: 0),
            results: cached,
          ),
        );
      }
      return left(e.message ?? 'Ошибка сети');
    } catch (e) {
      return left(e.toString());
    }
  }

  Future<Either<String, Character>> getCharacterById(int id) async {
    try {
      final character = await remoteDataSource.getCharacterById(id);
      return right(character);
    } on DioException catch (e) {
      return left(e.message ?? 'Ошибка сети');
    } catch (e) {
      return left(e.toString());
    }
  }

  /// Загружает нескольких персонажей по ID.
  Future<Either<String, List<Character>>> getCharactersByIds(
    List<int> ids,
  ) async {
    try {
      final characters = await remoteDataSource.getCharactersByIds(ids);
      return right(characters);
    } on DioException catch (e) {
      return left(e.message ?? 'Ошибка сети');
    } catch (e) {
      return left(e.toString());
    }
  }

  /// Загружает эпизоды по ID.
  Future<Either<String, List<Episode>>> getEpisodesByIds(
    List<int> ids,
  ) async {
    try {
      final episodes = await remoteDataSource.getEpisodesByIds(ids);
      return right(episodes);
    } on DioException catch (e) {
      return left(e.message ?? 'Ошибка сети');
    } catch (e) {
      return left(e.toString());
    }
  }

  // ── Favorites ──

  Future<void> addToFavorites(Character character) async {
    await hiveService.saveFavorite(
      character.id.toString(),
      character.toJson(),
    );
  }

  Future<void> removeFromFavorites(int characterId) async {
    await hiveService.removeFavorite(characterId.toString());
  }

  bool isFavorite(int characterId) {
    return hiveService.containsFavorite(characterId.toString());
  }

  List<Character> getFavorites() {
    return hiveService.getAllFavorites().map(Character.fromJson).toList();
  }

  // ── Helpers ──

  List<Character> _cachedCharacters(int page) {
    return hiveService.getCachedItems(page).map(Character.fromJson).toList();
  }
}
