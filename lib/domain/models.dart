import 'dart:math' as math;

/// The demo runs on a fixed farm day so the sample herd, charts and due dates line up.
class AppClock {
  static DateTime today = DateTime(2026, 11, 6);
}

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

enum Role { admin, manager, worker, vet }

extension RoleX on Role {
  String get label => switch (this) {
        Role.admin => 'Admin',
        Role.manager => 'Manager',
        Role.worker => 'Worker',
        Role.vet => 'Veterinarian',
      };
  String get summary => switch (this) {
        Role.admin => 'Full access, team and settings',
        Role.manager => 'Herd, milk, breeding, reports',
        Role.worker => 'Daily milk and animal records',
        Role.vet => 'Health and breeding records',
      };
}

enum Module { animals, milk, breeding, health, reports, team }

extension ModuleX on Module {
  String get label => switch (this) {
        Module.animals => 'Animals',
        Module.milk => 'Milk',
        Module.breeding => 'Breeding',
        Module.health => 'Health',
        Module.reports => 'Reports',
        Module.team => 'Team',
      };
}

/// Simple role-based access: which modules a role may change.
/// Every role can read the herd; writes and the team screen are gated here.
class Permissions {
  static const Map<Role, Set<Module>> _edit = {
    Role.admin: {Module.animals, Module.milk, Module.breeding, Module.health, Module.reports, Module.team},
    Role.manager: {Module.animals, Module.milk, Module.breeding, Module.health, Module.reports},
    Role.worker: {Module.animals, Module.milk},
    Role.vet: {Module.animals, Module.breeding, Module.health},
  };

  static bool can(Role role, Module module) => _edit[role]!.contains(module);
}

class TeamMember {
  const TeamMember(this.name, this.role, this.subtitle, this.photo);
  final String name;
  final Role role;
  final String subtitle;
  final String photo;
}

const team = [
  TeamMember('Priya Shah', Role.admin, 'Farm administrator - Full access', 'priya-shah'),
  TeamMember('Lena Park', Role.manager, 'Herd manager - Barn sector 4', 'lena-park'),
  TeamMember('Tom Reyes', Role.worker, 'Milking parlor and daily logs', 'tom-reyes'),
  TeamMember('Dr. Sam Okafor', Role.vet, 'Attending veterinarian', 'sam-okafor'),
];

TeamMember memberFor(Role role) => team.firstWhere((m) => m.role == role);

enum Sex { female, male }

enum HerdGroup { milking, dry, heifer, bull }

extension HerdGroupX on HerdGroup {
  String get label => switch (this) {
        HerdGroup.milking => 'Milking',
        HerdGroup.dry => 'Dry',
        HerdGroup.heifer => 'Heifers',
        HerdGroup.bull => 'Bulls',
      };
}

const breeds = ['Holstein', 'Jersey', 'Brown Swiss', 'Ayrshire'];
const pens = ['Pen 1', 'Pen 2', 'Pen 3', 'Pen 4', 'Dry pen', 'Heifer barn', 'Bull pen', 'Maternity pen'];

/// Wood's lactation curve y(t) = a * t^b * e^(-c t), fitted per cow.
class LactationCurve {
  const LactationCurve(this.a, this.b, this.c);
  final double a, b, c;

  double at(int dim) => dim <= 0 ? 0 : a * math.pow(dim, b) * math.exp(-c * dim);
  int get peakDay => (b / c).round();
  double get peakYield => at(peakDay);
  double total(int fromDay, int toDay) {
    var s = 0.0;
    for (var d = fromDay; d <= toDay; d++) {
      s += at(d);
    }
    return s;
  }
}

class Animal {
  const Animal({
    this.id,
    required this.tag,
    required this.name,
    required this.breed,
    required this.sex,
    required this.birthDate,
    required this.group,
    required this.pen,
    this.sireId,
    this.damId,
    this.photo,
    this.inHerd = true,
    this.lactation = 0,
    this.calvingDate,
    this.prevCalvingDate,
    this.pregnant = false,
    this.curveA = 0,
    this.curveB = 0.25,
    this.curveC = 0.0048,
    this.prevLactations = '',
  });

  final int? id;
  final String tag;
  final String name;
  final String breed;
  final Sex sex;
  final DateTime birthDate;
  final HerdGroup group;
  final String pen;
  final int? sireId;
  final int? damId;
  final String? photo;

  /// Ancestors that left the farm stay as records so the pedigree is complete.
  final bool inHerd;
  final int lactation;
  final DateTime? calvingDate;
  final DateTime? prevCalvingDate;
  final bool pregnant;
  final double curveA, curveB, curveC;

  /// Closed lactations as "year:liters:peak" separated by ';'.
  final String prevLactations;

