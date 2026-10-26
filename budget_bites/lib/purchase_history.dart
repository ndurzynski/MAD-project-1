import 'package:flutter/material.dart';

class PurchaseHistory extends StatefulWidget {
  final bool isDark;

  const PurchaseHistory({super.key, required this.isDark});

  @override
  State<PurchaseHistory> createState() => _PurchaseHistoryState();
}

class _PurchaseHistoryState extends State<PurchaseHistory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text('This is the Purchase History Screen'));
  }
}
