import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/character.dart';
import '../../domain/episode.dart';
import '../../infrastructure/repos/characters_repository.dart';

part 'character_detail_provider.g.dart';

/// Извлекает ID эпизодов из URL-ов вида
/// "https://rickandmortyapi.com/api/episode/28".
List<int> _parseEpisodeIds(List<String> urls) {
  return urls
      .map((url) => int.tryParse(url.split('/').last) ?? 0)
      .where((id) => id > 0)
      .toList();
}

/// Извлекает ID персонажей из URL-ов.
List<int> _parseCharacterIds(List<String> urls) {
  return urls
      .map((url) => int.tryParse(url.split('/').last) ?? 0)
      .where((id) => id > 0)
      .toList();
}

/// Эпизоды, в которых появляется персонаж.
@riverpod
Future<List<Episode>> characterEpisodes(
  Ref ref,
  List<String> episodeUrls,
) async {
  final repo = ref.watch(charactersRepositoryProvider);
  final ids = _parseEpisodeIds(episodeUrls);
  if (ids.isEmpty) return [];

  final result = await repo.getEpisodesByIds(ids);
  return result.fold((_) => [], (episodes) => episodes);
}

/// Персонажи из того же первого эпизода (связанные / «коллеги»).
/// Исключает самого персонажа из списка. Возвращает максимум 10.
@riverpod
Future<List<Character>> relatedCharacters(
  Ref ref,
  int characterId,
  List<String> episodeUrls,
) async {
  if (episodeUrls.isEmpty) return [];

  final repo = ref.watch(charactersRepositoryProvider);

  // Берём первый эпизод для поиска связанных персонажей.
  final firstEpIds = _parseEpisodeIds([episodeUrls.first]);
  if (firstEpIds.isEmpty) return [];

  final epResult = await repo.getEpisodesByIds(firstEpIds);
  return epResult.fold((_) => <Character>[], (episodes) async {
    if (episodes.isEmpty) return <Character>[];

    final charIds = _parseCharacterIds(episodes.first.characters)
        .where((id) => id != characterId)
        .take(10)
        .toList();

    if (charIds.isEmpty) return <Character>[];

    final charsResult = await repo.getCharactersByIds(charIds);
    return charsResult.fold((_) => <Character>[], (chars) => chars);
  });
}
