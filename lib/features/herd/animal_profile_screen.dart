import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../breeding/breeding_screen.dart';
import '../health/health_screen.dart';
import '../milk/lactation_screen.dart';
import '../milk/milk_entry_screen.dart';
import 'animal_form_screen.dart';
import 'pedigree_screen.dart';

class AnimalProfileScreen extends ConsumerWidget {
  const AnimalProfileScreen({super.key, required this.animalId});
  final int animalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(herdViewProvider);
    final role = ref.watch(sessionProvider) ?? Role.manager;
    final a = view?.byId[animalId];
    if (view == null || a == null) {
      return const Scaffold(body: Center(child: Text('This animal is no longer in the herd.')));
    }
    final canEdit = Permissions.can(role, Module.animals);
    final (label, tone) = view.status(a);
    final dim = a.daysInMilk;
    final sire = view.sire(a), dam = view.dam(a);
    final today = view.cowDay(a.id!, AppClock.today);
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        Stack(children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            child: Photo(a.photo, width: double.infinity, height: 280, radius: 0),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                _Circle(Icons.arrow_back_rounded, 'Back', () => Navigator.of(context).maybePop(), const Key('back')),
                const Spacer(),
                if (canEdit) ...[
                  _Circle(Icons.edit_outlined, 'Edit', () => push(AnimalFormScreen(animal: a)), const Key('edit-animal')),
                  const SizedBox(width: 8),
                  _Circle(Icons.delete_outline_rounded, 'Delete', () => _delete(context, ref, a), const Key('delete-animal')),
                ],
              ]),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(a.name, style: T.display)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: C.border)),
                child: Text('# ${a.tag}', style: T.label.copyWith(fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [TintChip(a.breed), TintChip(a.pen), StatusChip(label, tone)]),
            const SizedBox(height: 16),
            if (a.group == HerdGroup.milking)
              AppCard(
                child: Row(children: [
                  _Metric('Lactation', '${a.lactation}', 'Current'),
                  _Metric('Days in milk', '${dim ?? '-'}', dim != null && dim < 100 ? 'Early' : 'Mid'),
                  _Metric('Today', liters(today.am + today.pm, digits: 1), 'AM + PM'),
                ]),
              ),
            SectionHeader('General information'),
            AppCard(
              child: Column(children: [
                KeyValueRow('Born', longDate(a.birthDate)),
                KeyValueRow('Sex', a.sex == Sex.female ? 'Female' : 'Male'),
                KeyValueRow('Group', a.group.label),
                KeyValueRow('Sire', sire == null ? '-' : '${sire.name} ${sire.tag}', vColor: C.fill),
                KeyValueRow('Dam', dam == null ? '-' : '${dam.name} ${dam.tag}', vColor: C.fill),
              ]),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                _Link(Icons.account_tree_outlined, 'Pedigree', '3 generations', const Key('link-pedigree'), () => push(PedigreeScreen(animalId: a.id!))),
                if (a.sex == Sex.female) ...[
                  _Link(Icons.water_drop_outlined, 'Record milk', 'Today ${liters(today.am + today.pm, digits: 1)}', const Key('link-milk'), () => push(MilkEntryScreen(animalId: a.id))),
                  if (a.calvingDate != null) _Link(Icons.autorenew_rounded, 'Lactations', '${a.closedLactations.length} completed', const Key('link-lactation'), () => push(LactationScreen(animalId: a.id!))),
                  _Link(Icons.favorite_border_rounded, 'Breeding events', a.pregnant ? 'Pregnant' : 'Open', const Key('link-breeding'), () => push(BreedingHistoryScreen(animalId: a.id!))),
                ],
                _Link(Icons.medical_services_outlined, 'Health records', '${view.healthFor(animalId: a.id).length} entries', const Key('link-health'), () => push(HealthScreen(animalId: a.id))),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Animal a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete ${a.name}?'),
        content: Text('This removes ${a.tag} and all of its milk, breeding and health records from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: C.dangerFg), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final nav = Navigator.of(context);
    if (await guarded(context, () => ref.read(herdProvider.notifier).deleteAnimal(a.id!), ok: '${a.name} deleted')) nav.pop();
  }
}

class _Circle extends StatelessWidget {
  const _Circle(this.icon, this.tip, this.onTap, this.k);
  final IconData icon;
  final String tip;
  final VoidCallback onTap;
  final Key k;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        child: IconButton(key: k, tooltip: tip, icon: Icon(icon, color: C.ink), onPressed: onTap),
      );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.note);
  final String label, value, note;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(label, style: T.caption),
          const SizedBox(height: 4),
          Text(value, style: T.title.copyWith(color: C.fill, fontSize: 22, fontWeight: FontWeight.w700)),
          Text(note, style: T.small),
        ]),
      );
}

class _Link extends StatelessWidget {
  const _Link(this.icon, this.title, this.note, this.k, this.onTap);
  final IconData icon;
  final String title, note;
  final Key k;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
        key: k,
        onTap: onTap,
        minTileHeight: 56,
        leading: IconPill(icon, size: 36),
        title: Text(title, style: T.label.copyWith(fontWeight: FontWeight.w600)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(note, style: T.caption), const Icon(Icons.chevron_right_rounded, color: C.ink3)]),
      );
}
