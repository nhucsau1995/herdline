import 'package:flutter_test/flutter_test.dart';
import 'package:herdline/data/herd_repository.dart';
import 'package:herdline/data/sample_herd.dart';
import 'package:herdline/domain/herd_view.dart';
import 'package:herdline/domain/models.dart';

void main() {
  final view = HerdView(SampleHerd.build());

  test('sample herd has the expected structure', () {
    expect(view.count(HerdGroup.milking), 182);
    expect(view.count(HerdGroup.dry), 24);
    expect(view.count(HerdGroup.heifer), 41);
    expect(view.count(HerdGroup.bull), 3);
    expect(view.pregnant, greaterThan(80));
    expect(view.inWithdrawal.length, 2);
  });

  test('withdrawal milk is excluded from the tank total', () {
    final today = AppClock.today;
    final rosie = view.cowDay(12, today);
    expect(rosie.am, greaterThan(0));
    final withRosie = view.data.milk.where((r) => dayOnly(r.date) == today).fold(0.0, (t, r) => t + r.liters);
    expect(view.totalOn(today), lessThan(withRosie));
  });

  test('Bella lactation peaks on day 52 at 41.2 L', () {
    final bella = view.byId[10]!;
    expect(bella.daysInMilk, 128);
    expect(bella.curve.peakDay, 52);
    expect(bella.curve.peakYield, closeTo(41.2, 0.05));
    expect(view.projected305(bella), greaterThan(view.totalToDate(bella)));
  });

  test('pedigree links sire, dam and grandparents', () {
    final bella = view.byId[10]!;
    expect(view.sire(bella)!.name, 'Bolt');
    expect(view.dam(bella)!.name, 'Rosa');
    expect(view.sire(view.sire(bella)!)!.name, 'Atlas');
    expect(view.offspring(bella).map((a) => a.name), containsAll(['Poppy', 'Lily']));
  });

  test('fertility numbers are in a realistic range', () {
    expect(view.conceptionRate, inInclusiveRange(35, 60));
    expect(view.calvingInterval, inInclusiveRange(370, 430));
    expect(view.calvingsThisWeek.length, 3);
    expect(view.strawsInTank, 186);
  });

  test('roles gate edits', () {
    expect(Permissions.can(Role.worker, Module.milk), isTrue);
    expect(Permissions.can(Role.worker, Module.breeding), isFalse);
    expect(Permissions.can(Role.vet, Module.health), isTrue);
    expect(Permissions.can(Role.manager, Module.team), isFalse);
    expect(Permissions.can(Role.admin, Module.team), isTrue);
  });

  test('memory repository supports CRUD and duplicate tag check', () async {
    final repo = MemoryHerdRepository();
    await repo.open();
    final saved = await repo.saveAnimal(Animal(
      tag: 'NL 9001', name: 'Test', breed: 'Holstein', sex: Sex.female, birthDate: DateTime(2025, 1, 1),
      group: HerdGroup.heifer, pen: 'Heifer barn',
    ));
    var v = HerdView(await repo.loadAll());
    expect(v.tagInUse('nl 9001'), isTrue);
    expect(v.tagInUse('NL 9001', exceptId: saved.id), isFalse);
    await repo.saveAnimal(saved.copyWith(name: 'Renamed'));
    v = HerdView(await repo.loadAll());
    expect(v.byId[saved.id]!.name, 'Renamed');
    await repo.deleteAnimal(saved.id!);
    v = HerdView(await repo.loadAll());
    expect(v.byId[saved.id], isNull);
  });
}
