# Архитектура проекта

## Общий обзор

Проект построен на основе **Clean Architecture** с разделением на три основных слоя:

1. **Domain** - бизнес-логика и модели
2. **Infrastructure** - работа с данными (API, БД)
3. **Presentation** - UI и state management

## Структура проекта

```
lib/
├── core/                           # Общие компоненты для всего приложения
│   ├── domain/                     # Доменные модели
│   │   └── api_response.dart       # Обертка для API ответов с пагинацией
│   ├── infrastructure/             
│   │   ├── network/                # Сетевой слой
│   │   │   └── dio_provider.dart   # Провайдер для Dio (HTTP клиент)
│   │   └── local/                  # Локальное хранилище
│   │       └── hive_service.dart   # Сервис для работы с Hive БД
│   └── presentation/               
│       ├── theme/                  # Темы приложения
│       │   └── app_theme.dart      # Светлая и темная темы
│       └── widgets/                # Переиспользуемые виджеты
│           └── character_card.dart # Карточка персонажа
│
└── features/                       # Фичи приложения
    └── characters/
        ├── domain/                 # Доменный слой
        │   └── character.dart      # Модель персонажа (Freezed)
        ├── infrastructure/         # Инфраструктурный слой
        │   ├── data_sources/       
        │   │   └── characters_remote_data_source.dart  # API запросы
        │   └── repos/              
        │       └── characters_repository.dart          # Бизнес-логика работы с данными
        └── presentation/           # Презентационный слой
            ├── providers/          
            │   └── characters_provider.dart            # Riverpod провайдеры
            └── screens/            
                ├── characters_list/
                │   └── characters_list_screen.dart     # Экран списка
                └── favorites/
                    └── favorites_screen.dart           # Экран избранного
```

## Слои архитектуры

### 1. Domain Layer (Доменный слой)

**Назначение:** Содержит бизнес-логику и модели данных.

**Особенности:**
- Не зависит от фреймворков и библиотек
- Использует Freezed для создания иммутабельных моделей
- Содержит только чистые Dart классы

**Примеры:**
- `Character` - модель персонажа
- `CharacterLocation` - локация персонажа
- `ApiResponse` - обертка для API ответов

### 2. Infrastructure Layer (Инфраструктурный слой)

**Назначение:** Реализует взаимодействие с внешними источниками данных.

**Компоненты:**

#### Data Sources (Источники данных)
- `CharactersRemoteDataSource` - работа с Rick and Morty API через Dio
- Обработка HTTP запросов и парсинг ответов

#### Repositories (Репозитории)
- `CharactersRepository` - координирует работу между data sources и presentation
- Обрабатывает ошибки через Either (fpdart)
- Управляет кешированием данных
- Реализует логику работы с избранным

#### Local Storage (Локальное хранилище)
- `HiveService` - работа с Hive БД
- Кеширование персонажей для оффлайн-режима
- Хранение избранных персонажей

### 3. Presentation Layer (Презентационный слой)

**Назначение:** Отображение данных и обработка взаимодействия с пользователем.

**Компоненты:**

#### Providers (Провайдеры состояния)
- `CharactersList` - управление списком персонажей
- `FavoriteCharacters` - управление избранными
- `ThemeMode` - управление темой приложения

#### Screens (Экраны)
- `CharactersListScreen` - главный экран с сеткой персонажей
- `FavoritesScreen` - экран избранного с сортировкой

#### Widgets (Виджеты)
- `CharacterCard` - переиспользуемая карточка персонажа
- Анимированная кнопка избранного

## Паттерны проектирования

### Repository Pattern

Репозиторий служит прослойкой между источниками данных и presentation layer:

```dart
class CharactersRepository {
  CharactersRepository({
    required this.remoteDataSource,
    required this.hiveService,
  });

  Future<Either<String, ApiResponse<Character>>> getCharacters() async {
    try {
      final response = await remoteDataSource.getCharacters();
      await hiveService.cacheCharacters(response.results);
      return right(response);
    } catch (e) {
      // Fallback на кеш при ошибке
      final cached = hiveService.getCachedCharacters();
      return cached.isNotEmpty 
        ? right(ApiResponse(results: cached))
        : left(error);
    }
  }
}
```

### Provider Pattern (Riverpod)

Использование Riverpod для управления состоянием:

