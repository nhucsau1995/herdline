import 'models.dart';

enum Tone { info, success, warning, danger, neutral }

/// Read-only queries over [HerdData]: counts, milk totals, lactation and fertility numbers.
/// Kept free of Flutter so it is easy to unit test.
class HerdView {
  HerdView(this.data)
      : byId = {for (final a in data.animals) a.id!: a},
        _withdrawal = {
          for (final h in data.health)
            if (h.animalId != null && h.inWithdrawal) h.animalId!: h,
        };

  final HerdData data;
  final Map<int, Animal> byId;
  final Map<int, HealthEvent> _withdrawal;

  DateTime get today => AppClock.today;

  List<Animal> get herd => data.animals.where((a) => a.inHerd).toList()..sort((a, b) => a.tag.compareTo(b.tag));
  bool get isEmpty => herd.isEmpty;

  int count(HerdGroup g) => herd.where((a) => a.group == g).length;
  int get pregnant => herd.where((a) => a.pregnant).length;
  List<Animal> get inWithdrawal => herd.where((a) => _withdrawal.containsKey(a.id)).toList();
  HealthEvent? withdrawalFor(int id) => _withdrawal[id];

  DateTime? get withdrawalEnds {
    final ends = _withdrawal.values.map((h) => h.withdrawalUntil!).toList()..sort();
    return ends.isEmpty ? null : ends.last;
  }

  /// The one status chip shown on a herd row.
  (String, Tone) status(Animal a) {
    if (_withdrawal.containsKey(a.id)) return ('Treatment', Tone.warning);
    if (a.group == HerdGroup.dry) return ('Dry', Tone.neutral);
    if (a.group == HerdGroup.bull) return ('Bull', Tone.neutral);
    if (a.pregnant) return ('Pregnant', Tone.success);
    if (a.group == HerdGroup.heifer) return ('Heifer', Tone.info);
    return ('Milking', Tone.info);
  }

  List<Animal> search(String query, HerdGroup? group) {
    final q = query.trim().toLowerCase();
    return herd.where((a) {
      if (group != null && a.group != group) return false;
      if (q.isEmpty) return true;
      return a.tag.toLowerCase().contains(q) || a.name.toLowerCase().contains(q) || a.pen.toLowerCase().contains(q);
    }).toList();
  }

  bool tagInUse(String tag, {int? exceptId}) {
    final t = tag.trim().toUpperCase();
    return data.animals.any((a) => a.tag.toUpperCase() == t && a.id != exceptId);
  }

  // ---- milk ---------------------------------------------------------------------------------
  Iterable<MilkRecord> milkOn(DateTime day) => data.milk.where((r) => dayOnly(r.date) == dayOnly(day) && !_isDiscarded(r));
  bool _isDiscarded(MilkRecord r) => _withdrawal.containsKey(r.animalId);

  double totalOn(DateTime day, [Session? s]) =>
      milkOn(day).where((r) => s == null || r.session == s).fold(0.0, (t, r) => t + r.liters);

  List<(DateTime, double)> last7(DateTime end) =>
      [for (var i = 6; i >= 0; i--) (end.subtract(Duration(days: i)), totalOn(end.subtract(Duration(days: i))))];

  double avg7Before(DateTime day) {
    final days = [for (var i = 1; i <= 7; i++) totalOn(day.subtract(Duration(days: i)))];
    return days.reduce((a, b) => a + b) / 7;
  }

  /// Percent change of [day] vs the 7 days before it.
  double trendPct(DateTime day) {
    final avg = avg7Before(day);
    return avg == 0 ? 0 : (totalOn(day) - avg) / avg * 100;
  }

  ({double am, double pm}) cowDay(int animalId, DateTime day) {
    var am = 0.0, pm = 0.0;
    for (final r in data.milk) {
      if (r.animalId != animalId || dayOnly(r.date) != dayOnly(day)) continue;
      if (r.session == Session.am) {
        am += r.liters;
      } else {
        pm += r.liters;
      }
    }
    return (am: am, pm: pm);
  }

  double avgPerCow(DateTime day) {
    final cows = milkOn(day).map((r) => r.animalId).toSet().length;
    return cows == 0 ? 0 : totalOn(day) / cows;
  }

  double avgPerCowPeriod(int days) {
    var sum = 0.0;
    for (var i = 0; i < days; i++) {
      sum += avgPerCow(today.subtract(Duration(days: i)));
    }
    return sum / days;
  }

