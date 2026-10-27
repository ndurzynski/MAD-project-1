import 'package:flutter/material.dart';

class MealEditor extends StatefulWidget {
  final bool isDark;
  final Map<String, Object>? meal;

  const MealEditor({super.key, required this.isDark, this.meal});

  @override
  State<MealEditor> createState() => _MealEditorState();
}

class _MealEditorState extends State<MealEditor> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _category = '';
  double _price = 0;

  void _saveMeal() {
    final form = _formKey.currentState!;
    if (!form.validate()) return;

    form.save();
    Navigator.of(context)
        .pop({'name': _name, 'category': _category, 'price': _price});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                initialValue: widget.meal?['category'] as String?,
                decoration: const InputDecoration(labelText: 'Category'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a category';
                  }
                  return null;
                },
                onSaved: (value) => _category = value!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: widget.meal?['price']?.toString(),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  final price = double.tryParse(value?.trim() ?? '');
                  if (price == null || !price.isFinite || price < 0) {
                    return 'Enter a valid price of 0 or more';
                  }
                  return null;
                },
                onSaved: (value) => _price = double.parse(value!.trim()),
                onFieldSubmitted: (_) => _saveMeal(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _saveMeal, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
