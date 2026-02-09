import 'package:flutter_test/flutter_test.dart';
import 'package:rick_and_morty/core/domain/api_response.dart';

void main() {
  group('ApiInfo', () {
    test('fromJson parses correctly', () {
      final info = ApiInfo.fromJson(const {
        'count': 826,
        'pages': 42,
        'next': 'https://rickandmortyapi.com/api/character?page=2',
        'prev': null,
      });

      expect(info.count, 826);
      expect(info.pages, 42);
      expect(info.next, isNotNull);
      expect(info.prev, isNull);
    });

    test('next is null on last page', () {
      final info = ApiInfo.fromJson(const {
        'count': 826,
        'pages': 42,
        'next': null,
        'prev': 'https://rickandmortyapi.com/api/character?page=41',
      });

      expect(info.next, isNull);
      expect(info.prev, isNotNull);
    });
  });

  group('ApiResponse', () {
    test('fromJson with generic factory', () {
      final json = <String, dynamic>{
        'info': {
          'count': 2,
          'pages': 1,
          'next': null,
          'prev': null,
        },
        'results': [
          {'value': 'a'},
          {'value': 'b'},
        ],
      };

      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        json,
        (obj) => obj as Map<String, dynamic>,
      );

      expect(response.info.count, 2);
      expect(response.results, hasLength(2));
      expect(response.results.first['value'], 'a');
    });
  });
}