  /// Usual range for a cow, from her fitted curve at today's stage.
  (double, double) typicalRange(Animal a) {
    final dim = a.daysInMilk ?? 100;
    final half = a.curve.at(dim) / 2;
    return ((half * 0.85), (half * 1.15));
  }

  // ---- lactation -----------------------------------------------------------------------------
  double totalToDate(Animal a) => a.daysInMilk == null ? 0 : a.curve.total(1, a.daysInMilk!);
  double projected305(Animal a) => a.curve.total(1, 305);
  double avgDaily(Animal a) => a.daysInMilk == null || a.daysInMilk == 0 ? 0 : totalToDate(a) / a.daysInMilk!;

  // ---- pedigree ------------------------------------------------------------------------------
  Animal? sire(Animal a) => a.sireId == null ? null : byId[a.sireId];
  Animal? dam(Animal a) => a.damId == null ? null : byId[a.damId];
  List<Animal> offspring(Animal a) =>
      data.animals.where((x) => x.sireId == a.id || x.damId == a.id).toList()..sort((x, y) => y.birthDate.compareTo(x.birthDate));

  // ---- breeding ------------------------------------------------------------------------------
  List<BreedingEvent> get dueNow {
    final from = today.subtract(const Duration(days: 2));
    final to = today.add(const Duration(days: 7));
    final list = data.breeding.where((e) {
      return switch (e.type) {
        BreedingType.heat => !e.date.isBefore(from) && !e.date.isAfter(today),
        BreedingType.pregnancyCheck => !e.date.isBefore(today.subtract(const Duration(days: 7))) && !e.date.isAfter(to),
        BreedingType.calvingDue => !e.date.isBefore(today) && !e.date.isAfter(to),
        BreedingType.insemination => !e.date.isBefore(today.subtract(const Duration(days: 30))),
      };
    }).toList();
    int rank(BreedingEvent e) => switch (e.type) {
          BreedingType.heat => 0,
          BreedingType.calvingDue => 1,
          BreedingType.pregnancyCheck => 2,
          BreedingType.insemination => 3,
        };
    list.sort((a, b) => rank(a) != rank(b) ? rank(a).compareTo(rank(b)) : b.date.compareTo(a.date));
    return list;
  }

  List<BreedingEvent> get history => [...data.breeding]..sort((a, b) => b.date.compareTo(a.date));

  List<BreedingEvent> get calvingsThisWeek => data.breeding
      .where((e) => e.type == BreedingType.calvingDue && !e.date.isBefore(today) && !e.date.isAfter(today.add(const Duration(days: 7))))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  int get heatChecksDue => data.breeding
      .where((e) => e.type == BreedingType.heat && !e.date.isBefore(today.subtract(const Duration(days: 2))) && !e.date.isAfter(today))
      .length;

  (String, Tone) breedingChip(BreedingEvent e) => switch (e.type) {
        BreedingType.heat => ('Inseminate', Tone.warning),
        BreedingType.calvingDue => ('Due', Tone.warning),
        BreedingType.insemination => ('Inseminated', Tone.info),
        BreedingType.pregnancyCheck => e.confirmed == true ? ('Confirmed', Tone.success) : (e.confirmed == false ? ('Open', Tone.neutral) : ('Check', Tone.info)),
      };

  /// Confirmed pregnancies / pregnancy checks with a result, as a percentage.
  int get conceptionRate {
    final checks = data.breeding.where((e) => e.type == BreedingType.pregnancyCheck && e.confirmed != null).toList();
    if (checks.isEmpty) return 0;
    return (checks.where((e) => e.confirmed!).length / checks.length * 100).round();
  }

  int get calvingInterval {
    final gaps = herd
        .where((a) => a.calvingDate != null && a.prevCalvingDate != null)
        .map((a) => a.calvingDate!.difference(a.prevCalvingDate!).inDays)
        .toList();
    return gaps.isEmpty ? 0 : (gaps.reduce((a, b) => a + b) / gaps.length).round();
  }

  int get strawsInTank => data.bulls.fold(0, (t, b) => t + b.straws);

  // ---- health --------------------------------------------------------------------------------
  List<HealthEvent> healthFor({HealthType? type, int? animalId}) => data.health
      .where((h) => (type == null || h.type == type) && (animalId == null || h.animalId == animalId))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  int treatmentsIn(int days) => data.health
      .where((h) => h.type == HealthType.treatment && !h.date.isBefore(today.subtract(Duration(days: days))))
      .length;
}
