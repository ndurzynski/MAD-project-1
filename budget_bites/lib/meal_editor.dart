import 'package:flutter/material.dart';

class MealEditor extends StatefulWidget {
  final bool isDark;

  const MealEditor({super.key, required this.isDark});

  @override
  State<MealEditor> createState() => _MealEditorState();
}

class _MealEditorState extends State<MealEditor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text('This is the Meal Editor Screen'));
  }
}
