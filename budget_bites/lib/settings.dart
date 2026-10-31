import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  final bool isDark;
  final double userBudget;
  final ValueChanged<double> onBudgetChanged;
  final double maxBudget;
  final bool isCompact;
  final ValueChanged<bool> onCompactChanged;

  const Settings({
    super.key,
    required this.isDark,
    required this.userBudget,
    required this.onBudgetChanged,
    required this.maxBudget,
    required this.isCompact,
    required this.onCompactChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Bites')),
      body: ListView(
        children: <Widget>[
          Text('Meal Budget \$${userBudget.toStringAsFixed(2)}'),
          Row(
            children: [
              Text('\$0'),
              Expanded(
                child: Slider(
                  value: userBudget,
                  max: maxBudget,
                  divisions: (maxBudget * 100).round(),
                  min: 0.0,
                  onChanged: (double value) {
                    onBudgetChanged(value);
                  },
                ),
              ),
              Text('\$${maxBudget.toInt()}'),
            ],
          ),
          CheckboxListTile(
            title: const Text('Compact Meal Cards'),
            value: isCompact,
            onChanged: (value) {
              if (value != null) onCompactChanged(value);
            },
          ),

          const Center(child: Text('Settings are saved automatically.')),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
