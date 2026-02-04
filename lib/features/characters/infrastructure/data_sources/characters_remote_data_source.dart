import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rick_and_morty/core/domain/api_response.dart';
import 'package:rick_and_morty/core/infrastructure/network/dio_provider.dart';
import 'package:rick_and_morty/features/characters/domain/character.dart';

part 'characters_remote_data_source.g.dart';

@riverpod
CharactersRemoteDataSource charactersRemoteDataSource(
  Ref ref,
) {
  return CharactersRemoteDataSource(
    dio: ref.watch(dioProvider),
  );
}

class CharactersRemoteDataSource {
  CharactersRemoteDataSource({
    required this.dio,
  });

  final Dio dio;

  Future<ApiResponse<Character>> getCharacters({
    int page = 1,
    String? name,
    String? status,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
      };

      if (name != null && name.isNotEmpty) {
        queryParameters['name'] = name;
      }

      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      final response = await dio.get(
        '/character',
        queryParameters: queryParameters,
      );

      return ApiResponse<Character>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Character.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
          'Таймаут подключения. Проверьте интернет-соединение или запустите Chrome с флагом --disable-web-security',
        );
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Таймаут получения данных. Сервер не отвечает');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Ошибка подключения. Возможно проблема с CORS при работе в браузере',
        );
      }
      rethrow;
    }
  }

  Future<Character> getCharacterById(int id) async {
    try {
      final response = await dio.get('/character/$id');
      return Character.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
          'Таймаут подключения. Проверьте интернет-соединение или запустите Chrome с флагом --disable-web-security',
        );
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Таймаут получения данных. Сервер не отвечает');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Ошибка подключения. Возможно проблема с CORS при работе в браузере',
        );
      }
      rethrow;
    }
  }
}
