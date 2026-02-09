import 'package:flutter_test/flutter_test.dart';
import 'package:rick_and_morty/features/characters/domain/episode.dart';

void main() {
  const sampleJson = <String, dynamic>{
    'id': 1,
    'name': 'Pilot',
    'air_date': 'December 2, 2013',
    'episode': 'S01E01',
    'characters': [
      'https://rickandmortyapi.com/api/character/1',
      'https://rickandmortyapi.com/api/character/2',
    ],
    'url': 'https://rickandmortyapi.com/api/episode/1',
    'created': '2017-11-10T12:56:33.798Z',
  };

  group('Episode', () {
    test('fromJson creates correct model', () {
      final episode = Episode.fromJson(sampleJson);

      expect(episode.id, 1);
      expect(episode.name, 'Pilot');
      expect(episode.airDate, 'December 2, 2013');
      expect(episode.episode, 'S01E01');
      expect(episode.characters, hasLength(2));
    });

    test('toJson produces valid Map', () {
      final episode = Episode.fromJson(sampleJson);
      final json = episode.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Pilot');
      expect(json['air_date'], 'December 2, 2013');
    });

    test('roundtrip preserves data', () {
      final original = Episode.fromJson(sampleJson);
      final restored = Episode.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.airDate, original.airDate);
      expect(restored.episode, original.episode);
    });
  });
}
