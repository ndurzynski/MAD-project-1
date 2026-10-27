import 'package:flutter/material.dart';

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

  const HomeScreen({
    super.key,
    required this.isDark,
    required this.userBudget,
    required this.onBudgetChanged,
    required this.maxBudget,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _userCuisine = cuisines.first;
  final List<Map<String, Object>> _meals = [];

  Future<void> _openMealEditor([int? index]) async {
    final meal = await Navigator.push<Map<String, Object>>(
      context,
      MaterialPageRoute<Map<String, Object>>(
        builder: (context) => MealEditor(
          isDark: widget.isDark,
          meal: index == null ? null : _meals[index],
        ),
      ),
    );

    if (!mounted || meal == null) return;

    setState(() {
      if (index == null) {
        _meals.add(meal);
      } else {
        _meals[index] = meal;
      }
    });
  }

  Future<void> _deleteMeal(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete meal?'),
        content: Text('Delete "${_meals[index]['name']}"?'),
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

    setState(() {
      _meals.removeAt(index);
    });
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
              onPressed: () => _openMealEditor(),
              child: Text('+ Add Meal'),
            ),
          ),
          for (var index = 0; index < _meals.length; index++)
            ListTile(
              onTap: () => _openMealEditor(index),
              title: Text(_meals[index]['name'] as String),
              subtitle: Text(_meals[index]['category'] as String),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\$${(_meals[index]['price'] as double).toStringAsFixed(2)}',
                  ),
                  IconButton(
                    tooltip: 'Delete meal',
                    onPressed: () => _deleteMeal(index),
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
