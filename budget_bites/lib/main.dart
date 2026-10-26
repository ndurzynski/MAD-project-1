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

class _AppState extends State<App> {
  bool isDarkMode = true;
  bool _isHomeScreen = true;
  int _currentScreenIndex = 0;
  double _userBudget = 0;
  double _userMaxBudget = 100;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode
          ? ThemeData.dark(useMaterial3: false)
          : ThemeData.light(useMaterial3: false),
      home: Scaffold(
        // TODO: Maybe need to fix to ensure data is not lost when exiting without saving
        body: _isHomeScreen
            ? HomeScreen(
                isDark: isDarkMode,
                userBudget: _userBudget,
                maxBudget: _userMaxBudget,
                onBudgetChanged: (value) {
                  setState(() {
                    _userBudget = value;
                  });
                },
              )
            : _currentScreenIndex == 0
            ? MealDetail(isDark: isDarkMode)
            : _currentScreenIndex == 1
            ? PurchaseHistory(isDark: isDarkMode)
            : _currentScreenIndex == 2
            ? Settings(
                isDark: isDarkMode,
                userBudget: _userBudget,
                maxBudget: _userMaxBudget,
                onBudgetChanged: (value) {
                  setState(() {
                    _userBudget = value;
                  });
                },
              )
            : HomeScreen(
                isDark: isDarkMode,
                userBudget: _userBudget,
                maxBudget: _userMaxBudget,
                onBudgetChanged: (value) {
                  setState(() {
                    _userBudget = value;
                  });
                },
              ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              _currentScreenIndex = index;
              _isHomeScreen = false;
            });
          },
          indicatorColor: Colors.amber,
          selectedIndex: _currentScreenIndex,
          destinations: const <Widget>[
            NavigationDestination(icon: Icon(Icons.food_bank), label: 'Meals'),
            NavigationDestination(icon: Icon(Icons.dining), label: 'History'),
            NavigationDestination(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
