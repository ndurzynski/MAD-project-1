import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final bool isDark;

  const HomeScreen({super.key, required this.isDark});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Bites')),
      body: Center(),
      backgroundColor: Colors.black,
    );
  }
}
