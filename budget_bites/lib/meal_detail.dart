import 'package:budget_bites/main.dart';
import 'package:flutter/material.dart';

class MealDetail extends StatefulWidget {
  final bool isDark;

  const MealDetail({super.key, required this.isDark});

  @override
  State<MealDetail> createState() => _MealDetailState();
}

class _MealDetailState extends State<MealDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text('This is the Meal Detail Screen'));
  }
}
