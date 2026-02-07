import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/domain/api_response.dart';
import '../../../../core/infrastructure/network/dio_provider.dart';
import '../../domain/character.dart';

part 'characters_remote_data_source.g.dart';

@riverpod
CharactersRemoteDataSource charactersRemoteDataSource(Ref ref) {
  return CharactersRemoteDataSource(dio: ref.watch(dioProvider));
}

class CharactersRemoteDataSource {
  CharactersRemoteDataSource({required this.dio});

  final Dio dio;

  /// Загружает список персонажей. Пробрасывает [DioException] наверх,
  /// чтобы репозиторий мог выполнить фоллбэк на кэш.
  Future<ApiResponse<Character>> getCharacters({
    int page = 1,
    String? name,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
    };
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

  Future<Character> getCharacterById(int id) async {
    final response = await dio.get('/character/$id');
    return Character.fromJson(response.data as Map<String, dynamic>);
  }
}
