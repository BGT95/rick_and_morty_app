import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/domain/api_response.dart';
import '../../../../core/infrastructure/network/dio_provider.dart';
import '../../domain/character.dart';
import '../../domain/episode.dart';

part 'characters_remote_data_source.g.dart';

@riverpod
CharactersRemoteDataSource charactersRemoteDataSource(Ref ref) {
  return CharactersRemoteDataSource(dio: ref.watch(dioProvider));
}

class CharactersRemoteDataSource {
  CharactersRemoteDataSource({required this.dio});

  final Dio dio;

  /// Загружает список персонажей.
  Future<ApiResponse<Character>> getCharacters({
    int page = 1,
    String? name,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{'page': page};
    if (name != null && name.isNotEmpty) queryParameters['name'] = name;
    if (status != null && status.isNotEmpty) queryParameters['status'] = status;

    final response = await dio.get(
      '/character',
      queryParameters: queryParameters,
    );

    return ApiResponse<Character>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Character.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Загружает одного персонажа по ID.
  Future<Character> getCharacterById(int id) async {
    final response = await dio.get('/character/$id');
    return Character.fromJson(response.data as Map<String, dynamic>);
  }

  /// Загружает нескольких персонажей по списку ID.
  /// API поддерживает: /character/1,2,3
  Future<List<Character>> getCharactersByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    if (ids.length == 1) return [await getCharacterById(ids.first)];

    final idsParam = ids.join(',');
    final response = await dio.get('/character/$idsParam');
    final data = response.data;

    if (data is List) {
      return data
          .map((json) => Character.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [Character.fromJson(data as Map<String, dynamic>)];
  }

  /// Загружает несколько эпизодов по списку ID.
  /// API поддерживает: /episode/1,2,3
  Future<List<Episode>> getEpisodesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    if (ids.length == 1) {
      final response = await dio.get('/episode/${ids.first}');
      return [Episode.fromJson(response.data as Map<String, dynamic>)];
    }

    final idsParam = ids.join(',');
    final response = await dio.get('/episode/$idsParam');
    final data = response.data;

    if (data is List) {
      return data
          .map((json) => Episode.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [Episode.fromJson(data as Map<String, dynamic>)];
  }
}
