import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/herd_repository.dart';
import '../data/sqlite_herd_repository.dart';
import '../domain/herd_view.dart';
import '../domain/models.dart';

/// Swapped for [MemoryHerdRepository] in tests via ProviderScope overrides.
final repositoryProvider = Provider<HerdRepository>((ref) => SqliteHerdRepository());

/// Signed-in role on this device (null = signed out).
final sessionProvider = NotifierProvider<SessionNotifier, Role?>(SessionNotifier.new);

class SessionNotifier extends Notifier<Role?> {
  @override
  Role? build() => null;
  void signIn(Role role) => state = role;
  void signOut() => state = null;
}

/// The whole herd, loaded from the local database. Every write goes to the database first and
/// then refreshes this state, so what you see is always what is stored.
final herdProvider = AsyncNotifierProvider<HerdNotifier, HerdData>(HerdNotifier.new);

/// Read-only queries over the loaded herd; null while loading.
final herdViewProvider = Provider<HerdView?>((ref) {
  final data = ref.watch(herdProvider).value;
  return data == null ? null : HerdView(data);
});

class HerdNotifier extends AsyncNotifier<HerdData> {
  HerdRepository get _repo => ref.read(repositoryProvider);

  @override
  Future<HerdData> build() async {
    await _repo.open();
    return _repo.loadAll();
  }

  Future<T> _write<T>(Future<T> Function() op) async {
    final result = await op();
    state = AsyncData(await _repo.loadAll());
    return result;
  }

  Future<Animal> saveAnimal(Animal a) => _write(() => _repo.saveAnimal(a));
  Future<void> deleteAnimal(int id) => _write(() => _repo.deleteAnimal(id));
  Future<MilkRecord> addMilk(MilkRecord r) => _write(() => _repo.addMilk(r));
  Future<HealthEvent> addHealth(HealthEvent e) => _write(() => _repo.addHealth(e));
  Future<void> clearAll() => _write(_repo.clearAll);
  Future<void> loadSample() => _write(_repo.loadSample);

  Future<void> addStraws(Bull b, int count) => _write(() => _repo.saveBull(b.copyWith(straws: b.straws + count)));

  /// Logs a breeding event and keeps the linked records in step: an insemination uses one
  /// straw, a pregnancy check result updates the cow's pregnant flag.
  Future<void> addBreeding(BreedingEvent e) => _write(() async {
        await _repo.addBreeding(e);
        final data = await _repo.loadAll();
        if (e.type == BreedingType.insemination && e.bullId != null) {
          final bull = data.bulls.firstWhere((b) => b.id == e.bullId);
          if (bull.straws > 0) await _repo.saveBull(bull.copyWith(straws: bull.straws - 1));
        }
        if (e.type == BreedingType.pregnancyCheck && e.confirmed != null) {
          final cow = data.animals.firstWhere((a) => a.id == e.animalId);
          await _repo.saveAnimal(cow.copyWith(pregnant: e.confirmed));
        }
      });
}
