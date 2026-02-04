import 'package:flutter/material.dart' as flutter;
import 'package:flutter/material.dart' hide ThemeMode;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rick_and_morty/core/infrastructure/local/hive_service.dart';
import 'package:rick_and_morty/core/presentation/theme/app_theme.dart';
import 'package:rick_and_morty/features/characters/presentation/screens/characters_list/characters_list_screen.dart';
import 'package:rick_and_morty/features/characters/presentation/screens/favorites/favorites_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize Hive
    ref.watch(hiveServiceProvider);

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Rick and Morty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode == ThemeModeEnum.dark
          ? flutter.ThemeMode.dark
          : flutter.ThemeMode.light,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    CharactersListScreen(),
    FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Персонажи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Избранное',
          ),
        ],
      ),
    );
  }
}
