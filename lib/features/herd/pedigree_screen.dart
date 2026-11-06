import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/herd_view.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import 'animal_profile_screen.dart';

/// Three-generation family tree (animal, parents, grandparents) plus offspring.
class PedigreeScreen extends ConsumerWidget {
  const PedigreeScreen({super.key, required this.animalId});
  final int animalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(herdViewProvider);
    final a = view?.byId[animalId];
    if (view == null || a == null) return const Scaffold(body: SizedBox());
    final sire = view.sire(a), dam = view.dam(a);
    final grand = [sire == null ? null : view.sire(sire), sire == null ? null : view.dam(sire), dam == null ? null : view.sire(dam), dam == null ? null : view.dam(dam)];
    final kids = view.offspring(a);

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
          DetailHeader(title: 'Pedigree', caption: '${a.name} - ${a.tag}'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AppCard(
                gradient: C.hero,
                child: Row(children: [
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: Photo(a.photo, size: 56, radius: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.name, style: T.title.copyWith(color: Colors.white)),
                      Text('${a.tag} - ${a.breed} - born ${longDate(a.birthDate)}', style: T.caption.copyWith(color: Colors.white)),
                      const SizedBox(height: 6),
                      Text('${a.lactation} lactations - ${a.sex == Sex.female ? 'Female' : 'Male'}', style: T.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ),
              const _Connector(),
              Row(children: [
                Expanded(child: _Node(sire, 'Sire', large: true)),
                const SizedBox(width: 12),
                Expanded(child: _Node(dam, 'Dam', large: true)),
              ]),
              const _Connector(),
              Row(children: [
                for (var i = 0; i < 4; i++) ...[
                  Expanded(child: _Node(grand[i], i.isEven ? 'Grandsire' : 'Granddam')),
                  if (i < 3) const SizedBox(width: 6),
                ],
              ]),
              SectionHeader('Offspring (${kids.length})'),
              if (kids.isEmpty) Text('No recorded offspring yet.', style: T.caption),
              for (final k in kids)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AnimalProfileScreen(animalId: k.id!))),
                    child: Row(children: [
                      Photo(k.photo, size: 44, radius: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${k.name} - ${k.tag}', style: T.label.copyWith(fontWeight: FontWeight.w600)),
                          Text('${k.group == HerdGroup.heifer ? 'Heifer' : 'Cow'} - born ${longDate(k.birthDate)}', style: T.caption),
                        ]),
                      ),
                      StatusChip(k.group.label, Tone.info),
                      const Icon(Icons.chevron_right_rounded, color: C.ink3),
                    ]),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 28,
        child: CustomPaint(painter: _ConnectorPainter(), size: Size.infinite),
      );
}

class _ConnectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = C.borderStrong..strokeWidth = 1.5;
    final mid = s.height / 2;
    canvas.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, mid), p);
    canvas.drawLine(Offset(s.width / 4, mid), Offset(s.width * 3 / 4, mid), p);
    canvas.drawLine(Offset(s.width / 4, mid), Offset(s.width / 4, s.height), p);
    canvas.drawLine(Offset(s.width * 3 / 4, mid), Offset(s.width * 3 / 4, s.height), p);
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) => false;
}

class _Node extends StatelessWidget {
  const _Node(this.a, this.role, {this.large = false});
  final Animal? a;
  final String role;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final male = a?.sex == Sex.male || role.contains('sire') || role == 'Sire';
    return Container(
      padding: EdgeInsets.all(large ? 12 : 8),
      decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(large ? 20 : 12), border: Border.all(color: C.border), boxShadow: large ? C.shadow : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(male ? Icons.male_rounded : Icons.female_rounded, size: 14, color: C.fill),
          const SizedBox(width: 2),
          Flexible(child: Text(role, style: T.small.copyWith(color: C.fill), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 4),
        if (large && a != null) ...[Photo(a!.photo, size: 36, radius: 18), const SizedBox(height: 6)],
        Text(a?.name ?? 'Unknown', style: (large ? T.titleSm : T.label).copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(a?.tag ?? '-', style: T.small),
      ]),
    );
  }
}
