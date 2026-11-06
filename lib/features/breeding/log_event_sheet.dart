import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';

Future<void> showLogEventSheet(BuildContext context, {int? animalId}) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: C.surface,
      builder: (_) => _LogEventSheet(animalId: animalId),
    );

/// Heat, insemination (uses one straw), pregnancy check (updates pregnant status) or calving due.
class _LogEventSheet extends ConsumerStatefulWidget {
  const _LogEventSheet({this.animalId});
  final int? animalId;
  @override
  ConsumerState<_LogEventSheet> createState() => _LogEventSheetState();
}

class _LogEventSheetState extends ConsumerState<_LogEventSheet> {
  late int? _animal = widget.animalId ?? 11;
  BreedingType _type = BreedingType.insemination;
  int? _bull = 1;
  bool _confirmed = true;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_animal == null) return toast(context, 'Pick an animal');
    final view = ref.read(herdViewProvider)!;
    if (_type == BreedingType.insemination) {
      final bull = view.data.bulls.firstWhere((b) => b.id == _bull);
      if (bull.straws == 0) return toast(context, 'No ${bull.name} straws left in the tank');
    }
    final e = BreedingEvent(
      animalId: _animal!,
      type: _type,
      date: _type == BreedingType.calvingDue ? AppClock.today.add(const Duration(days: 7)) : AppClock.today,
      bullId: _type == BreedingType.insemination ? _bull : null,
      confirmed: _type == BreedingType.pregnancyCheck ? _confirmed : null,
      note: _note.text.trim(),
    );
    final nav = Navigator.of(context);
    if (await guarded(context, () => ref.read(herdProvider.notifier).addBreeding(e), ok: '${e.type.label} logged')) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(herdViewProvider)!;
    final cows = view.herd.where((a) => a.sex == Sex.female && a.group != HerdGroup.heifer || a.id == widget.animalId).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Log breeding event', style: T.title),
        const FieldLabel('Animal', required: true),
        DropdownButtonFormField<int>(
          initialValue: _animal,
          isExpanded: true,
          items: [for (final a in cows.take(80)) DropdownMenuItem(value: a.id, child: Text('${a.name} - ${a.tag}'))],
          onChanged: (v) => setState(() => _animal = v),
        ),
        const FieldLabel('Event'),
        Wrap(children: [
          for (final t in BreedingType.values) FilterPill(label: t == BreedingType.pregnancyCheck ? 'Pregnancy check' : t.label, selected: _type == t, onTap: () => setState(() => _type = t)),
        ]),
        if (_type == BreedingType.insemination) ...[
          const FieldLabel('Bull straw'),
          DropdownButtonFormField<int>(
            initialValue: _bull,
            items: [for (final b in view.data.bulls) DropdownMenuItem(value: b.id, child: Text('${b.name} ${b.tag} - ${b.straws} straws'))],
            onChanged: (v) => setState(() => _bull = v),
          ),
        ],
        if (_type == BreedingType.pregnancyCheck) ...[
          const FieldLabel('Result'),
          SegmentedButton<bool>(
            segments: const [ButtonSegment(value: true, label: Text('Pregnant')), ButtonSegment(value: false, label: Text('Open'))],
            selected: {_confirmed},
            onSelectionChanged: (s) => setState(() => _confirmed = s.first),
          ),
        ],
        const FieldLabel('Note'),
        TextField(controller: _note, decoration: const InputDecoration(hintText: 'Optional')),
        const SizedBox(height: 20),
        PrimaryButton(key: const Key('save-event'), label: 'Save event', icon: Icons.check_rounded, onPressed: _save),
      ]),
    );
  }
}
