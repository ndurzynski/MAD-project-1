import 'package:flutter/material.dart';

import 'home_screen.dart';
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
  int _currentScreenIndex = 0;
  double _userBudget = 0;
  final double _userMaxBudget = 100;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode
          ? ThemeData.dark(useMaterial3: false)
          : ThemeData.light(useMaterial3: false),
      home: Scaffold(
        body: IndexedStack(
          index: _currentScreenIndex,
          children: [
            HomeScreen(
              isDark: isDarkMode,
              userBudget: _userBudget,
              maxBudget: _userMaxBudget,
              onBudgetChanged: (value) {
                setState(() {
                  _userBudget = value;
                });
              },
            ),
            PurchaseHistory(isDark: isDarkMode),
            Settings(
              isDark: isDarkMode,
              userBudget: _userBudget,
              maxBudget: _userMaxBudget,
              onBudgetChanged: (value) {
                setState(() {
                  _userBudget = value;
                });
              },
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              _currentScreenIndex = index;
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
