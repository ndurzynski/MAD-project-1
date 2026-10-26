import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  final bool isDark;

  const Settings({super.key, required this.isDark});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text('This is the Settings Screen'));
  }
}