  LactationCurve get curve => LactationCurve(curveA, curveB, curveC);

  int? get daysInMilk =>
      calvingDate == null || group != HerdGroup.milking ? null : AppClock.today.difference(calvingDate!).inDays;

  List<({int number, String years, int liters, double peak})> get closedLactations {
    if (prevLactations.isEmpty) return const [];
    var n = 0;
    return prevLactations.split(';').map((s) {
      final p = s.split(':');
      n++;
      return (number: n, years: p[0], liters: int.parse(p[1]), peak: double.parse(p[2]));
    }).toList();
  }

  Animal copyWith({
    int? id,
    String? tag,
    String? name,
    String? breed,
    Sex? sex,
    DateTime? birthDate,
    HerdGroup? group,
    String? pen,
    int? sireId,
    int? damId,
    bool clearSire = false,
    bool clearDam = false,
    String? photo,
    bool? pregnant,
  }) =>
      Animal(
        id: id ?? this.id,
        tag: tag ?? this.tag,
        name: name ?? this.name,
        breed: breed ?? this.breed,
        sex: sex ?? this.sex,
        birthDate: birthDate ?? this.birthDate,
        group: group ?? this.group,
        pen: pen ?? this.pen,
        sireId: clearSire ? null : (sireId ?? this.sireId),
        damId: clearDam ? null : (damId ?? this.damId),
        photo: photo ?? this.photo,
        inHerd: inHerd,
        lactation: lactation,
        calvingDate: calvingDate,
        prevCalvingDate: prevCalvingDate,
        pregnant: pregnant ?? this.pregnant,
        curveA: curveA,
        curveB: curveB,
        curveC: curveC,
        prevLactations: prevLactations,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'tag': tag,
        'name': name,
        'breed': breed,
        'sex': sex.name,
        'birth': isoDay(birthDate),
        'grp': group.name,
        'pen': pen,
        'sire_id': sireId,
        'dam_id': damId,
        'photo': photo,
        'in_herd': inHerd ? 1 : 0,
        'lactation': lactation,
        'calving': calvingDate == null ? null : isoDay(calvingDate!),
        'prev_calving': prevCalvingDate == null ? null : isoDay(prevCalvingDate!),
        'pregnant': pregnant ? 1 : 0,
        'ca': curveA,
        'cb': curveB,
        'cc': curveC,
        'prev_lact': prevLactations,
      };

  static Animal fromMap(Map<String, Object?> m) => Animal(
        id: m['id'] as int?,
        tag: m['tag'] as String,
        name: m['name'] as String,
        breed: m['breed'] as String,
        sex: Sex.values.byName(m['sex'] as String),
        birthDate: DateTime.parse(m['birth'] as String),
        group: HerdGroup.values.byName(m['grp'] as String),
        pen: m['pen'] as String,
        sireId: m['sire_id'] as int?,
        damId: m['dam_id'] as int?,
        photo: m['photo'] as String?,
        inHerd: (m['in_herd'] as int) == 1,
        lactation: m['lactation'] as int,
        calvingDate: m['calving'] == null ? null : DateTime.parse(m['calving'] as String),
        prevCalvingDate: m['prev_calving'] == null ? null : DateTime.parse(m['prev_calving'] as String),
        pregnant: (m['pregnant'] as int) == 1,
        curveA: (m['ca'] as num).toDouble(),
        curveB: (m['cb'] as num).toDouble(),
        curveC: (m['cc'] as num).toDouble(),
        prevLactations: (m['prev_lact'] as String?) ?? '',
      );
}

enum Session { am, pm }

class MilkRecord {
  const MilkRecord({this.id, required this.animalId, required this.date, required this.session, required this.liters, this.note = ''});
  final int? id;
  final int animalId;
  final DateTime date;
  final Session session;
  final double liters;
  final String note;

  Map<String, Object?> toMap() =>
      {'id': id, 'animal_id': animalId, 'day': isoDay(date), 'session': session.name, 'liters': liters, 'note': note};

  static MilkRecord fromMap(Map<String, Object?> m) => MilkRecord(
        id: m['id'] as int?,
        animalId: m['animal_id'] as int,
        date: DateTime.parse(m['day'] as String),
        session: Session.values.byName(m['session'] as String),
        liters: (m['liters'] as num).toDouble(),
        note: (m['note'] as String?) ?? '',
      );
}

enum BreedingType { heat, insemination, pregnancyCheck, calvingDue }

extension BreedingTypeX on BreedingType {
  String get label => switch (this) {
        BreedingType.heat => 'Heat observed',
        BreedingType.insemination => 'Inseminated',
        BreedingType.pregnancyCheck => 'Pregnancy check',
        BreedingType.calvingDue => 'Calving due',
      };
}

