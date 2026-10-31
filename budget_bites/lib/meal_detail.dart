import 'package:flutter/material.dart';

import 'app_database.dart';
import 'meal_editor.dart';
import 'purchase_editor.dart';

enum _ActivityState { ready, planning, recorded, finished }

class MealDetail extends StatefulWidget {
  final bool isDark;
  final Map<String, Object?> meal;
  final AppDatabase database;

  const MealDetail({
    super.key,
    required this.isDark,
    required this.meal,
    required this.database,
  });

  @override
  State<MealDetail> createState() => _MealDetailState();
}

class _MealDetailState extends State<MealDetail> {
  late Map<String, Object?> _meal;
  _ActivityState _activity = _ActivityState.ready;
  int? _planEstimateCents;
  int? _actualCents;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _meal = Map.of(widget.meal);
  }

  void _startPlan() {
    if (_busy || _activity != _ActivityState.ready) return;
    setState(() {
      _planEstimateCents = _meal['price_cents'] as int;
      _activity = _ActivityState.planning;
    });
  }

  Future<void> _editMeal() async {
    if (_busy) return;
    setState(() => _busy = true);
    final meal = await Navigator.push<Map<String, Object?>>(
      context,
      MaterialPageRoute<Map<String, Object?>>(
        builder: (context) => MealEditor(
          isDark: widget.isDark,
          meal: _meal,
          database: widget.database,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (meal != null) _meal = meal;
      _busy = false;
    });
  }

  Future<void> _recordPurchase() async {
    if (_busy || _activity != _ActivityState.planning) return;
    setState(() => _busy = true);
    final actualCents = await Navigator.push<int>(
      context,
      MaterialPageRoute<int>(
        builder: (context) => PurchaseEditor(
          database: widget.database,
          meals: [_meal],
          initialMealId: _meal['id'] as int,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (actualCents != null) {
        _actualCents = actualCents;
        _activity = _ActivityState.recorded;
      }
      _busy = false;
    });
  }

  Future<void> _reset() async {
    if (_busy) return;
    setState(() => _busy = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset activity?'),
        content: const Text(
          'Clear this activity? Saved purchases will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      if (confirmed == true) {
        _activity = _ActivityState.ready;
        _planEstimateCents = null;
        _actualCents = null;
      }
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canStart = !_busy && _activity == _ActivityState.ready;
    final status = switch (_activity) {
      _ActivityState.ready => 'Ready to plan',
      _ActivityState.planning => 'Plan started',
      _ActivityState.recorded => 'Purchase recorded',
      _ActivityState.finished => 'Finished',
    };
    final difference = _actualCents == null
        ? null
        : _actualCents! - _planEstimateCents!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Detail'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _editMeal,
            child: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _meal['name'] as String,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text('Venue note: ${_meal['venue_note'] ?? ''}'),
          Text('Cuisine: ${_meal['category']}'),
          Text(
            'Estimated price: \$${formatPriceCents(_meal['price_cents'] as int)}',
          ),
          Semantics(
            hint: canStart
                ? 'Long press to start, or use the Start plan button.'
                : null,
            onLongPress: canStart ? _startPlan : null,
            child: GestureDetector(
              excludeFromSemantics: true,
              onLongPress: canStart ? _startPlan : null,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(status),
                ),
              ),
            ),
          ),
          if (_actualCents != null) ...[
            Text('Plan estimate: \$${formatPriceCents(_planEstimateCents!)}'),
            Text('Actual price: \$${formatPriceCents(_actualCents!)}'),
            Text(
              'Difference (actual - estimate): ${difference! < 0 ? '-' : '+'}\$${formatPriceCents(difference.abs())}',
            ),
          ],
          if (_activity == _ActivityState.ready)
            ElevatedButton(
              onPressed: canStart ? _startPlan : null,
              child: const Text('Start plan'),
            ),
          if (_activity == _ActivityState.planning)
            ElevatedButton(
              onPressed: _busy ? null : _recordPurchase,
              child: const Text('Record purchase'),
            ),
          if (_activity == _ActivityState.recorded)
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : () => setState(() => _activity = _ActivityState.finished),
              child: const Text('Finish'),
            ),
          if (_activity != _ActivityState.ready)
            TextButton(
              onPressed: _busy ? null : _reset,
              child: const Text('Reset'),
            ),
        ],
      ),
    );
  }
}
