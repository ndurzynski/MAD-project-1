import 'package:flutter/material.dart';

import 'app_database.dart';
import 'meal_editor.dart';

const List<String> cuisines = [
  'All',
  'Thai',
  'Spanish',
  'American',
  'Chinese',
  'Japanese',
];

class HomeScreen extends StatefulWidget {
  final bool isDark;
  final double userBudget;
  final ValueChanged<double> onBudgetChanged;
  final double maxBudget;
  final AppDatabase? database;

  const HomeScreen({
    super.key,
    required this.isDark,
    required this.userBudget,
    required this.onBudgetChanged,
    required this.maxBudget,
    this.database,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _userCuisine = cuisines.first;
  final List<Map<String, Object?>> _meals = [];
  bool _loading = true;
  bool _deleting = false;
  String? _loadError;

  AppDatabase get _database => widget.database ?? AppDatabase.instance;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final meals = await _database.getMeals();
      if (!mounted) return;
      setState(() {
        _meals
          ..clear()
          ..addAll(meals);
      });
    } on AppDatabaseException catch (error) {
      if (mounted) setState(() => _loadError = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMealEditor([Map<String, Object?>? existingMeal]) async {
    final meal = await Navigator.push<Map<String, Object?>>(
      context,
      MaterialPageRoute<Map<String, Object?>>(
        builder: (context) => MealEditor(
          isDark: widget.isDark,
          meal: existingMeal,
          database: _database,
        ),
      ),
    );

    if (!mounted || meal == null) return;

    setState(() {
      final index = _meals.indexWhere((item) => item['id'] == meal['id']);
      if (index == -1) {
        _meals.add(meal);
      } else {
        _meals[index] = meal;
      }
    });
  }

  Future<void> _deleteMeal(Map<String, Object?> meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete meal?'),
        content: Text('Delete "${meal['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _database.deleteMeal(meal['id'] as int);
      if (!mounted) return;
      setState(() => _meals.removeWhere((item) => item['id'] == meal['id']));
    } on AppDatabaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Bites')),
      body: ListView(
        children: <Widget>[
          Text('Meal Budget \$${widget.userBudget.toStringAsFixed(2)}'),
          Row(
            children: [
              Text('\$0'),
              Slider(
                value: widget.userBudget,
                max: widget.maxBudget,
                min: 0.0,
                onChanged: (double value) {
                  widget.onBudgetChanged(value);
                },
              ),
              Text('\$${widget.maxBudget.toInt()}'),
            ],
          ),
          //TODO: DropdownMenu
          // DropdownMenu(dropdownMenuEntries: cuisines),
          //TODO: List All meals that fit the budget and current cuisine

          Center(
            child: ElevatedButton(
              onPressed: _loading || _deleting || _loadError != null
                  ? null
                  : () => _openMealEditor(),
              child: Text('+ Add Meal'),
            ),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_loadError != null) ...[
            Text(_loadError!),
            TextButton(onPressed: _loadMeals, child: const Text('Retry')),
          ],
          for (final meal in _meals)
            ListTile(
              key: ValueKey(meal['id']),
              onTap: _loading || _deleting ? null : () => _openMealEditor(meal),
              title: Text(meal['name'] as String),
              subtitle: Text(meal['category'] as String),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('\$${formatPriceCents(meal['price_cents'] as int)}'),
                  IconButton(
                    tooltip: 'Delete meal',
                    onPressed: _loading || _deleting
                        ? null
                        : () => _deleteMeal(meal),
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
            ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
