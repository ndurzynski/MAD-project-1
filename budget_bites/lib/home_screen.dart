import 'package:flutter/material.dart';

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
  String _userCuisine = cuisines.first;

  // TODO: Fix funtionality for Add Meal button. It should swap the screen to Meal Editor Dashboard
  void addMeal() {}

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

          //TODO: Add Add Meal Button
          Center(
            child: ElevatedButton(
              onPressed: addMeal,
              child: Text('+ Add Meal'),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
