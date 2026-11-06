import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/herd_view.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../herd/animal_profile_screen.dart';
import 'bulls_screen.dart';
import 'log_event_sheet.dart';

class BreedingScreen extends ConsumerStatefulWidget {
  const BreedingScreen({super.key});
  @override
  ConsumerState<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends ConsumerState<BreedingScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(herdViewProvider);
    final role = ref.watch(sessionProvider) ?? Role.manager;
    if (view == null) return const Center(child: CircularProgressIndicator());
    final calvings = view.calvingsThisWeek;
    final next = calvings.isEmpty ? null : calvings.first;
    final upcoming = view.data.breeding.where((e) => e.type == BreedingType.calvingDue && !e.date.isBefore(AppClock.today)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final events = switch (_tab) { 0 => view.dueNow, 1 => upcoming, _ => view.history.take(40).toList() };
    final canEdit = Permissions.can(role, Module.breeding);

    return Stack(children: [
      ListView(padding: const EdgeInsets.only(bottom: 96), children: [
        const TabHeader(title: 'Breeding'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFE9EEF6), borderRadius: BorderRadius.circular(999)),
              child: Row(children: [
                for (final (i, l) in [(0, 'Due now'), (1, 'Calendar'), (2, 'History')])
                  Expanded(
                    child: GestureDetector(
                      key: Key('breeding-tab-$i'),
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: _tab == i ? C.surface : Colors.transparent, borderRadius: BorderRadius.circular(999), boxShadow: _tab == i ? C.shadow : null),
                        child: Text(l, style: T.label.copyWith(color: _tab == i ? C.fill : C.ink2, fontWeight: _tab == i ? FontWeight.w700 : FontWeight.w500)),
                      ),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 16),
            AppCard(
              gradient: C.hero,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Calvings this week', style: T.label.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text('${calvings.length}', style: T.display.copyWith(color: Colors.white, fontSize: 40)),
                if (next != null)
                  Text('Next: ${view.byId[next.animalId]?.name} ${view.byId[next.animalId]?.tag} on ${shortDate(next.date)}', style: T.caption.copyWith(color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 12),
            AppCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BullsScreen())),
              child: Row(children: [
                const IconPill(Icons.science_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Bulls and semen - ${view.strawsInTank} straws in tank', key: const Key('bulls-link'), style: T.label.copyWith(fontWeight: FontWeight.w600)),
                    Text('Inventory and conception by sire', style: T.caption),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: C.ink3),
              ]),
            ),
            SectionHeader(['Due now', 'Upcoming calvings', 'History'][_tab], trailing: StatusChip('${events.length} events', Tone.info)),
            if (events.isEmpty) Text('Nothing due. Logged events show up here.', style: T.caption),
            for (final e in events) Padding(padding: const EdgeInsets.only(bottom: 10), child: EventCard(view: view, e: e)),
          ]),
        ),
      ]),
      if (canEdit)
        Positioned(
          right: 20,
          bottom: 16,
          child: FloatingPill(key: const Key('log-event'), label: 'Log event', onPressed: () => showLogEventSheet(context)),
        ),
    ]);
  }
}

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.view, required this.e});
  final HerdView view;
  final BreedingEvent e;

  @override
  Widget build(BuildContext context) {
    final a = view.byId[e.animalId];
    final (label, tone) = view.breedingChip(e);
    final bull = e.bullId == null ? null : view.data.bulls.where((b) => b.id == e.bullId).firstOrNull;
    final when = dayOnly(e.date) == AppClock.today ? 'Today' : shortDate(e.date);
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: a == null ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AnimalProfileScreen(animalId: a.id!))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Photo(a?.photo, size: 40, radius: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${a?.name ?? 'Unknown'} - ${a?.tag ?? ''}', style: T.label.copyWith(fontWeight: FontWeight.w600)),
              Row(children: [const Icon(Icons.schedule_rounded, size: 14, color: C.ink3), const SizedBox(width: 4), Text(when, style: T.small)]),
            ]),
          ),
          StatusChip(label, tone),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.type == BreedingType.pregnancyCheck ? 'Pregnancy check' : e.type.label, style: T.label.copyWith(fontWeight: FontWeight.w600)),
            Text(
              [if (bull != null) '${bull.name} straw', if (e.note.isNotEmpty) e.note].join(' - ').ifEmpty(a?.pen ?? ''),
              style: T.caption,
            ),
          ]),
        ),
      ]),
    );
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

/// All breeding events for one cow.
class BreedingHistoryScreen extends ConsumerWidget {
  const BreedingHistoryScreen({super.key, required this.animalId});
  final int animalId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(herdViewProvider);
    final a = view?.byId[animalId];
    if (view == null || a == null) return const Scaffold(body: SizedBox());
    final events = view.history.where((e) => e.animalId == animalId).toList();
    final canEdit = Permissions.can(ref.watch(sessionProvider) ?? Role.manager, Module.breeding);
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(0, 0, 0, 32), children: [
          DetailHeader(title: 'Breeding events', caption: '${a.name} - ${a.tag} - ${a.pregnant ? 'Pregnant' : 'Open'}'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (events.isEmpty) Text('No breeding events recorded yet.', style: T.caption),
              for (final e in events) Padding(padding: const EdgeInsets.only(bottom: 10), child: EventCard(view: view, e: e)),
              const SizedBox(height: 8),
              if (canEdit) PrimaryButton(label: 'Log event', icon: Icons.add_rounded, onPressed: () => showLogEventSheet(context, animalId: animalId)),
            ]),
          ),
        ]),
      ),
    );
  }
}
