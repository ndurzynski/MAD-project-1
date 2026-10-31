import 'package:budget_bites/app_database.dart';
import 'package:budget_bites/home_screen.dart';
import 'package:budget_bites/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class MealDatabase extends AppDatabase {
  MealDatabase({this.empty = false});
  final bool empty;

  @override
  Future<List<Map<String, Object?>>> getMeals() async => empty
      ? []
      : [
          {
            'id': 1,
            'name': 'Pad Thai',
            'category': 'Thai',
            'price_cents': 1000,
          },
          {
            'id': 2,
            'name': 'Sushi',
            'category': 'Japanese',
            'price_cents': 1001,
          },
          {'id': 3, 'name': 'Tacos', 'category': 'Mexican', 'price_cents': 800},
        ];
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('budget and cuisine combine, including custom cuisines', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          isDark: false,
          userBudget: 10,
          maxBudget: 100,
          onBudgetChanged: (_) {},
          database: MealDatabase(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pad Thai'), findsOneWidget);
    expect(find.text('Tacos'), findsOneWidget);
    expect(find.text('Sushi'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mexican').last);
    await tester.pumpAndSettle();
    expect(find.text('Tacos'), findsOneWidget);
    expect(find.text('Pad Thai'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Japanese').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No meals match your budget and cuisine.'),
      findsOneWidget,
    );
    expect(find.text('Sushi'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saves both preferences and restores them on a fresh app', (
    tester,
  ) async {
    await tester.pumpWidget(App(database: MealDatabase()));
    await tester.pumpAndSettle();
    expect(find.textContaining('No meals match your budget'), findsOneWidget);

    // Change the budget on Home, then check that Settings shares it.
    tester.widget<Slider>(find.byType(Slider)).onChanged!(10);
    await tester.pumpAndSettle();
    expect(find.text('Pad Thai'), findsOneWidget);
    final mealCard = find.ancestor(
      of: find.text('Pad Thai'),
      matching: find.byType(Card),
    );
    final regularHeight = tester.getSize(mealCard).height;
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(find.byType(Slider)).value, 10);
    await tester.tap(find.text('Compact Meal Cards'));
    await tester.pumpAndSettle();
    tester.widget<Slider>(find.byType(Slider)).onChanged!(12.34);
    await tester.pumpAndSettle();

    final preferences = SharedPreferencesAsync();
    expect(await preferences.getDouble('user_budget'), 12.34);
    expect(await preferences.getBool('compact_cards'), isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(App(database: MealDatabase()));
    await tester.pumpAndSettle();
    expect(find.text('Meal Budget \$12.34'), findsOneWidget);
    expect(find.text('Sushi'), findsOneWidget);
    expect(tester.getSize(mealCard).height, lessThan(regularHeight));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty database suggests adding a meal', (tester) async {
    await tester.pumpWidget(App(database: MealDatabase(empty: true)));
    await tester.pumpAndSettle();
    expect(
      find.text('No meals yet. Add a meal to get started.'),
      findsOneWidget,
    );
  });

  testWidgets('restored budgets are clamped to the slider range', (
    tester,
  ) async {
    await SharedPreferencesAsync().setDouble('user_budget', 150);
    await tester.pumpWidget(App(database: MealDatabase()));
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(find.byType(Slider)).value, 100);
    expect(tester.takeException(), isNull);
  });
}
