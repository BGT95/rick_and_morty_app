import 'package:flutter_test/flutter_test.dart';
import 'package:rick_and_morty/features/characters/domain/character.dart';

void main() {
  const sampleJson = <String, dynamic>{
    'id': 1,
    'name': 'Rick Sanchez',
    'status': 'Alive',
    'species': 'Human',
    'type': '',
    'gender': 'Male',
    'origin': {'name': 'Earth (C-137)', 'url': 'https://rickandmortyapi.com/api/location/1'},
    'location': {'name': 'Citadel of Ricks', 'url': 'https://rickandmortyapi.com/api/location/3'},
    'image': 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
    'episode': [
      'https://rickandmortyapi.com/api/episode/1',
      'https://rickandmortyapi.com/api/episode/2',
    ],
    'url': 'https://rickandmortyapi.com/api/character/1',
    'created': '2017-11-04T18:48:46.250Z',
  };

  group('Character', () {
    test('fromJson creates correct model', () {
      final character = Character.fromJson(sampleJson);

      expect(character.id, 1);
      expect(character.name, 'Rick Sanchez');
      expect(character.status, 'Alive');
      expect(character.species, 'Human');
      expect(character.gender, 'Male');
      expect(character.origin.name, 'Earth (C-137)');
      expect(character.location.name, 'Citadel of Ricks');
      expect(character.episode, hasLength(2));
    });

    test('toJson produces valid Map', () {
      final character = Character.fromJson(sampleJson);
      final json = character.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Rick Sanchez');
      expect(json['origin'], isA<Map<String, dynamic>>());
      expect(json['location'], isA<Map<String, dynamic>>());
      expect(json['episode'], isA<List>());
    });

    test('roundtrip fromJson -> toJson -> fromJson preserves data', () {
      final original = Character.fromJson(sampleJson);
      final restored = Character.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.status, original.status);
      expect(restored.origin.name, original.origin.name);
      expect(restored.location.name, original.location.name);
      expect(restored.episode, original.episode);
    });

    test('type can be empty string', () {
      final character = Character.fromJson(sampleJson);
      expect(character.type, '');
    });
  });

  group('CharacterLocation', () {
    test('fromJson creates correct model', () {
      final location = CharacterLocation.fromJson(
        const {'name': 'Earth', 'url': 'https://example.com'},
      );
      expect(location.name, 'Earth');
      expect(location.url, 'https://example.com');
    });
  });
}
