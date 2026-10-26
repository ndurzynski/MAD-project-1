import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'meal_detail.dart';
import 'meal_editor.dart';
import 'purchase_history.dart';
import 'settings.dart';

enum ScreenState {
  homeScreen,
  mealDetail,
  mealEditor,
  purchaseHistory,
  settings,
}

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState() extends State<App> {
  bool isDarkMode = true;

  final ScreenState _currentScreen = ScreenState.homeScreen;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode
          ? ThemeData.dark(useMaterial3: false)
          : ThemeData.light(useMaterial3: false),
      home: switch (_currentScreen) {
        ScreenState.homeScreen => const HomeScreen(),
        ScreenState.mealDetail => const MealDetail(),
        ScreenState.mealEditor => const MealEditor(),
        ScreenState.purchaseHistory => const PurchaseHistory(),
        ScreenState.settings => const Settings(),
      },
    );
  }
}
