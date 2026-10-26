import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  final bool isDark;
  final double userBudget;
  final ValueChanged<double> onBudgetChanged;
  final double maxBudget;

  const Settings({
    super.key,
    required this.isDark,
    required this.userBudget,
    required this.onBudgetChanged,
    required this.maxBudget,
  });

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _isCompact = false;

  void saveSetting() {}

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
          Row(
            children: [
              Checkbox(
                value: _isCompact,
                onChanged: (bool? value) {
                  setState(() {
                    _isCompact = value!;
                  });
                },
              ),
              Text('Compact Meal Cards'),
            ],
          ),

          Center(
            child: ElevatedButton(onPressed: saveSetting, child: Text('Save')),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
