import 'package:flutter/material.dart';

import 'app_database.dart';

class MealEditor extends StatefulWidget {
  final bool isDark;
  final Map<String, Object?>? meal;
  final AppDatabase? database;

  const MealEditor({super.key, required this.isDark, this.meal, this.database});

  @override
  State<MealEditor> createState() => _MealEditorState();
}

class _MealEditorState extends State<MealEditor> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _venueNote = '';
  String _category = '';
  int _priceCents = 0;
  bool _saving = false;
  String? _error;

  Future<void> _saveMeal() async {
    if (_saving) return;
    final form = _formKey.currentState!;
    if (!form.validate()) return;

    form.save();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final database = widget.database ?? AppDatabase.instance;
      final existingId = widget.meal?['id'] as int?;
      final int id;
      if (existingId == null) {
        id = await database.createMeal(
          name: _name,
          category: _category,
          priceCents: _priceCents,
          venueNote: _venueNote,
        );
      } else {
        await database.updateMeal(
          existingId,
          name: _name,
          category: _category,
          priceCents: _priceCents,
          venueNote: _venueNote,
        );
        id = existingId;
      }
      if (!mounted) return;
      Navigator.of(context).pop({
        'id': id,
        'name': _name,
        'venue_note': _venueNote,
        'category': _category,
        'price_cents': _priceCents,
      });
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
          title: Text(widget.meal == null ? 'Add Meal' : 'Edit Meal'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  readOnly: _saving,
                  initialValue: widget.meal?['name'] as String?,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a meal name';
                    }
                    return null;
                  },
                  onSaved: (value) => _name = value!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  readOnly: _saving,
                  initialValue: widget.meal?['venue_note'] as String?,
                  decoration: const InputDecoration(
                    labelText: 'Venue note',
                    hintText: 'Optional location or restaurant note',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  onSaved: (value) => _venueNote = value?.trim() ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  readOnly: _saving,
                  initialValue: widget.meal?['category'] as String?,
                  decoration: const InputDecoration(labelText: 'Cuisine'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a cuisine';
                    }
                    return null;
                  },
                  onSaved: (value) => _category = value!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  readOnly: _saving,
                  initialValue: widget.meal == null
                      ? null
                      : formatPriceCents(widget.meal!['price_cents'] as int),
                  decoration: const InputDecoration(
                    labelText: 'Estimated price',
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (parsePriceCents(value ?? '') == null) {
                      return 'Enter a nonnegative price with at most 2 decimal places';
                    }
                    return null;
                  },
                  onSaved: (value) => _priceCents = parsePriceCents(value!)!,
                  onFieldSubmitted: (_) => _saveMeal(),
                ),
                const SizedBox(height: 24),
                if (_error != null) Text(_error!),
                ElevatedButton(
                  onPressed: _saving ? null : _saveMeal,
                  child: Text(_saving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