class BreedingEvent {
  const BreedingEvent({
    this.id,
    required this.animalId,
    required this.type,
    required this.date,
    this.bullId,
    this.confirmed,
    this.note = '',
  });
  final int? id;
  final int animalId;
  final BreedingType type;
  final DateTime date;
  final int? bullId;

  /// Pregnancy check result (null for other event types).
  final bool? confirmed;
  final String note;

  Map<String, Object?> toMap() => {
        'id': id,
        'animal_id': animalId,
        'type': type.name,
        'day': isoDay(date),
        'bull_id': bullId,
        'confirmed': confirmed == null ? null : (confirmed! ? 1 : 0),
        'note': note,
      };

  static BreedingEvent fromMap(Map<String, Object?> m) => BreedingEvent(
        id: m['id'] as int?,
        animalId: m['animal_id'] as int,
        type: BreedingType.values.byName(m['type'] as String),
        date: DateTime.parse(m['day'] as String),
        bullId: m['bull_id'] as int?,
        confirmed: m['confirmed'] == null ? null : (m['confirmed'] as int) == 1,
        note: (m['note'] as String?) ?? '',
      );
}

class Bull {
  const Bull({this.id, required this.name, required this.tag, required this.breed, required this.straws, required this.conception, this.sexed = false, this.photo, this.note = ''});
  final int? id;
  final String name;
  final String tag;
  final String breed;
  final int straws;
  final int conception;
  final bool sexed;
  final String? photo;
  final String note;

  static const lowStock = 10;
  bool get isLow => straws < lowStock;

  Bull copyWith({int? straws}) =>
      Bull(id: id, name: name, tag: tag, breed: breed, straws: straws ?? this.straws, conception: conception, sexed: sexed, photo: photo, note: note);

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'tag': tag,
        'breed': breed,
        'straws': straws,
        'conception': conception,
        'sexed': sexed ? 1 : 0,
        'photo': photo,
        'note': note,
      };

  static Bull fromMap(Map<String, Object?> m) => Bull(
        id: m['id'] as int?,
        name: m['name'] as String,
        tag: m['tag'] as String,
        breed: m['breed'] as String,
        straws: m['straws'] as int,
        conception: m['conception'] as int,
        sexed: (m['sexed'] as int) == 1,
        photo: m['photo'] as String?,
        note: (m['note'] as String?) ?? '',
      );
}

enum HealthType { treatment, vaccination, check }

extension HealthTypeX on HealthType {
  String get label => switch (this) {
        HealthType.treatment => 'Treatment',
        HealthType.vaccination => 'Vaccination',
        HealthType.check => 'Check',
      };
}

class HealthEvent {
  const HealthEvent({
    this.id,
    this.animalId,
    required this.type,
    required this.date,
    required this.title,
    required this.by,
    this.withdrawalUntil,
    this.animalCount = 1,
    this.note = '',
  });
  final int? id;

  /// null = whole-herd event (for example a vaccination round).
  final int? animalId;
  final HealthType type;
  final DateTime date;
  final String title;
  final String by;
  final DateTime? withdrawalUntil;
  final int animalCount;
  final String note;

  bool get inWithdrawal => withdrawalUntil != null && !withdrawalUntil!.isBefore(AppClock.today);

  Map<String, Object?> toMap() => {
        'id': id,
        'animal_id': animalId,
        'type': type.name,
        'day': isoDay(date),
        'title': title,
        'by_name': by,
        'withdrawal': withdrawalUntil == null ? null : isoDay(withdrawalUntil!),
        'count': animalCount,
        'note': note,
      };

  static HealthEvent fromMap(Map<String, Object?> m) => HealthEvent(
        id: m['id'] as int?,
        animalId: m['animal_id'] as int?,
        type: HealthType.values.byName(m['type'] as String),
        date: DateTime.parse(m['day'] as String),
        title: m['title'] as String,
        by: m['by_name'] as String,
        withdrawalUntil: m['withdrawal'] == null ? null : DateTime.parse(m['withdrawal'] as String),
        animalCount: m['count'] as int,
        note: (m['note'] as String?) ?? '',
      );
}

/// Everything the app shows, loaded from the local database in one go.
class HerdData {
  const HerdData({required this.animals, required this.milk, required this.breeding, required this.bulls, required this.health});
  final List<Animal> animals;
  final List<MilkRecord> milk;
  final List<BreedingEvent> breeding;
  final List<Bull> bulls;
  final List<HealthEvent> health;

  static const empty = HerdData(animals: [], milk: [], breeding: [], bulls: [], health: []);
}
