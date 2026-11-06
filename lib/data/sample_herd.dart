import 'dart:math' as math;

import '../domain/models.dart';

/// A realistic, deterministic sample farm: 250 head, 14 days of AM/PM milk records,
/// breeding and health history. Same seed, same herd, so screenshots and tests are stable.
class SampleHerd {
  static HerdData build() {
    final rnd = math.Random(7);
    final today = AppClock.today;
    DateTime d(int y, int m, int day) => DateTime(y, m, day);
    double r(double lo, double hi) => lo + rnd.nextDouble() * (hi - lo);

    final animals = <Animal>[];
    final milk = <MilkRecord>[];
    final breeding = <BreedingEvent>[];
    final health = <HealthEvent>[];

    Animal curveCow(Animal base, {required int dim, required double peak, required int peakDay}) {
      final b = r(0.2, 0.3);
      final c = b / peakDay;
      final a = peak / (math.pow(peakDay, b) * math.exp(-b));
      return Animal(
        id: base.id,
        tag: base.tag,
        name: base.name,
        breed: base.breed,
        sex: base.sex,
        birthDate: base.birthDate,
        group: base.group,
        pen: base.pen,
        sireId: base.sireId,
        damId: base.damId,
        photo: base.photo,
        lactation: base.lactation,
        calvingDate: today.subtract(Duration(days: dim)),
        prevCalvingDate: base.lactation > 1 ? today.subtract(Duration(days: dim + 360 + rnd.nextInt(60))) : null,
        pregnant: base.pregnant,
        curveA: a,
        curveB: b,
        curveC: c,
        prevLactations: base.prevLactations,
      );
    }

    // Ancestors kept for the pedigree (no longer on the farm).
    animals.addAll([
      Animal(id: 1, tag: 'DE 1180', name: 'Atlas', breed: 'Holstein', sex: Sex.male, birthDate: d(2014, 4, 2), group: HerdGroup.bull, pen: 'Bull pen', inHerd: false, photo: 'bull-holstein'),
      Animal(id: 2, tag: 'NL 0102', name: 'Nora', breed: 'Holstein', sex: Sex.female, birthDate: d(2013, 9, 14), group: HerdGroup.dry, pen: 'Dry pen', inHerd: false),
      Animal(id: 3, tag: 'NL 0045', name: 'Duke', breed: 'Jersey', sex: Sex.male, birthDate: d(2013, 2, 20), group: HerdGroup.bull, pen: 'Bull pen', inHerd: false, photo: 'bull-jersey'),
      Animal(id: 4, tag: 'NL 0098', name: 'Fleur', breed: 'Holstein', sex: Sex.female, birthDate: d(2014, 1, 8), group: HerdGroup.dry, pen: 'Dry pen', inHerd: false),
      Animal(id: 5, tag: 'NL 0021', name: 'Bolt', breed: 'Holstein', sex: Sex.male, birthDate: d(2017, 5, 30), group: HerdGroup.bull, pen: 'Bull pen', sireId: 1, damId: 2, inHerd: false, photo: 'bull-holstein'),
      Animal(id: 6, tag: 'NL 0211', name: 'Rosa', breed: 'Holstein', sex: Sex.female, birthDate: d(2016, 3, 11), group: HerdGroup.dry, pen: 'Dry pen', sireId: 3, damId: 4, inHerd: false, photo: 'cow-holstein'),
    ]);

    // Bella: the featured cow, peak day 52 at 41.2 L, 128 days in milk.
    const bb = 0.25, bc = bb / 52;
    final ba = 41.2 / (math.pow(52, bb) * math.exp(-bb));
    animals.add(Animal(
      id: 10, tag: 'NL 0482', name: 'Bella', breed: 'Holstein', sex: Sex.female, birthDate: d(2021, 3, 12),
      group: HerdGroup.milking, pen: 'Pen 2', sireId: 5, damId: 6, photo: 'bella-pasture', lactation: 3,
      calvingDate: today.subtract(const Duration(days: 128)), prevCalvingDate: today.subtract(const Duration(days: 128 + 392)),
      curveA: ba, curveB: bb, curveC: bc, prevLactations: '2022-2023:8420:32.4;2024-2025:9610:38.1',
    ));
    final featured = [
      (Animal(id: 11, tag: 'NL 0517', name: 'Daisy', breed: 'Holstein', sex: Sex.female, birthDate: d(2020, 8, 2), group: HerdGroup.milking, pen: 'Pen 2', photo: 'cow-holstein', lactation: 3), 96, 44.0, 55),
      (Animal(id: 12, tag: 'NL 0390', name: 'Rosie', breed: 'Holstein', sex: Sex.female, birthDate: d(2019, 5, 19), group: HerdGroup.milking, pen: 'Pen 1', photo: 'cow-holstein', lactation: 4), 150, 39.0, 60),
      (Animal(id: 14, tag: 'NL 0702', name: 'Maple', breed: 'Holstein', sex: Sex.female, birthDate: d(2022, 2, 27), group: HerdGroup.milking, pen: 'Pen 3', photo: 'cow-holstein', lactation: 2, pregnant: true), 210, 33.0, 48),
      (Animal(id: 15, tag: 'NL 0733', name: 'Hazel', breed: 'Jersey', sex: Sex.female, birthDate: d(2021, 10, 5), group: HerdGroup.milking, pen: 'Pen 3', photo: 'cow-jersey', lactation: 2), 84, 29.0, 50),
      (Animal(id: 17, tag: 'NL 0655', name: 'Lily', breed: 'Holstein', sex: Sex.female, birthDate: d(2023, 1, 18), group: HerdGroup.milking, pen: 'Pen 1', sireId: 1, damId: 10, photo: 'cow-holstein', lactation: 1), 60, 34.0, 62),
    ];
    for (final (a, dim, peak, pd) in featured) {
      animals.add(curveCow(a, dim: dim, peak: peak, peakDay: pd));
    }
    animals.add(Animal(id: 13, tag: 'NL 0611', name: 'Clover', breed: 'Jersey', sex: Sex.female, birthDate: d(2020, 4, 22), group: HerdGroup.dry, pen: 'Dry pen', photo: 'cow-jersey', lactation: 3, pregnant: true, prevCalvingDate: d(2025, 11, 20)));
    animals.add(Animal(id: 16, tag: 'NL 0812', name: 'Poppy', breed: 'Holstein', sex: Sex.female, birthDate: d(2025, 2, 4), group: HerdGroup.heifer, pen: 'Heifer barn', sireId: 5, damId: 10, photo: 'heifer-calf'));

    // The rest of the herd.
    const names = [
      'Willow', 'Ivy', 'Pearl', 'Ruby', 'Hope', 'Bonnie', 'Daffodil', 'Juniper', 'Olive', 'Fern', 'Clementine', 'Mabel',
      'Tilly', 'Nell', 'Peony', 'Saffron', 'Bluebell', 'Honey', 'Primrose', 'Heather', 'Marigold', 'Rosemary', 'Sage', 'Holly',
      'Dotty', 'Florence', 'Greta', 'Iris', 'Jasmine', 'Kiki', 'Lottie', 'Minnie', 'Nutmeg', 'Opal', 'Pixie', 'Quinn',
      'Rhubarb', 'Sorrel', 'Tansy', 'Velvet', 'Wren', 'Yarrow', 'Zinnia', 'Acorn', 'Briar', 'Cocoa', 'Dew', 'Ember',
    ];
    var nextId = 100, nextTag = 1001, ni = 0;
    String tag() => 'NL ${(nextTag++).toString().padLeft(4, '0')}';
    String name() => names[ni++ % names.length];
    final pregnantIds = <int>{14, 13};

    for (var i = 0; i < 176; i++) {
      final jersey = rnd.nextDouble() < 0.18;
      final lact = 1 + rnd.nextInt(5);
      final dim = 5 + rnd.nextInt(296);
      final preg = dim > 90 && rnd.nextDouble() < 0.53;
      final base = Animal(
        id: nextId++, tag: tag(), name: name(), breed: jersey ? 'Jersey' : 'Holstein', sex: Sex.female,
        birthDate: today.subtract(Duration(days: 365 * (lact + 1) + rnd.nextInt(300))), group: HerdGroup.milking,
        pen: pens[rnd.nextInt(4)], lactation: lact, pregnant: preg, photo: jersey ? 'cow-jersey' : 'cow-holstein',
      );
      animals.add(curveCow(base, dim: dim, peak: jersey ? r(24, 31) : r(30, 44), peakDay: 40 + rnd.nextInt(31)));
      if (preg) pregnantIds.add(base.id!);
    }
    for (var i = 0; i < 23; i++) {
      final id = nextId++;
      final lact = 1 + rnd.nextInt(4);
      animals.add(Animal(
        id: id, tag: tag(), name: name(), breed: rnd.nextDouble() < 0.2 ? 'Jersey' : 'Holstein', sex: Sex.female,
        birthDate: today.subtract(Duration(days: 365 * (lact + 1) + rnd.nextInt(300))), group: HerdGroup.dry, pen: 'Dry pen',
        lactation: lact, pregnant: true, prevCalvingDate: today.subtract(Duration(days: 300 + rnd.nextInt(40))),
      ));
      pregnantIds.add(id);
    }
    for (var i = 0; i < 40; i++) {
      animals.add(Animal(
        id: nextId++, tag: tag(), name: name(), breed: rnd.nextDouble() < 0.2 ? 'Jersey' : 'Holstein', sex: Sex.female,
        birthDate: today.subtract(Duration(days: 120 + rnd.nextInt(500))), group: HerdGroup.heifer, pen: 'Heifer barn',
        sireId: 5, photo: 'heifer-calf',
      ));
    }
    for (final (n, br) in [('Ranger', 'Holstein'), ('Moss', 'Jersey'), ('Bram', 'Holstein')]) {
      animals.add(Animal(
        id: nextId++, tag: tag(), name: n, breed: br, sex: Sex.male, birthDate: today.subtract(Duration(days: 900 + rnd.nextInt(600))),
        group: HerdGroup.bull, pen: 'Bull pen', photo: br == 'Jersey' ? 'bull-jersey' : 'bull-holstein',
      ));
    }

    // 14 days of AM/PM milk records from each cow's curve.
    for (final a in animals.where((a) => a.inHerd && a.group == HerdGroup.milking)) {
      for (var k = 13; k >= 0; k--) {
        final day = today.subtract(Duration(days: k));
        final dim = a.daysInMilk! - k;
        if (dim <= 0) continue;
        final y = a.curve.at(dim) * r(0.95, 1.05);
        double round1(double v) => (v * 10).round() / 10;
        milk.add(MilkRecord(animalId: a.id!, date: day, session: Session.am, liters: round1(y * 0.52)));
        milk.add(MilkRecord(animalId: a.id!, date: day, session: Session.pm, liters: round1(y * 0.48)));
      }
    }

    // Bulls and straw inventory.
    final bulls = [
      const Bull(id: 1, name: 'Bolt', tag: 'NL 0021', breed: 'Holstein', straws: 72, conception: 46, photo: 'bull-holstein', note: 'Active sire'),
      const Bull(id: 2, name: 'Atlas', tag: 'DE 1180', breed: 'Holstein', straws: 48, conception: 51, photo: 'bull-holstein', note: 'Proven sire'),
      const Bull(id: 3, name: 'Duke', tag: 'NL 0045', breed: 'Jersey', straws: 8, conception: 39, photo: 'bull-jersey'),
      const Bull(id: 4, name: 'Sterling', tag: 'NL 0077', breed: 'Holstein', straws: 58, conception: 44, sexed: true, photo: 'bull-holstein', note: 'Sexed female'),
    ];

    // Breeding: today's heats, this week's calvings, checks with results.
    breeding.addAll([
      BreedingEvent(animalId: 11, type: BreedingType.heat, date: today, note: 'Pen 2 - standing heat seen at 06:10'),
      BreedingEvent(animalId: 13, type: BreedingType.calvingDue, date: d(2026, 11, 9), note: 'Maternity pen - gestation 282 d'),
      BreedingEvent(animalId: 14, type: BreedingType.pregnancyCheck, date: today, confirmed: true, note: 'Day 35 scan by Dr. Sam Okafor'),
      BreedingEvent(animalId: 15, type: BreedingType.insemination, date: d(2026, 10, 14), bullId: 1, note: 'Bolt straw - watch for return heat'),
    ]);
    final milkingOpen = animals.where((a) => a.inHerd && a.group == HerdGroup.milking && !a.pregnant && a.id! >= 100).toList();
    for (final a in milkingOpen.take(5)) {
      breeding.add(BreedingEvent(animalId: a.id!, type: BreedingType.heat, date: today.subtract(Duration(days: rnd.nextInt(2))), note: '${a.pen} - activity up'));
    }
    final dryIds = animals.where((a) => a.inHerd && a.group == HerdGroup.dry && a.id! >= 100).map((a) => a.id!).toList();
    breeding.add(BreedingEvent(animalId: dryIds[0], type: BreedingType.calvingDue, date: d(2026, 11, 7), note: 'Maternity pen'));
    breeding.add(BreedingEvent(animalId: dryIds[1], type: BreedingType.calvingDue, date: d(2026, 11, 12), note: 'Maternity pen'));
    for (final id in pregnantIds.where((i) => i != 14)) {
      final ins = today.subtract(Duration(days: 60 + rnd.nextInt(150)));
      final bull = bulls[rnd.nextInt(bulls.length)];
      breeding.add(BreedingEvent(animalId: id, type: BreedingType.insemination, date: ins, bullId: bull.id));
      breeding.add(BreedingEvent(animalId: id, type: BreedingType.pregnancyCheck, date: ins.add(const Duration(days: 35)), confirmed: true));
    }
    for (final a in milkingOpen.skip(5)) {
      for (var t = 0; t < 1; t++) {
        final ins = today.subtract(Duration(days: 50 + rnd.nextInt(160)));
        breeding.add(BreedingEvent(animalId: a.id!, type: BreedingType.insemination, date: ins, bullId: bulls[rnd.nextInt(4)].id));
        breeding.add(BreedingEvent(animalId: a.id!, type: BreedingType.pregnancyCheck, date: ins.add(const Duration(days: 35)), confirmed: false));
      }
    }

    // Health history; two cows are in a milk withdrawal period.
    final other = milkingOpen[20];
    health.addAll([
      HealthEvent(animalId: 12, type: HealthType.treatment, date: d(2026, 11, 5), title: 'Mastitis treatment', by: 'Dr. Sam Okafor', withdrawalUntil: d(2026, 11, 9), note: 'Intramammary course day 2 of 3. Milk diverted to waste line.'),
      HealthEvent(animalId: other.id, type: HealthType.treatment, date: d(2026, 11, 4), title: 'Foot infection treatment', by: 'Dr. Sam Okafor', withdrawalUntil: d(2026, 11, 8), note: 'Antibiotic injection, recheck on 8 Nov.'),
      HealthEvent(type: HealthType.vaccination, date: d(2026, 11, 3), title: 'Herd vaccination BVD', by: 'Tom Reyes and farm team', animalCount: 182, note: 'Whole milking herd booster.'),
      HealthEvent(animalId: 15, type: HealthType.check, date: d(2026, 11, 1), title: 'Lameness check, hoof trimmed', by: 'Dr. Sam Okafor', note: 'Score 1 (normal). Left hind claw re-balanced.'),
      HealthEvent(animalId: 13, type: HealthType.check, date: d(2026, 10, 28), title: 'Dry-off body condition check', by: 'Lena Park', note: 'BCS 3.25, ready for calving.'),
      HealthEvent(animalId: milkingOpen[30].id, type: HealthType.treatment, date: d(2026, 10, 20), title: 'Metritis treatment', by: 'Dr. Sam Okafor', withdrawalUntil: d(2026, 10, 26)),
      HealthEvent(animalId: milkingOpen[41].id, type: HealthType.treatment, date: d(2026, 10, 15), title: 'Hoof block applied', by: 'Tom Reyes'),
      HealthEvent(animalId: milkingOpen[52].id, type: HealthType.treatment, date: d(2026, 10, 12), title: 'Milk fever, calcium given', by: 'Dr. Sam Okafor'),
      HealthEvent(animalId: milkingOpen[60].id, type: HealthType.treatment, date: d(2026, 10, 9), title: 'Mastitis treatment', by: 'Dr. Sam Okafor', withdrawalUntil: d(2026, 10, 14)),
    ]);

    return HerdData(animals: animals, milk: milk, breeding: breeding, bulls: bulls, health: health);
  }
}
