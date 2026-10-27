import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// Parses dollar input without passing money through a double.
int? parsePriceCents(String input) {
  final value = input.trim();
  if (!RegExp(r'^(?:\d+(?:\.\d{0,2})?|\.\d{1,2})$').hasMatch(value)) {
    return null;
  }
  final parts = value.split('.');
  final dollars = parts.first.isEmpty ? '0' : parts.first;
  final cents = (parts.length == 2 ? parts[1] : '').padRight(2, '0');
  return int.tryParse('$dollars$cents');
}

String formatPriceCents(int cents) =>
    '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

class AppDatabaseException implements Exception {
  final String message;
  final Object? cause;

  const AppDatabaseException(this.message, [this.cause]);

  @override
  String toString() => message;
}

/// Shared storage. Inject a factory and file path only for isolated tests.
class AppDatabase {
  static final instance = AppDatabase();

  AppDatabase({this.factory, String? databasePath}) : _path = databasePath;

  final DatabaseFactory? factory;
  final String? _path;
  Future<Database>? _opening;

  Future<Database> _open() async {
    final selectedFactory = factory ?? databaseFactory;
    final file =
        _path ??
        path.join(await selectedFactory.getDatabasesPath(), 'budget_bites.db');
    return selectedFactory.openDatabase(
      file,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _createSchema(db),
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _upgradeToV2(db);
        },
      ),
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
            CREATE TABLE meals (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL CHECK(length(trim(name)) > 0),
              venue_note TEXT NOT NULL DEFAULT '',
              category TEXT NOT NULL CHECK(length(trim(category)) > 0),
              price_cents INTEGER NOT NULL
                CHECK(typeof(price_cents) = 'integer' AND price_cents >= 0)
            )
          ''');
    await db.execute('''
            CREATE TABLE purchase_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              meal_id INTEGER REFERENCES meals(id) ON DELETE RESTRICT,
              meal_name TEXT NOT NULL,
              meal_category TEXT NOT NULL,
              price_paid_cents INTEGER NOT NULL
                CHECK(typeof(price_paid_cents) = 'integer' AND price_paid_cents >= 0),
              purchased_at TEXT NOT NULL
            )
          ''');
    await db.execute(
      'CREATE INDEX purchase_logs_meal_id ON purchase_logs(meal_id)',
    );
  }

  // sqflite runs onUpgrade inside a transaction. Rebuild both tables so the
  // column types and foreign-key rule change together, preserving existing IDs.
  Future<void> _upgradeToV2(Database db) async {
    final sequences = await db.query(
      'sqlite_sequence',
      where: 'name IN (?, ?)',
      whereArgs: ['meals', 'purchase_logs'],
    );
    await db.execute('ALTER TABLE meals RENAME TO meals_v1');
    await db.execute('ALTER TABLE purchase_logs RENAME TO purchase_logs_v1');
    await db.execute('DROP INDEX purchase_logs_meal_id');
    await _createSchema(db);
    await db.execute('''
      INSERT INTO meals (id, name, venue_note, category, price_cents)
      SELECT id, name, '', category, CAST(ROUND(price * 100) AS INTEGER)
      FROM meals_v1
    ''');
    await db.execute('''
      INSERT INTO purchase_logs
        (id, meal_id, meal_name, meal_category, price_paid_cents, purchased_at)
      SELECT id, meal_id, meal_name, meal_category,
        CAST(ROUND(price_paid * 100) AS INTEGER), purchased_at
      FROM purchase_logs_v1
    ''');
    await db.execute('DROP TABLE purchase_logs_v1');
    await db.execute('DROP TABLE meals_v1');
    // Preserve high-water marks even if the highest IDs were already deleted.
    for (final row in sequences) {
      await db.delete(
        'sqlite_sequence',
        where: 'name = ?',
        whereArgs: [row['name']],
      );
      await db.insert('sqlite_sequence', row);
    }
  }

  Future<Database> get _database async {
    final opening = _opening ??= _open();
    try {
      return await opening;
    } catch (_) {
      // A failed open must not prevent a later retry.
      if (identical(_opening, opening)) _opening = null;
      rethrow;
    }
  }

  Future<T> _run<T>(
    String action,
    Future<T> Function(Database) operation,
  ) async {
    try {
      return await operation(await _database);
    } on AppDatabaseException {
      rethrow;
    } on Exception catch (error) {
      throw AppDatabaseException('Could not $action. Please try again.', error);
    }
  }

  Map<String, Object> _mealValues(
    String name,
    String category,
    int priceCents,
    String venueNote,
  ) {
    if (name.trim().isEmpty || category.trim().isEmpty) {
      throw ArgumentError('Meal name and category are required.');
    }
    _validateCents(priceCents);
    return {
      'name': name.trim(),
      'venue_note': venueNote.trim(),
      'category': category.trim(),
      'price_cents': priceCents,
    };
  }

  void _validateCents(int cents) {
    if (cents < 0) {
      throw ArgumentError('Price must be nonnegative integer cents.');
    }
  }

  String _timestamp(DateTime value) {
    final utc = value.toUtc();
    final iso = utc.toIso8601String();
    // Fixed fractional precision keeps TEXT ordering chronological.
    return utc.microsecond == 0
        ? '${iso.substring(0, iso.length - 1)}000Z'
        : iso;
  }

  void _requireRow(int count, String item) {
    if (count == 0) throw AppDatabaseException('$item no longer exists.');
  }

  Future<int> createMeal({
    required String name,
    required String category,
    required int priceCents,
    String venueNote = '',
  }) {
    final values = _mealValues(name, category, priceCents, venueNote);
    return _run('save the meal', (db) => db.insert('meals', values));
  }

  Future<List<Map<String, Object?>>> getMeals() =>
      _run('load meals', (db) => db.query('meals', orderBy: 'id'));

  Future<Map<String, Object?>?> getMeal(int id) =>
      _run('load the meal', (db) async {
        final rows = await db.query('meals', where: 'id = ?', whereArgs: [id]);
        return rows.isEmpty ? null : rows.single;
      });

  Future<void> updateMeal(
    int id, {
    required String name,
    required String category,
    required int priceCents,
    String venueNote = '',
  }) {
    final values = _mealValues(name, category, priceCents, venueNote);
    return _run('update the meal', (db) async {
      _requireRow(
        await db.update('meals', values, where: 'id = ?', whereArgs: [id]),
        'The meal',
      );
    });
  }

  Future<void> deleteMeal(int id) => _run(
    'delete the meal',
    (db) => db.transaction((txn) async {
      final logs = await txn.query(
        'purchase_logs',
        columns: ['id'],
        where: 'meal_id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (logs.isNotEmpty) {
        throw const AppDatabaseException(
          'This meal has purchase logs and cannot be deleted. '
          'Its purchase history must be kept.',
        );
      }
      _requireRow(
        await txn.delete('meals', where: 'id = ?', whereArgs: [id]),
        'The meal',
      );
    }),
  );

  Future<Map<String, Object?>> _mealSnapshot(
    DatabaseExecutor db,
    int mealId,
  ) async {
    final rows = await db.query('meals', where: 'id = ?', whereArgs: [mealId]);
    if (rows.isEmpty) {
      throw const AppDatabaseException('The meal no longer exists.');
    }
    return {
      'meal_id': mealId,
      'meal_name': rows.single['name'],
      'meal_category': rows.single['category'],
    };
  }

  Future<int> createPurchaseLog({
    required int mealId,
    required int pricePaidCents,
    DateTime? purchasedAt,
  }) {
    _validateCents(pricePaidCents);
    final timestamp = _timestamp(purchasedAt ?? DateTime.now());
    return _run(
      'save the purchase log',
      (db) => db.transaction((txn) async {
        final values = await _mealSnapshot(txn, mealId);
        return txn.insert('purchase_logs', {
          ...values,
          'price_paid_cents': pricePaidCents,
          'purchased_at': timestamp,
        });
      }),
    );
  }

  Future<List<Map<String, Object?>>> getPurchaseLogs({int? mealId}) => _run(
    'load purchase logs',
    (db) => db.query(
      'purchase_logs',
      where: mealId == null ? null : 'meal_id = ?',
      whereArgs: mealId == null ? null : [mealId],
      orderBy: 'purchased_at DESC, id DESC',
    ),
  );

  Future<Map<String, Object?>?> getPurchaseLog(int id) =>
      _run('load the purchase log', (db) async {
        final rows = await db.query(
          'purchase_logs',
          where: 'id = ?',
          whereArgs: [id],
        );
        return rows.isEmpty ? null : rows.single;
      });

  /// Keeps the original meal snapshot when mealId is omitted. Supplying a new
  /// mealId relinks the log and refreshes its name and category snapshot.
  Future<void> updatePurchaseLog(
    int id, {
    required int pricePaidCents,
    required DateTime purchasedAt,
    int? mealId,
  }) {
    _validateCents(pricePaidCents);
    return _run(
      'update the purchase log',
      (db) => db.transaction((txn) async {
        final values = <String, Object?>{
          'price_paid_cents': pricePaidCents,
          'purchased_at': _timestamp(purchasedAt),
          if (mealId != null) ...await _mealSnapshot(txn, mealId),
        };
        _requireRow(
          await txn.update(
            'purchase_logs',
            values,
            where: 'id = ?',
            whereArgs: [id],
          ),
          'The purchase log',
        );
      }),
    );
  }

  Future<void> deletePurchaseLog(int id) =>
      _run('delete the purchase log', (db) async {
        _requireRow(
          await db.delete('purchase_logs', where: 'id = ?', whereArgs: [id]),
          'The purchase log',
        );
      });

  /// Screens share [instance] and leave it open. Tests can close and reopen files.
  Future<void> close() async {
    final opening = _opening;
    if (opening == null) return;
    try {
      await (await opening).close();
    } finally {
      _opening = null;
    }
  }
}
