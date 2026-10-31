import 'package:flutter/material.dart';

import 'app_database.dart';
import 'meal_detail.dart';
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
  final bool isCompact;

  const HomeScreen({
    super.key,
    required this.isDark,
    required this.userBudget,
    required this.onBudgetChanged,
    required this.maxBudget,
    this.database,
    this.isCompact = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userCuisine = cuisines.first;
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

  Future<void> _openMealDetail(Map<String, Object?> meal) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            MealDetail(isDark: widget.isDark, meal: meal, database: _database),
      ),
    );
    if (mounted) await _loadMeals();
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
    final budgetCents = (widget.userBudget * 100).round();
    final filteredMeals = _meals.where((meal) {
      return (meal['price_cents'] as int) <= budgetCents &&
          (_userCuisine == 'All' ||
              (meal['category'] as String).trim().toLowerCase() ==
                  _userCuisine.toLowerCase());
    }).toList();
    // The editor accepts custom cuisines, so include them in the filter too.
    final cuisineOptions = <String, String>{
      for (final cuisine in cuisines) cuisine.toLowerCase(): cuisine,
    };
    for (final meal in _meals) {
      final cuisine = (meal['category'] as String).trim();
      cuisineOptions.putIfAbsent(cuisine.toLowerCase(), () => cuisine);
    }
    cuisineOptions.putIfAbsent(_userCuisine.toLowerCase(), () => _userCuisine);
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Bites')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Meal Budget \$${widget.userBudget.toStringAsFixed(2)}'),
          Row(
            children: [
              Text('\$0'),
              Expanded(
                child: Slider(
                  value: widget.userBudget,
                  divisions: (widget.maxBudget * 100).round(),
                  max: widget.maxBudget,
                  min: 0.0,
                  onChanged: (double value) {
                    widget.onBudgetChanged(value);
                  },
                ),
              ),
              Text('\$${widget.maxBudget.toInt()}'),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: _userCuisine,
            decoration: const InputDecoration(labelText: 'Cuisine'),
            items: [
              for (final cuisine in cuisineOptions.values)
                DropdownMenuItem(value: cuisine, child: Text(cuisine)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _userCuisine = value);
            },
          ),

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
          if (!_loading && _loadError == null && filteredMeals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                _meals.isEmpty
                    ? 'No meals yet. Add a meal to get started.'
                    : 'No meals match your budget and cuisine. '
                          'Increase your budget or choose another cuisine.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final meal in filteredMeals)
            Card(
              key: ValueKey(meal['id']),
              margin: EdgeInsets.symmetric(vertical: widget.isCompact ? 2 : 8),
              child: ListTile(
                dense: widget.isCompact,
                visualDensity: widget.isCompact
                    ? VisualDensity.compact
                    : VisualDensity.standard,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: widget.isCompact ? 0 : 12,
                ),
                onTap: _loading || _deleting
                    ? null
                    : () => _openMealDetail(meal),
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
            ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
