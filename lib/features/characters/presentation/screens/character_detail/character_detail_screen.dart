import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../domain/character.dart';
import '../../../domain/episode.dart';
import '../../providers/character_detail_provider.dart';
import '../../providers/characters_provider.dart';

class CharacterDetailScreen extends ConsumerWidget {
  const CharacterDetailScreen({super.key, required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoriteCharactersProvider.select(
        (favs) => favs.any((c) => c.id == character.id),
      ),
    );

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero image AppBar ──
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : null,
                ),
                onPressed: () => ref
                    .read(favoriteCharactersProvider.notifier)
                    .toggleFavorite(character),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                character.name,
                style: const TextStyle(
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
              background: Hero(
                tag: 'character_${character.id}',
                child: CachedNetworkImage(
                  imageUrl: character.image,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 64),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Статус и вид
                  _StatusBadge(character: character),
                  const SizedBox(height: 24),

                  // Характеристики
                  const _SectionTitle(title: 'Характеристики'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _InfoGrid(
                        character: character, colorScheme: colorScheme),
                  ),
                  const SizedBox(height: 24),

                  // Биография / описание
                  const _SectionTitle(title: 'О персонаже'),
                  const SizedBox(height: 8),
                  _BioCard(character: character, colorScheme: colorScheme),
                  const SizedBox(height: 24),

                  // Эпизоды
                  _SectionTitle(title: 'Эпизоды (${character.episode.length})'),
                  const SizedBox(height: 8),
                  _EpisodesList(episodeUrls: character.episode),
                  const SizedBox(height: 24),

                  // Связанные персонажи
                  const _SectionTitle(title: 'Появляется вместе с'),
                  const SizedBox(height: 8),
                  _RelatedCharactersList(
                    characterId: character.id,
                    episodeUrls: character.episode,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ──

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.character});
  final Character character;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _statusColor(character.status),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${character.status} — ${character.species}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'alive':
        return Colors.green;
      case 'dead':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.character, required this.colorScheme});
  final Character character;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final items = [
      _InfoItem(Icons.wc, 'Пол', character.gender),
      _InfoItem(Icons.category, 'Вид', character.species),
      if (character.type.isNotEmpty)
        _InfoItem(Icons.label, 'Тип', character.type),
      _InfoItem(Icons.public, 'Происхождение', character.origin.name),
      _InfoItem(Icons.location_on, 'Локация', character.location.name),
      _InfoItem(Icons.movie, 'Эпизодов', '${character.episode.length}'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((item) => _InfoChip(item: item, colorScheme: colorScheme))
          .toList(),
    );
  }
}

class _InfoItem {
  const _InfoItem(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.item, required this.colorScheme});
  final _InfoItem item;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  item.value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BioCard extends StatelessWidget {
  const _BioCard({required this.character, required this.colorScheme});
  final Character character;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final bio = _generateBio(character);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(bio, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  String _generateBio(Character c) {
    final status = switch (c.status.toLowerCase()) {
      'alive' => 'жив',
      'dead' => 'мёртв',
      _ => 'статус неизвестен',
    };

    final gender = switch (c.gender.toLowerCase()) {
      'male' => 'мужского пола',
      'female' => 'женского пола',
      'genderless' => 'бесполый',
      _ => 'пол неизвестен',
    };

    final type = c.type.isNotEmpty ? ' (${c.type})' : '';
    final origin = c.origin.name != 'unknown'
        ? 'Родом из ${c.origin.name}.'
        : 'Происхождение неизвестно.';
    final location = c.location.name != 'unknown'
        ? 'Последнее известное местонахождение — ${c.location.name}.'
        : 'Текущее местонахождение неизвестно.';

    return '${c.name} — ${c.species}$type, $gender, $status. '
        '$origin $location '
        'Появляется в ${c.episode.length} эпизодах сериала.';
  }
}

class _EpisodesList extends ConsumerWidget {
  const _EpisodesList({required this.episodeUrls});
  final List<String> episodeUrls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(characterEpisodesProvider(episodeUrls));

    return episodesAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Text('Не удалось загрузить эпизоды'),
      data: (episodes) {
        if (episodes.isEmpty) {
          return const Text('Нет данных об эпизодах');
        }
        return SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: episodes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) =>
                _EpisodeChip(episode: episodes[index]),
          ),
        );
      },
    );
  }
}

class _EpisodeChip extends StatelessWidget {
  const _EpisodeChip({required this.episode});
  final Episode episode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 160,
      child: Card(
        color: colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                episode.episode,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  episode.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Text(
                episode.airDate,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer.withAlpha(180),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelatedCharactersList extends ConsumerWidget {
  const _RelatedCharactersList({
    required this.characterId,
    required this.episodeUrls,
  });

  final int characterId;
  final List<String> episodeUrls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedAsync = ref.watch(
      relatedCharactersProvider(characterId, episodeUrls),
    );

    return relatedAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Text('Не удалось загрузить'),
      data: (characters) {
        if (characters.isEmpty) {
          return const Text('Нет данных');
        }
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: characters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final c = characters[index];
              return _RelatedCharacterAvatar(
                character: c,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CharacterDetailScreen(character: c),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RelatedCharacterAvatar extends StatelessWidget {
  const _RelatedCharacterAvatar({
    required this.character,
    required this.onTap,
  });

  final Character character;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'character_${character.id}',
              child: CircleAvatar(
                radius: 32,
                backgroundImage: CachedNetworkImageProvider(character.image),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              character.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
