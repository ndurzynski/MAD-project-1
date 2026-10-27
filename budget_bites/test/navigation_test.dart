import 'package:budget_bites/home_screen.dart';
import 'package:budget_bites/main.dart';
import 'package:budget_bites/meal_editor.dart';
import 'package:budget_bites/purchase_history.dart';
import 'package:budget_bites/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navigation tabs show their matching screens', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.byType(PurchaseHistory), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(Settings), findsOneWidget);

    await tester.tap(find.text('Meals'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('+ Add Meal'), findsOneWidget);
  });

  testWidgets('Add Meal validates and returns saved form values', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.tap(find.text('+ Add Meal'));
    await tester.pumpAndSettle();
    expect(find.byType(MealEditor), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a meal name'), findsOneWidget);
    expect(find.byType(MealEditor), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '  Pad Thai  ');
    await tester.enterText(fields.at(1), 'Thai');
    await tester.enterText(fields.at(2), '8.50');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(MealEditor), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Pad Thai'), findsOneWidget);
    expect(find.text('Thai'), findsOneWidget);
    expect(find.text(r'$8.50'), findsOneWidget);

    for (final tab in ['History', 'Settings']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(find.text('Pad Thai'), findsNothing);
      await tester.tap(find.text('Meals'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Pad Thai'), findsOneWidget);
      expect(find.text('Thai'), findsOneWidget);
      expect(find.text(r'$8.50'), findsOneWidget);
    }

    await tester.tap(find.text('+ Add Meal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Cancelled meal');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Pad Thai'), findsOneWidget);
    expect(find.text('Cancelled meal'), findsNothing);
  });

  testWidgets('Back cancels a partially filled meal without a result', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.tap(find.text('+ Add Meal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Cancelled meal');
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(ListTile), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('+ Add Meal'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .initialValue,
      isEmpty,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(ListTile), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returning after the home screen is disposed is safe', (
    tester,
  ) async {
    final showHome = ValueNotifier(true);
    addTearDown(showHome.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: showHome,
          builder: (context, visible, child) => visible
              ? HomeScreen(
                  isDark: false,
                  userBudget: 0,
                  maxBudget: 100,
                  onBudgetChanged: (_) {},
                )
              : const Scaffold(body: Text('Home removed')),
        ),
      ),
    );
    await tester.tap(find.text('+ Add Meal'));
    await tester.pumpAndSettle();
    showHome.value = false;
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Home removed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
