import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';
import 'herd_repository.dart';
import 'sample_herd.dart';

/// SQLite storage (sqflite). All reads and writes stay on the device; no network is used.
class SqliteHerdRepository implements HerdRepository {
  Database? _db;
  Database get db => _db!;

  static const _schema = [
    '''CREATE TABLE animals(id INTEGER PRIMARY KEY, tag TEXT NOT NULL UNIQUE, name TEXT NOT NULL, breed TEXT NOT NULL,
       sex TEXT NOT NULL, birth TEXT NOT NULL, grp TEXT NOT NULL, pen TEXT NOT NULL, sire_id INTEGER, dam_id INTEGER,
       photo TEXT, in_herd INTEGER NOT NULL, lactation INTEGER NOT NULL, calving TEXT, prev_calving TEXT,
       pregnant INTEGER NOT NULL, ca REAL, cb REAL, cc REAL, prev_lact TEXT)''',
    '''CREATE TABLE milk(id INTEGER PRIMARY KEY, animal_id INTEGER NOT NULL, day TEXT NOT NULL, session TEXT NOT NULL,
       liters REAL NOT NULL, note TEXT, UNIQUE(animal_id, day, session))''',
    '''CREATE TABLE breeding(id INTEGER PRIMARY KEY, animal_id INTEGER NOT NULL, type TEXT NOT NULL, day TEXT NOT NULL,
       bull_id INTEGER, confirmed INTEGER, note TEXT)''',
    '''CREATE TABLE bulls(id INTEGER PRIMARY KEY, name TEXT NOT NULL, tag TEXT NOT NULL, breed TEXT NOT NULL,
       straws INTEGER NOT NULL, conception INTEGER NOT NULL, sexed INTEGER NOT NULL, photo TEXT, note TEXT)''',
    '''CREATE TABLE health(id INTEGER PRIMARY KEY, animal_id INTEGER, type TEXT NOT NULL, day TEXT NOT NULL, title TEXT NOT NULL,
       by_name TEXT NOT NULL, withdrawal TEXT, count INTEGER NOT NULL, note TEXT)''',
    'CREATE INDEX milk_day ON milk(day)',
    "CREATE TABLE meta(k TEXT PRIMARY KEY, v TEXT)",
  ];

  @override
  Future<void> open() async {
    if (_db != null) return;
    final path = p.join(await getDatabasesPath(), 'herdline.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, _) async {
      for (final s in _schema) {
        await db.execute(s);
      }
    });
    final seeded = await db.query('meta', where: 'k = ?', whereArgs: ['seeded']);
    if (seeded.isEmpty) {
      await loadSample();
    }
  }

  @override
  Future<HerdData> loadAll() async {
    final rows = await Future.wait([
      db.query('animals'),
      db.query('milk'),
      db.query('breeding'),
      db.query('bulls'),
      db.query('health'),
    ]);
    return HerdData(
      animals: rows[0].map(Animal.fromMap).toList(),
      milk: rows[1].map(MilkRecord.fromMap).toList(),
      breeding: rows[2].map(BreedingEvent.fromMap).toList(),
      bulls: rows[3].map(Bull.fromMap).toList(),
      health: rows[4].map(HealthEvent.fromMap).toList(),
    );
  }

  @override
  Future<Animal> saveAnimal(Animal a) async {
    if (a.id == null) {
      final map = a.toMap()..remove('id');
      final id = await db.insert('animals', map);
      return a.copyWith(id: id);
    }
    await db.update('animals', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
    return a;
  }

  @override
  Future<void> deleteAnimal(int id) => db.transaction((t) async {
        await t.delete('milk', where: 'animal_id = ?', whereArgs: [id]);
        await t.delete('breeding', where: 'animal_id = ?', whereArgs: [id]);
        await t.delete('health', where: 'animal_id = ?', whereArgs: [id]);
        await t.update('animals', {'sire_id': null}, where: 'sire_id = ?', whereArgs: [id]);
        await t.update('animals', {'dam_id': null}, where: 'dam_id = ?', whereArgs: [id]);
        await t.delete('animals', where: 'id = ?', whereArgs: [id]);
      });

  @override
  Future<MilkRecord> addMilk(MilkRecord r) async {
    final id = await db.insert('milk', r.toMap()..remove('id'), conflictAlgorithm: ConflictAlgorithm.replace);
    return MilkRecord(id: id, animalId: r.animalId, date: r.date, session: r.session, liters: r.liters, note: r.note);
  }

  @override
  Future<BreedingEvent> addBreeding(BreedingEvent e) async {
    final id = await db.insert('breeding', e.toMap()..remove('id'));
    return BreedingEvent.fromMap({...e.toMap(), 'id': id});
  }

  @override
  Future<void> saveBull(Bull b) => db.update('bulls', b.toMap(), where: 'id = ?', whereArgs: [b.id]);

  @override
  Future<HealthEvent> addHealth(HealthEvent e) async {
    final id = await db.insert('health', e.toMap()..remove('id'));
    return HealthEvent.fromMap({...e.toMap(), 'id': id});
  }

  @override
  Future<void> clearAll() => db.transaction((t) async {
        for (final table in ['animals', 'milk', 'breeding', 'bulls', 'health']) {
          await t.delete(table);
        }
        await t.insert('meta', {'k': 'seeded', 'v': 'cleared'}, conflictAlgorithm: ConflictAlgorithm.replace);
      });

  @override
  Future<void> loadSample() async {
    final d = SampleHerd.build();
    await db.transaction((t) async {
      for (final table in ['animals', 'milk', 'breeding', 'bulls', 'health']) {
        await t.delete(table);
      }
      final b = t.batch();
      for (final a in d.animals) {
        b.insert('animals', a.toMap());
      }
      for (final r in d.milk) {
        b.insert('milk', r.toMap()..remove('id'));
      }
      for (final e in d.breeding) {
        b.insert('breeding', e.toMap()..remove('id'));
      }
      for (final x in d.bulls) {
        b.insert('bulls', x.toMap());
      }
      for (final h in d.health) {
        b.insert('health', h.toMap()..remove('id'));
      }
      b.insert('meta', {'k': 'seeded', 'v': 'sample'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await b.commit(noResult: true);
    });
  }
}
