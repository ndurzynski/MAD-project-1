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

  const HomeScreen({super.key, required this.isDark});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final double maxBudget = 100;
  double _userBudget = 0;
  String _userCuisine = cuisines.first;

  // TODO: Fix funtionality for Add Meal button. It should swap the screen to Meal Editor Dashboard
  void addMeal() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Bites')),
      body: ListView(
        children: <Widget>[
          Text('Meal Budget'),
          Row(
            children: [
              Text('\$0'),
              Slider(
                value: _userBudget,
                max: maxBudget,
                min: 0.0,
                onChanged: (double value) {
                  setState(() {
                    _userBudget = value;
                  });
                },
              ),
              Text('\$${maxBudget.toInt()}'),
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
