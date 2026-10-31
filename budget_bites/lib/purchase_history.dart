import 'package:flutter/material.dart';

import 'app_database.dart';
import 'purchase_editor.dart';

class PurchaseHistory extends StatefulWidget {
  final bool isDark;
  final bool isActive;
  final AppDatabase? database;

  const PurchaseHistory({
    super.key,
    required this.isDark,
    this.isActive = true,
    this.database,
  });

  @override
  State<PurchaseHistory> createState() => _PurchaseHistoryState();
}

class _PurchaseHistoryState extends State<PurchaseHistory> {
  int _days = -1;
  List<Map<String, Object?>> _purchases = [];
  bool _loading = false;
  bool _busy = false;
  String? _error;

  AppDatabase get _database => widget.database ?? AppDatabase.instance;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _loadPurchases();
  }

  @override
  void didUpdateWidget(covariant PurchaseHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final purchases = await _database.getPurchaseLogs();
      if (mounted) setState(() => _purchases = purchases);
    } on AppDatabaseException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editPurchase([Map<String, Object?>? purchase]) async {
    if (_busy || _loading) return;
    setState(() => _busy = true);
    try {
      final meals = await _database.getMeals();
      if (!mounted) return;
      if (meals.isEmpty) {
        _showError('Add a meal before recording a purchase.');
        return;
      }
      final savedPrice = await Navigator.push<int>(
        context,
        MaterialPageRoute<int>(
          builder: (context) => PurchaseEditor(
            database: _database,
            meals: meals,
            purchase: purchase,
          ),
        ),
      );
      if (mounted && savedPrice != null) await _loadPurchases();
    } on AppDatabaseException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deletePurchase(Map<String, Object?> purchase) async {
    if (_busy || _loading) return;
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete purchase?'),
          content: Text('Delete the purchase of "${purchase['meal_name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      await _database.deletePurchaseLog(purchase['id'] as int);
      if (mounted) await _loadPurchases();
    } on AppDatabaseException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: _days));
    final purchases = _purchases.where((purchase) {
      if (_days == -1) return true;
      final date = DateTime.parse(purchase['purchased_at'] as String);
      return !date.isBefore(cutoff) && !date.isAfter(now);
    }).toList();
    final totalCents = purchases.fold<int>(
      0,
      (total, purchase) => total + (purchase['price_paid_cents'] as int),
    );
    final disabled = _busy || _loading;
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownMenu<int>(
            initialSelection: -1,
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: -1, label: 'All Time'),
              DropdownMenuEntry(value: 1, label: 'Past Day'),
              DropdownMenuEntry(value: 3, label: 'Past 3 Days'),
              DropdownMenuEntry(value: 7, label: 'Past Week'),
              DropdownMenuEntry(value: 31, label: 'Past Month'),
            ],
            onSelected: (value) {
              if (value != null) setState(() => _days = value);
            },
          ),
          if (!_loading && _error == null)
            Text('Total Spent: \$${formatPriceCents(totalCents)}'),
          Center(
            child: ElevatedButton(
              onPressed: disabled ? null : () => _editPurchase(),
              child: const Text('+ Add Purchase'),
            ),
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: _loadPurchases, child: const Text('Retry')),
          ] else if (purchases.isEmpty)
            Text(
              _purchases.isEmpty
                  ? 'No purchases yet. Add a purchase to get started.'
                  : 'No purchases in this date range.',
            )
          else
            for (final purchase in purchases)
              ListTile(
                onTap: disabled ? null : () => _editPurchase(purchase),
                title: Text(purchase['meal_name'] as String),
                subtitle: Text(
                  '${purchase['meal_category']} · '
                  '${DateTime.parse(purchase['purchased_at'] as String).toLocal().toIso8601String().split('T').first}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${formatPriceCents(purchase['price_paid_cents'] as int)}',
                    ),
                    IconButton(
                      tooltip: 'Delete purchase',
                      onPressed: disabled
                          ? null
                          : () => _deletePurchase(purchase),
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
