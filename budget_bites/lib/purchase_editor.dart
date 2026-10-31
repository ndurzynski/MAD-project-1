import 'package:flutter/material.dart';

import 'app_database.dart';

class PurchaseEditor extends StatefulWidget {
  final AppDatabase database;
  final List<Map<String, Object?>> meals;
  final Map<String, Object?>? purchase;
  final int? initialMealId;

  const PurchaseEditor({
    super.key,
    required this.database,
    required this.meals,
    this.purchase,
    this.initialMealId,
  });

  @override
  State<PurchaseEditor> createState() => _PurchaseEditorState();
}

class _PurchaseEditorState extends State<PurchaseEditor> {
  final _formKey = GlobalKey<FormState>();
  int? _mealId;
  int _priceCents = 0;
  late DateTime _date;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mealId = widget.purchase?['meal_id'] as int? ?? widget.initialMealId;
    _date = widget.purchase == null
        ? DateTime.now()
        : DateTime.parse(widget.purchase!['purchased_at'] as String).toLocal();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year < 1900 ? _date.year : 1900),
      lastDate: DateTime(_date.year > 2100 ? _date.year : 2100, 12, 31),
    );
    if (mounted && date != null) setState(() => _date = date);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = widget.purchase?['id'] as int?;
      if (id == null) {
        await widget.database.createPurchaseLog(
          mealId: _mealId!,
          pricePaidCents: _priceCents,
          purchasedAt: _date,
        );
      } else {
        await widget.database.updatePurchaseLog(
          id,
          mealId: _mealId == widget.purchase!['meal_id'] ? null : _mealId,
          pricePaidCents: _priceCents,
          purchasedAt: _date,
        );
      }
      if (mounted) Navigator.pop(context, _priceCents);
    } on AppDatabaseException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.purchase == null ? 'Add Purchase' : 'Edit Purchase',
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<int>(
                initialValue: _mealId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Meal'),
                items: [
                  for (final meal in widget.meals)
                    DropdownMenuItem(
                      value: meal['id'] as int,
                      child: Text('${meal['name']} (${meal['category']})'),
                    ),
                ],
                onChanged: _saving ? null : (value) => _mealId = value,
                validator: (value) => value == null ? 'Select a meal' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: _saving,
                initialValue: widget.purchase == null
                    ? ''
                    : formatPriceCents(
                        widget.purchase!['price_paid_cents'] as int,
                      ),
                decoration: const InputDecoration(
                  labelText: 'Actual price',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) => parsePriceCents(value ?? '') == null
                    ? 'Enter a nonnegative price with at most 2 decimal places'
                    : null,
                onSaved: (value) => _priceCents = parsePriceCents(value!)!,
                onFieldSubmitted: (_) => _save(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Purchase date'),
                subtitle: Text(
                  MaterialLocalizations.of(context).formatMediumDate(_date),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _saving ? null : _pickDate,
              ),
              if (_error != null) Text(_error!),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
