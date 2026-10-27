import 'package:flutter/material.dart';

class PurchaseHistory extends StatefulWidget {
  final bool isDark;

  const PurchaseHistory({super.key, required this.isDark});

  @override
  State<PurchaseHistory> createState() => _PurchaseHistoryState();
}

class _PurchaseHistoryState extends State<PurchaseHistory> {
  int daysValue = -1;
  double totalSpent = 0;

  void changeItemHistory() {}

  void addPurchase() {}

  void goBack() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Title
      appBar: AppBar(title: const Text('Purchase History')),
      body: ListView(
        children: <Widget>[
          // DropDownMenu for choosing how many days
          DropdownMenu<String>(
            initialSelection: '-1',
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: '-1', label: 'All Time'),
              DropdownMenuEntry(value: '1', label: 'Past Day'),
              DropdownMenuEntry(value: '3', label: 'Past 3 Days'),
              DropdownMenuEntry(value: '7', label: 'Past Week'),
              DropdownMenuEntry(value: '31', label: 'Past Month'),
            ],
            onSelected: (value) {
              setState(() {
                daysValue = int.tryParse(value ?? '-1') ?? -1;
              });
            },
          ),
          Text('Total Spent: \$${totalSpent.toStringAsFixed(2)}'),
          //TODO: Add each meal as a card for Purchase History

          // DO SOMETHING HERE AAAAAAAAAAAAa
          Center(
            child: ElevatedButton(
              onPressed: addPurchase,
              child: Text('+ Add Purchase'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: goBack,
        child: Text('Back'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
