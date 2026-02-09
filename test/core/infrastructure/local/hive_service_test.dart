import 'package:flutter_test/flutter_test.dart';
import 'package:rick_and_morty/core/infrastructure/local/hive_service.dart';

void main() {
  group('HiveService.deepConvert', () {
    test('converts Map<dynamic, dynamic> to Map<String, dynamic>', () {
      final input = <dynamic, dynamic>{
        'name': 'Rick',
        'id': 1,
        42: 'numeric key',
      };

      final result = HiveService.deepConvert(input);

      expect(result, isA<Map<String, dynamic>>());
      final map = result as Map<String, dynamic>;
      expect(map['name'], 'Rick');
      expect(map['id'], 1);
      expect(map['42'], 'numeric key');
    });

    test('recursively converts nested Maps', () {
      final input = <dynamic, dynamic>{
        'location': <dynamic, dynamic>{
          'name': 'Earth',
          'url': 'https://example.com',
        },
      };

      final result = HiveService.deepConvert(input) as Map<String, dynamic>;
      expect(result['location'], isA<Map<String, dynamic>>());
      expect((result['location'] as Map)['name'], 'Earth');
    });

    test('converts Lists with nested Maps', () {
      final input = <dynamic>[
        <dynamic, dynamic>{'id': 1},
        <dynamic, dynamic>{'id': 2},
      ];

      final result = HiveService.deepConvert(input);

      expect(result, isA<List>());
      final list = result as List;
      expect(list[0], isA<Map<String, dynamic>>());
      expect((list[0] as Map)['id'], 1);
    });

    test('returns primitives unchanged', () {
      expect(HiveService.deepConvert(42), 42);
      expect(HiveService.deepConvert('hello'), 'hello');
      expect(HiveService.deepConvert(true), true);
      expect(HiveService.deepConvert(null), null);
    });
  });
}
