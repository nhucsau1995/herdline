import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';

/// Register a new animal or edit one. Validates the ear tag (required, format, unique),
/// name and birth date before anything is written.
class AnimalFormScreen extends ConsumerStatefulWidget {
  const AnimalFormScreen({super.key, this.animal});
  final Animal? animal;
  @override
  ConsumerState<AnimalFormScreen> createState() => _AnimalFormScreenState();
}

class _AnimalFormScreenState extends ConsumerState<AnimalFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _tag = TextEditingController(text: widget.animal?.tag ?? '');
  late final _name = TextEditingController(text: widget.animal?.name ?? '');
  late String _breed = widget.animal?.breed ?? 'Holstein';
  late Sex _sex = widget.animal?.sex ?? Sex.female;
  late DateTime? _birth = widget.animal?.birthDate;
  late HerdGroup _group = widget.animal?.group ?? HerdGroup.heifer;
  late String _pen = widget.animal?.pen ?? 'Heifer barn';
  late int? _sire = widget.animal?.sireId;
  late int? _dam = widget.animal?.damId;
  bool _saving = false;

  static final _tagFormat = RegExp(r'^[A-Z]{2} ?\d{4}$');

  @override
  void dispose() {
    _tag.dispose();
    _name.dispose();
    super.dispose();
  }

  String? _validateTag(String? v) {
    final t = (v ?? '').trim().toUpperCase();
    if (t.isEmpty) return 'Ear tag is required';
    if (!_tagFormat.hasMatch(t)) return 'Use country code + 4 digits, for example NL 0812';
    final view = ref.read(herdViewProvider);
    if (view != null && view.tagInUse(t, exceptId: widget.animal?.id)) return 'Tag $t is already in use';
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_birth == null) {
      toast(context, 'Pick a date of birth');
      return;
    }
    setState(() => _saving = true);
    final raw = _tag.text.trim().toUpperCase();
    final tag = raw.contains(' ') ? raw : '${raw.substring(0, 2)} ${raw.substring(2)}';
    final base = widget.animal;
    final a = base == null
        ? Animal(
            tag: tag,
            name: _name.text.trim(),
            breed: _breed,
            sex: _sex,
            birthDate: _birth!,
            group: _group,
            pen: _pen,
            sireId: _sire,
            damId: _dam,
            photo: _group == HerdGroup.heifer ? 'heifer-calf' : (_breed == 'Jersey' ? 'cow-jersey' : 'cow-holstein'),
          )
        : base.copyWith(
            tag: tag,
            name: _name.text.trim(),
            breed: _breed,
            sex: _sex,
            birthDate: _birth,
            group: _group,
            pen: _pen,
            sireId: _sire,
            damId: _dam,
            clearSire: _sire == null,
            clearDam: _dam == null,
          );
    final nav = Navigator.of(context);
    final ok = await guarded(context, () => ref.read(herdProvider.notifier).saveAnimal(a), ok: base == null ? '${a.name} registered' : 'Changes saved');
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(herdViewProvider);
    final all = view?.data.animals ?? const <Animal>[];
    final males = all.where((a) => a.sex == Sex.male).toList();
    final females = all.where((a) => a.sex == Sex.female && a.id != widget.animal?.id && (a.lactation > 0 || !a.inHerd)).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          DetailHeader(title: widget.animal == null ? 'Register animal' : 'Edit ${widget.animal!.name}', close: true),
          Expanded(
            child: Form(
              key: _form,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [const Icon(Icons.sell_outlined, color: C.fill, size: 20), const SizedBox(width: 8), Text('Identification', style: T.titleSm)]),
                    const FieldLabel('Ear tag', required: true),
                    TextFormField(
                      key: const Key('field-tag'),
                      controller: _tag,
                      textCapitalization: TextCapitalization.characters,
                      validator: _validateTag,
                      decoration: const InputDecoration(hintText: 'NL 0812'),
                    ),
                    const FieldLabel('Name', required: true),
                    TextFormField(
                      key: const Key('field-name'),
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v ?? '').trim().length < 2 ? 'Enter a name of 2 letters or more' : null,
                      decoration: const InputDecoration(hintText: 'Poppy'),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [const Icon(Icons.pets_outlined, color: C.fill, size: 20), const SizedBox(width: 8), Text('Biology and group', style: T.titleSm)]),
                    const FieldLabel('Breed'),
                    DropdownButtonFormField<String>(
                      initialValue: _breed,
                      items: [for (final b in breeds) DropdownMenuItem(value: b, child: Text(b))],
                      onChanged: (v) => setState(() => _breed = v!),
                    ),
                    const FieldLabel('Sex'),
                    SegmentedButton<Sex>(
                      segments: const [
                        ButtonSegment(value: Sex.female, label: Text('Female'), icon: Icon(Icons.female_rounded)),
                        ButtonSegment(value: Sex.male, label: Text('Male'), icon: Icon(Icons.male_rounded)),
                      ],
                      selected: {_sex},
                      onSelectionChanged: (s) => setState(() => _sex = s.first),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.fill : C.surface),
                        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : C.ink2),
                        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                      ),
                    ),
                    const FieldLabel('Date of birth', required: true),
                    InkWell(
                      key: const Key('field-birth'),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _birth ?? AppClock.today.subtract(const Duration(days: 300)),
                          firstDate: DateTime(2005),
                          lastDate: AppClock.today,
                        );
                        if (d != null) setState(() => _birth = d);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_month_outlined, color: C.fill)),
                        child: Text(_birth == null ? 'Pick a date' : longDate(_birth!), style: T.body.copyWith(color: _birth == null ? C.ink3 : C.ink)),
                      ),
                    ),
                    const FieldLabel('Group'),
                    DropdownButtonFormField<HerdGroup>(
                      initialValue: _group,
                      items: [for (final g in HerdGroup.values) DropdownMenuItem(value: g, child: Text(g.label))],
                      onChanged: (v) => setState(() => _group = v!),
                    ),
                    const FieldLabel('Pen'),
                    DropdownButtonFormField<String>(
                      initialValue: _pen,
                      items: [for (final p in pens) DropdownMenuItem(value: p, child: Text(p))],
                      onChanged: (v) => setState(() => _pen = v!),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [const Icon(Icons.account_tree_outlined, color: C.fill, size: 20), const SizedBox(width: 8), Text('Pedigree', style: T.titleSm)]),
                    const FieldLabel('Sire'),
                    DropdownButtonFormField<int?>(
                      initialValue: _sire,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Unknown')),
                        for (final m in males) DropdownMenuItem(value: m.id, child: Text('${m.name} - ${m.tag}')),
                      ],
                      onChanged: (v) => setState(() => _sire = v),
                    ),
                    const FieldLabel('Dam'),
                    DropdownButtonFormField<int?>(
                      initialValue: _dam,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Unknown')),
                        for (final f in females.take(60)) DropdownMenuItem(value: f.id, child: Text('${f.name} - ${f.tag}')),
                      ],
                      onChanged: (v) => setState(() => _dam = v),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.verified_user_outlined, size: 16, color: C.ink3),
                  const SizedBox(width: 6),
                  Text('Stored locally on this device', style: T.caption.copyWith(color: C.ink3)),
                ]),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: PrimaryButton(key: const Key('save-animal'), label: _saving ? 'Saving...' : 'Save animal', icon: Icons.check_rounded, onPressed: _saving ? null : _save),
          ),
        ]),
      ),
    );
  }
}
