import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rick_and_morty/core/domain/api_response.dart';
import 'package:rick_and_morty/core/infrastructure/local/hive_service.dart';
import 'package:rick_and_morty/features/characters/domain/character.dart';
import 'package:rick_and_morty/features/characters/infrastructure/data_sources/characters_remote_data_source.dart';
import 'package:dio/dio.dart';

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

      // Cache the results
      await hiveService.cacheCharacters(response.results, page);

      return right(response);
    } on DioException catch (e) {
      // Try to load from cache on error
      final cached = hiveService.getCachedCharacters(page);
      if (cached.isNotEmpty) {
        return right(
          ApiResponse(
            info: const ApiInfo(count: 0, pages: 0),
            results: cached,
          ),
        );
      }
      return left(e.message ?? 'Network error');
    } catch (e) {
      return left(e.toString());
    }
  }

  Future<Either<String, Character>> getCharacterById(int id) async {
    try {
      final character = await remoteDataSource.getCharacterById(id);
      return right(character);
    } on DioException catch (e) {
      return left(e.message ?? 'Network error');
    } catch (e) {
      return left(e.toString());
    }
  }

  // Favorites
  Future<void> addToFavorites(Character character) async {
    await hiveService.addToFavorites(character);
  }

  Future<void> removeFromFavorites(int characterId) async {
    await hiveService.removeFromFavorites(characterId);
  }

  bool isFavorite(int characterId) {
    return hiveService.isFavorite(characterId);
  }

  List<Character> getFavorites() {
    return hiveService.getFavorites();
  }
}
