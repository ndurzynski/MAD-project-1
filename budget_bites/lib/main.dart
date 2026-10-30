import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';
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
  const App({super.key, this.database});

  final AppDatabase? database;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool isDarkMode = true;
  int _currentScreenIndex = 0;
  double _userBudget = 0;
  final double _userMaxBudget = 100;
  bool _isCompact = false;
  bool _loadingPreferences = true;
  late final SharedPreferencesAsync _preferences;
  Future<void> _pendingSave = Future<void>.value();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _preferences = SharedPreferencesAsync();
    _restorePreferences();
  }

  Future<void> _restorePreferences() async {
    try {
      final budget = await _preferences.getDouble('user_budget');
      final compact = await _preferences.getBool('compact_cards');
      if (!mounted) return;
      setState(() {
        _userBudget = budget != null && budget.isFinite
            ? budget.clamp(0, _userMaxBudget).toDouble()
            : 0;
        _isCompact = compact ?? false;
      });
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showPreferenceError('Could not restore settings. Using defaults.');
        }
      });
    } finally {
      if (mounted) setState(() => _loadingPreferences = false);
    }
  }

  void _showPreferenceError(String message) {
    _messengerKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  void _savePreferences() {
    final budget = _userBudget;
    final compact = _isCompact;
    // Keep rapid slider changes in order so an older write cannot win.
    _pendingSave = _pendingSave.then((_) async {
      try {
        await _preferences.setDouble('user_budget', budget);
        await _preferences.setBool('compact_cards', compact);
      } catch (_) {
        if (mounted) {
          _showPreferenceError('Could not save settings. Please try again.');
        }
      }
    });
  }

  void _changeBudget(double value) {
    setState(() => _userBudget = (value * 100).round() / 100);
    _savePreferences();
  }

  void _changeCompact(bool value) {
    setState(() => _isCompact = value);
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      theme: isDarkMode
          ? ThemeData.dark(useMaterial3: false)
          : ThemeData.light(useMaterial3: false),
      home: _loadingPreferences
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : Scaffold(
              body: IndexedStack(
                index: _currentScreenIndex,
                children: [
                  HomeScreen(
                    isDark: isDarkMode,
                    userBudget: _userBudget,
                    maxBudget: _userMaxBudget,
                    onBudgetChanged: _changeBudget,
                    isCompact: _isCompact,
                    database: widget.database,
                  ),
                  PurchaseHistory(isDark: isDarkMode),
                  Settings(
                    isDark: isDarkMode,
                    userBudget: _userBudget,
                    maxBudget: _userMaxBudget,
                    onBudgetChanged: _changeBudget,
                    isCompact: _isCompact,
                    onCompactChanged: _changeCompact,
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
                  NavigationDestination(
                    icon: Icon(Icons.food_bank),
                    label: 'Meals',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.dining),
                    label: 'History',
                  ),
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
