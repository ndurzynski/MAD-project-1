class CostInput {
  const CostInput(this.id, this.priceCents, this.purchasedAt);

  final int id;
  final int priceCents;
  final DateTime purchasedAt;
}

class CostSuggestion {
  CostSuggestion(List<CostInput> inputs, {required this.hasInvalidInput})
    : inputs = List.unmodifiable(inputs);

  final List<CostInput> inputs;
  final bool hasInvalidInput;

  int? get estimateCents {
    if (hasInvalidInput || inputs.length < 3) return null;
    final sum = inputs.fold<int>(0, (sum, input) => sum + input.priceCents);
    // Nearest cent, halves up. Three integer inputs cannot produce a half tie.
    return sum ~/ 3 + (sum % 3 >= 2 ? 1 : 0);
  }
}

CostSuggestion suggestCost(
  List<Map<String, Object?>> logs, {
  required int mealId,
  required DateTime now,
}) {
  final purchases = <CostInput>[];
  var hasInvalidInput = false;
  for (final row in logs) {
    if (row['meal_id'] != mealId) continue;
    final rawDate = row['purchased_at'];
    final date = rawDate is String ? DateTime.tryParse(rawDate) : null;
    if (date == null) {
      hasInvalidInput = true;
      continue;
    }
    if (date.isAfter(now)) continue;
    final amount = row['price_paid_cents'];
    final id = row['id'];
    if (amount is! int || amount < 0 || id is! int) {
      hasInvalidInput = true;
      continue;
    }
    purchases.add(CostInput(id, amount, date.toUtc()));
  }
  purchases.sort((a, b) {
    final dateOrder = b.purchasedAt.compareTo(a.purchasedAt);
    return dateOrder == 0 ? b.id.compareTo(a.id) : dateOrder;
  });
  return CostSuggestion(
    purchases.take(3).toList(),
    hasInvalidInput: hasInvalidInput,
  );
}
