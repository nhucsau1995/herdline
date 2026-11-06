import '../domain/models.dart';
import 'sample_herd.dart';

/// Local, offline-first storage for the herd. The app talks only to this interface:
/// [SqliteHerdRepository] on devices, [MemoryHerdRepository] in tests.
abstract class HerdRepository {
  /// Opens storage and loads the sample herd on the very first run.
  Future<void> open();
  Future<HerdData> loadAll();

  Future<Animal> saveAnimal(Animal a);
  Future<void> deleteAnimal(int id);
  Future<MilkRecord> addMilk(MilkRecord r);
  Future<BreedingEvent> addBreeding(BreedingEvent e);
  Future<void> saveBull(Bull b);
  Future<HealthEvent> addHealth(HealthEvent e);

  Future<void> clearAll();
  Future<void> loadSample();
}

class MemoryHerdRepository implements HerdRepository {
  MemoryHerdRepository({this.seed = true});
  final bool seed;
  HerdData _d = HerdData.empty;
  int _next = 100000;
  bool _opened = false;

  @override
  Future<void> open() async {
    if (_opened) return;
    _opened = true;
    if (seed) _d = SampleHerd.build();
  }

  @override
  Future<HerdData> loadAll() async => _d;

  HerdData _with({List<Animal>? animals, List<MilkRecord>? milk, List<BreedingEvent>? breeding, List<Bull>? bulls, List<HealthEvent>? health}) =>
      _d = HerdData(
        animals: animals ?? _d.animals,
        milk: milk ?? _d.milk,
        breeding: breeding ?? _d.breeding,
        bulls: bulls ?? _d.bulls,
        health: health ?? _d.health,
      );

  @override
  Future<Animal> saveAnimal(Animal a) async {
    if (a.id == null) {
      final saved = a.copyWith(id: _next++);
      _with(animals: [..._d.animals, saved]);
      return saved;
    }
    _with(animals: [for (final x in _d.animals) x.id == a.id ? a : x]);
    return a;
  }

  @override
  Future<void> deleteAnimal(int id) async {
    _with(
      animals: _d.animals.where((a) => a.id != id).toList(),
      milk: _d.milk.where((r) => r.animalId != id).toList(),
      breeding: _d.breeding.where((e) => e.animalId != id).toList(),
      health: _d.health.where((h) => h.animalId != id).toList(),
    );
  }

  @override
  Future<MilkRecord> addMilk(MilkRecord r) async {
    final saved = MilkRecord(id: _next++, animalId: r.animalId, date: r.date, session: r.session, liters: r.liters, note: r.note);
    final rest = _d.milk.where((x) => !(x.animalId == r.animalId && dayOnly(x.date) == dayOnly(r.date) && x.session == r.session));
    _with(milk: [...rest, saved]);
    return saved;
  }

  @override
  Future<BreedingEvent> addBreeding(BreedingEvent e) async {
    final saved = BreedingEvent.fromMap({...e.toMap(), 'id': _next++});
    _with(breeding: [..._d.breeding, saved]);
    return saved;
  }

  @override
  Future<void> saveBull(Bull b) async => _with(bulls: [for (final x in _d.bulls) x.id == b.id ? b : x]);

  @override
  Future<HealthEvent> addHealth(HealthEvent e) async {
    final saved = HealthEvent.fromMap({...e.toMap(), 'id': _next++});
    _with(health: [..._d.health, saved]);
    return saved;
  }

  @override
  Future<void> clearAll() async => _d = HerdData.empty;

  @override
  Future<void> loadSample() async => _d = SampleHerd.build();
}