```dart
@riverpod
class CharactersList extends _$CharactersList {
  @override
  Future<List<Character>> build() async {
    final repository = ref.watch(charactersRepositoryProvider);
    // Загрузка данных
  }
  
  Future<void> loadMore() async {
    // Пагинация
  }
}
```

### Either Pattern (Functional Programming)

Использование Either из fpdart для явной обработки ошибок:

```dart
Future<Either<String, Data>> getData() async {
  try {
    final data = await api.fetch();
    return right(data);  // Успех
  } catch (e) {
    return left(e.toString());  // Ошибка
  }
}
```

## State Management (Riverpod)

### Типы провайдеров

1. **@riverpod** - для сервисов и зависимостей
   ```dart
   @riverpod
   Dio dio(Ref ref) => Dio();
   ```

2. **@riverpod class** - для состояния с логикой
   ```dart
   @riverpod
   class CharactersList extends _$CharactersList {
     // State + Business Logic
   }
   ```

3. **StateProvider** - для простого изменяемого состояния
   ```dart
   final sortByProvider = StateProvider<String>((ref) => 'name');
   ```

### Lifecycle

- Провайдеры автоматически пересоздаются при изменении зависимостей
- `ref.invalidateSelf()` - принудительное обновление
- `ref.watch()` - подписка на изменения
- `ref.read()` - одноразовое чтение без подписки

## Кеширование и оффлайн-режим

### Двухуровневое кеширование

1. **Hive** - для моделей (JSON)
   - Быстрое NoSQL хранилище
   - Персонажи и избранное

2. **cached_network_image** - для изображений
   - Автоматическое кеширование
   - Управление памятью

### Стратегия Cache-First

```dart
Future<Either<String, Data>> getData() async {
  try {
    // Попытка загрузить из сети
    final networkData = await remoteDataSource.fetch();
    await hiveService.cache(networkData);
    return right(networkData);
  } catch (e) {
    // Fallback на кеш
    final cached = hiveService.getCached();
    return cached.isNotEmpty 
      ? right(cached) 
      : left('No connection and no cache');
  }
}
```

## Генерация кода

Проект использует code generation для:

1. **Freezed** - генерация иммутабельных моделей
2. **json_serializable** - JSON сериализация
3. **riverpod_generator** - генерация провайдеров

Команда для генерации:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Тестирование

### Структура тестов

```
test/
├── unit/                   # Unit тесты
│   ├── domain/             # Тесты моделей
│   ├── infrastructure/     # Тесты репозиториев
│   └── presentation/       # Тесты провайдеров
└── widget/                 # Widget тесты
    └── screens/            # Тесты экранов
```

### Mocking

Использование Mockito для создания моков:

```dart
@GenerateMocks([CharactersRepository, HiveService])
void main() {
  late MockCharactersRepository repository;
  
  setUp(() {
    repository = MockCharactersRepository();
  });
}
```

## Производительность

### Оптимизации

1. **Ленивая загрузка** - данные загружаются только при необходимости
2. **Пагинация** - загрузка по 20 персонажей за раз
3. **Кеширование изображений** - уменьшение сетевого трафика
4. **const конструкторы** - оптимизация пересборки виджетов

### Анимации

- `AnimationController` с `useAnimationController` хуком
- Кривые анимации для плавности (elasticOut, easeInOut)
- ScaleTransition для звездочки избранного

## Расширяемость

### Добавление новых фич

1. Создать папку в `features/`
2. Создать подпапки: `domain/`, `infrastructure/`, `presentation/`
3. Следовать существующей структуре
4. Добавить провайдеры и экраны

### Добавление новых источников данных

1. Создать data source в `infrastructure/data_sources/`
2. Добавить в repository
3. Использовать в провайдерах

## Best Practices

1. **Иммутабельность** - использование Freezed для всех моделей
2. **Явная обработка ошибок** - Either вместо try-catch
3. **Dependency Injection** - через Riverpod провайдеры
4. **Разделение ответственности** - каждый слой имеет четкую роль
5. **Code Generation** - избегание boilerplate кода
6. **Типобезопасность** - максимальное использование типов Dart

## Заключение

Архитектура проекта спроектирована для:
- Легкого тестирования
- Масштабируемости
- Поддерживаемости
- Читаемости кода
- Повторного использования компонентов
