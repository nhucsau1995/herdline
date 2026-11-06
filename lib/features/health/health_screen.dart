import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/herd_view.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';

/// Treatments, vaccinations and checks, with milk withdrawal periods.
/// Pass [animalId] to show one animal's records.
class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key, this.animalId});
  final int? animalId;
  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  HealthType? _type;

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(herdViewProvider);
    final role = ref.watch(sessionProvider) ?? Role.manager;
    if (view == null) return const Scaffold(body: SizedBox());
    final a = widget.animalId == null ? null : view.byId[widget.animalId];
    final items = view.healthFor(type: _type, animalId: widget.animalId);
    final withdrawal = view.inWithdrawal;
    final canEdit = Permissions.can(role, Module.health);

    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          ListView(padding: const EdgeInsets.only(bottom: 96), children: [
            DetailHeader(title: 'Health records', caption: a == null ? 'Whole herd' : '${a.name} - ${a.tag}'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (a == null)
                  AppCard(
                    color: C.warnBg,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.warning_amber_rounded, color: C.warnFg),
                        const SizedBox(width: 6),
                        Text('In withdrawal', style: T.label.copyWith(color: C.warnFg, fontWeight: FontWeight.w600)),
                      ]),
                      Text('${withdrawal.length} cows', style: T.display.copyWith(color: C.warnFg)),
                      Text(
                        view.withdrawalEnds == null ? 'No milk is being discarded' : 'Milk discarded until ${shortDate(view.withdrawalEnds!)}: ${withdrawal.map((c) => c.name).join(', ')}',
                        style: T.caption.copyWith(color: C.warnFg),
                      ),
                    ]),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    FilterPill(label: 'All', selected: _type == null, onTap: () => setState(() => _type = null)),
                    for (final t in HealthType.values)
                      FilterPill(label: '${t.label}s', selected: _type == t, onTap: () => setState(() => _type = t)),
                  ]),
                ),
                const SizedBox(height: 16),
                if (items.isEmpty) Text('No records for this filter.', style: T.caption),
                for (final h in items) _Entry(view: view, h: h),
              ]),
            ),
          ]),
          if (canEdit)
            Positioned(
              right: 20,
              bottom: 16,
              child: FloatingPill(key: const Key('log-health'), label: 'Log health event', onPressed: () => _log(context, view)),
            ),
        ]),
      ),
    );
  }

  Future<void> _log(BuildContext context, HerdView view) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: C.surface,
        builder: (_) => _LogHealthSheet(animalId: widget.animalId),
      );
}

class _Entry extends StatelessWidget {
  const _Entry({required this.view, required this.h});
  final HerdView view;
  final HealthEvent h;
  @override
  Widget build(BuildContext context) {
    final a = h.animalId == null ? null : view.byId[h.animalId];
    final tone = switch (h.type) { HealthType.treatment => h.inWithdrawal ? Tone.warning : Tone.danger, HealthType.vaccination => Tone.info, HealthType.check => Tone.success };
    final chip = h.inWithdrawal ? 'Withdrawal ${h.withdrawalUntil!.difference(h.date).inDays} days' : h.type.label;
    final (fg, _) = toneColors(tone == Tone.danger ? Tone.neutral : tone);
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 24,
          child: Column(children: [
            const SizedBox(height: 18),
            Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: fg, width: 3))),
            Expanded(child: Container(width: 2, color: C.border)),
          ]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Text(shortDate(h.date), style: T.small), const Spacer(), StatusChip(chip, tone == Tone.danger ? Tone.neutral : tone)]),
                const SizedBox(height: 6),
                Text(a == null ? h.title : '${a.name} - ${a.tag}', style: T.titleSm),
                Text(a == null ? '${h.animalCount} animals' : h.title, style: T.label.copyWith(color: C.ink2)),
                if (h.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(12)),
                    child: Text(h.note, style: T.caption),
                  ),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  if (h.by.startsWith('Dr.')) const Photo('sam-okafor', size: 24, radius: 12) else const Icon(Icons.groups_outlined, size: 18, color: C.ink3),
                  const SizedBox(width: 6),
                  Text(h.by, style: T.small),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _LogHealthSheet extends ConsumerStatefulWidget {
  const _LogHealthSheet({this.animalId});
  final int? animalId;
  @override
  ConsumerState<_LogHealthSheet> createState() => _LogHealthSheetState();
}

class _LogHealthSheetState extends ConsumerState<_LogHealthSheet> {
  final _form = GlobalKey<FormState>();
  late int? _animal = widget.animalId ?? 12;
  HealthType _type = HealthType.treatment;
  final _title = TextEditingController();
  final _note = TextEditingController();
  int _withdrawalDays = 0;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final role = ref.read(sessionProvider) ?? Role.manager;
    final today = AppClock.today;
    final e = HealthEvent(
      animalId: _animal,
      type: _type,
      date: today,
      title: _title.text.trim(),
      by: memberFor(role).name,
      withdrawalUntil: _withdrawalDays == 0 ? null : today.add(Duration(days: _withdrawalDays)),
      animalCount: _animal == null ? ref.read(herdViewProvider)!.herd.length : 1,
      note: _note.text.trim(),
    );
    final nav = Navigator.of(context);
    if (await guarded(context, () => ref.read(herdProvider.notifier).addHealth(e), ok: 'Health event saved')) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(herdViewProvider)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Log health event', style: T.title),
          const FieldLabel('Animal'),
          DropdownButtonFormField<int?>(
            initialValue: _animal,
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('Whole herd')),
              for (final a in view.herd.take(80)) DropdownMenuItem(value: a.id, child: Text('${a.name} - ${a.tag}')),
            ],
            onChanged: (v) => setState(() => _animal = v),
          ),
          const FieldLabel('Type'),
          Wrap(children: [for (final t in HealthType.values) FilterPill(label: t.label, selected: _type == t, onTap: () => setState(() => _type = t))]),
          const FieldLabel('What was done', required: true),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(hintText: 'Mastitis treatment'),
            validator: (v) => (v ?? '').trim().length < 3 ? 'Describe the treatment or check' : null,
          ),
          if (_type == HealthType.treatment) ...[
            const FieldLabel('Milk withdrawal'),
            Wrap(children: [for (final d in [0, 3, 4, 7]) FilterPill(label: d == 0 ? 'None' : '$d days', selected: _withdrawalDays == d, onTap: () => setState(() => _withdrawalDays = d))]),
          ],
          const FieldLabel('Notes'),
          TextField(controller: _note, decoration: const InputDecoration(hintText: 'Optional')),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Save', icon: Icons.check_rounded, onPressed: _save),
        ]),
      ),
    );
  }
}
