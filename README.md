# Rick and Morty Characters App

Мобильное приложение на Flutter для просмотра персонажей вселенной Rick and Morty.
Данные загружаются из открытого [Rick and Morty API](https://rickandmortyapi.com).

## Функционал

- **Список персонажей** с двухуровневой пагинацией (порции по 10, подгрузка при скролле 90%)
- **Детальная страница персонажа** — биография, характеристики, эпизоды, связанные персонажи
- **Избранное** — сохранение в Hive, сортировка по имени / статусу / виду, работает оффлайн
- **Оффлайн-кеш** — загруженные персонажи доступны без интернета
- **Тёмная / светлая тема** — переключение с сохранением между запусками
- **Hero-анимация** при переходе на детальную страницу
- **Pull-to-refresh** для обновления списка

### Экраны

| Экран | Описание |
|-------|----------|
| Список персонажей | Грид-список с пагинацией, переключение темы |
| Избранное | Отсортированный список избранных персонажей |
| Детали персонажа | SliverAppBar с Hero-изображением, характеристики, биография, эпизоды, связанные персонажи |

## Архитектура

Clean Architecture, feature-based структура:

```
lib/
├── core/
│   ├── domain/                     # ApiResponse, ApiInfo
│   ├── infrastructure/
│   │   ├── network/                # Dio провайдер
│   │   └── local/                  # HiveService (кеш, избранное)
│   ├── presentation/
│   │   └── theme/                  # AppTheme, ThemeMode провайдер
│   └── utils/                      # AppLogger
│
└── features/characters/
    ├── domain/                     # Character, Episode (Freezed)
    ├── infrastructure/
    │   ├── data_sources/           # CharactersRemoteDataSource
    │   └── repos/                  # CharactersRepository
    └── presentation/
        ├── providers/              # CharactersList, FavoriteCharacters,
        │                           # CharacterEpisodes, RelatedCharacters
        ├── screens/
        │   ├── characters_list/    # Главный экран
        │   ├── favorites/          # Избранное
        │   └── character_detail/   # Детали персонажа
        └── widgets/                # CharacterCard
```

## Требования

| Инструмент | Версия          |
|------------|-----------------|
| Flutter    | 3.32.8 (stable) |
| Dart       | 3.8.1           |
| Dart SDK   | >=3.5.0 <4.0.0  |

## Установка и запуск

```bash
# 1. Клонировать
git clone <repository-url>
cd rick_and_morty_app

# 2. Зависимости
flutter pub get

# 3. Кодогенерация (Freezed, Riverpod, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# 4. Запуск
flutter run                # подключённое устройство
flutter run -d android     # Android
flutter run -d ios         # iOS
flutter run -d chrome      # Web
```

## Зависимости

### Runtime

| Пакет | Версия | Назначение |
|-------|--------|------------|
| hooks_riverpod | ^2.6.1 | State management |
| riverpod_annotation | ^2.3.3 | Кодогенерация провайдеров |
| flutter_hooks | ^0.20.3 | Хуки для виджетов |
| dio | ^5.8.0 | HTTP-клиент |
| connectivity_plus | ^6.1.4 | Проверка сети |
| hive / hive_flutter | ^2.2.3 | Локальное хранилище |
| shared_preferences | ^2.5.3 | Настройки (тема) |
| freezed_annotation | ^2.4.1 | Иммутабельные модели |
| json_annotation | ^4.8.1 | JSON-сериализация |
| cached_network_image | ^3.3.0 | Кеширование изображений |
| fpdart | ^1.1.0 | Either для ошибок |

### Dev

| Пакет | Версия | Назначение |
|-------|--------|------------|
| build_runner | ^2.4.5 | Кодогенерация |
| riverpod_generator | ^2.2.3 | Генерация провайдеров |
| riverpod_lint | ^2.3.7 | Линтер Riverpod |
| freezed | ^2.4.1 | Генерация моделей |
| json_serializable | ^6.7.0 | Генерация fromJson/toJson |
| flutter_lints | ^5.0.0 | Правила анализа |

## Особенности реализации

### Пагинация
- API возвращает 20 персонажей за запрос; отображаются порциями по 10
- Автоматическая подгрузка при прокрутке до 90% списка
- Реактивные `isLoadingMoreProvider` / `hasMoreToShowProvider`

### Кеширование
- Персонажи кешируются в Hive с привязкой к странице (`page_N_id`)
- При потере сети Repository автоматически возвращает кеш
- Изображения — `cached_network_image`

### Детальная страница
- `SliverAppBar` с Hero-анимацией изображения
- Характеристики: пол, вид, тип, происхождение, локация, кол-во эпизодов
- Биография генерируется из данных API
- Эпизоды загружаются пакетно: `/episode/1,2,3`
- Связанные персонажи — из первого эпизода: `/character/1,2,3`

### Избранное
- Отдельный Hive box, сохраняется между перезапусками
- Сортировка через `sortedFavoritesProvider(sortBy)` — реактивный провайдер с параметром

### Темная тема
- `ThemeModeProvider` — async build из SharedPreferences, без вспышки

## Разработка

```bash
# Кодогенерация (разовая)
dart run build_runner build --delete-conflicting-outputs

# Кодогенерация (watch)
dart run build_runner watch --delete-conflicting-outputs

# Анализ
dart analyze

# Форматирование
dart format .

# Тесты
flutter test
```

## API

[Rick and Morty API](https://rickandmortyapi.com/documentation):

| Endpoint | Описание |
|----------|----------|
| `GET /character?page={n}` | Список персонажей (20 на страницу) |
| `GET /character/{id}` | Один персонаж |
| `GET /character/1,2,3` | Несколько персонажей |
| `GET /episode/1,2,3` | Несколько эпизодов |

## TODO

- [x] Загрузка и отображение списка персонажей
- [x] Пагинация (двухуровневая, по 10)
- [x] Добавление/удаление из избранного
- [x] Сохранение избранных в Hive (оффлайн)
- [x] Кеширование списка персонажей (оффлайн)
- [x] Детальная страница персонажа
- [x] Эпизоды и связанные персонажи
- [x] Hero-анимация перехода
- [x] Тёмная / светлая тема
- [x] Сортировка избранного
- [x] Поиск по имени с debounce (400ms)
- [x] Фильтрация по статусу (Alive / Dead / Unknown)
- [x] Оффлайн-баннер (connectivity_plus)
- [x] Unit-тесты (модели, HiveService)
- [x] CI pipeline (GitHub Actions)
- [ ] Widget-тесты (экраны)
- [ ] Локализация (en/ru)

---

**Flutter** 3.32.8 | **Dart** 3.8.1 | 2026
