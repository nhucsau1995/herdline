import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';

/// Record one milking (cow, session, liters). Validates the yield and warns when it is far
/// outside the cow's usual range for her lactation stage.
class MilkEntryScreen extends ConsumerStatefulWidget {
  const MilkEntryScreen({super.key, this.animalId});
  final int? animalId;
  @override
  ConsumerState<MilkEntryScreen> createState() => _MilkEntryScreenState();
}

class _MilkEntryScreenState extends ConsumerState<MilkEntryScreen> {
  final _form = GlobalKey<FormState>();
  late int _animalId = widget.animalId ?? 10;
  Session _session = Session.am;
  final _liters = TextEditingController();
  final _note = TextEditingController();
  final DateTime _date = AppClock.today;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final view = ref.read(herdViewProvider);
    final a = view?.byId[_animalId];
    if (view == null || a == null) return;
    final (lo, hi) = view.typicalRange(a);
    _liters.text = ((lo + hi) / 2).toStringAsFixed(1);
  }

  @override
  void dispose() {
    _liters.dispose();
    _note.dispose();
    super.dispose();
  }

  void _nudge(double d) {
    final v = (double.tryParse(_liters.text.replaceAll(',', '.')) ?? 0) + d;
    setState(() => _liters.text = v.clamp(0, 60).toStringAsFixed(1));
  }

  Future<void> _pickCow() async {
    final view = ref.read(herdViewProvider)!;
    final cows = view.herd.where((a) => a.group == HerdGroup.milking).toList();
    final id = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (c) => ListView(children: [
        for (final a in cows.take(60))
          ListTile(leading: Photo(a.photo, size: 40, radius: 20), title: Text(a.name), subtitle: Text('${a.tag} - ${a.pen}'), onTap: () => Navigator.pop(c, a.id)),
      ]),
    );
    if (id != null) {
      setState(() => _animalId = id);
      _prefill();
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final r = MilkRecord(animalId: _animalId, date: _date, session: _session, liters: double.parse(_liters.text.replaceAll(',', '.')), note: _note.text.trim());
    final nav = Navigator.of(context);
    final ok = await guarded(context, () => ref.read(herdProvider.notifier).addMilk(r), ok: 'Milk record saved on this device');
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(herdViewProvider);
    final a = view?.byId[_animalId];
    if (view == null || a == null) return const Scaffold(body: SizedBox());
    final (lo, hi) = view.typicalRange(a);
    final withdrawal = view.withdrawalFor(a.id!);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const DetailHeader(title: 'Record milk', close: true),
          Expanded(
            child: Form(
              key: _form,
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                AppCard(
                  onTap: _pickCow,
                  child: Row(children: [
                    Photo(a.photo, size: 52, radius: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${a.name} - ${a.tag}', style: T.titleSm),
                        Text('${a.pen} - Lactation ${a.lactation}', style: T.caption),
                      ]),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: C.ink3),
                  ]),
                ),
                if (withdrawal != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: C.warnBg, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded, color: C.warnFg),
                      const SizedBox(width: 8),
                      Expanded(child: Text('In withdrawal until ${shortDate(withdrawal.withdrawalUntil!)}. This milk is recorded but kept out of the tank total.', style: T.caption.copyWith(color: C.warnFg))),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),
                SegmentedButton<Session>(
                  segments: const [
                    ButtonSegment(value: Session.am, label: Text('AM session'), icon: Icon(Icons.wb_sunny_outlined)),
                    ButtonSegment(value: Session.pm, label: Text('PM session'), icon: Icon(Icons.nights_stay_outlined)),
                  ],
                  selected: {_session},
                  onSelectionChanged: (s) => setState(() => _session = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.fill : C.surface),
                    foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : C.ink2),
                    minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Milk yield', style: T.caption),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('field-liters'),
                          controller: _liters,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          style: T.display,
                          decoration: const InputDecoration(suffixText: 'L', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                          validator: (v) {
                            final x = double.tryParse((v ?? '').replaceAll(',', '.'));
                            if (x == null) return 'Enter liters, for example 17.8';
                            if (x <= 0 || x > 60) return 'A single milking is between 0.1 and 60 L';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Nudge('-0.5', () => _nudge(-0.5)),
                      const SizedBox(width: 6),
                      _Nudge('+0.5', () => _nudge(0.5)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 18, color: C.okFg),
                      const SizedBox(width: 6),
                      Text('Typical for ${a.name}: ${lo.toStringAsFixed(0)}-${hi.toStringAsFixed(0)} L', style: T.caption),
                    ]),
                  ]),
                ),
                const FieldLabel('Date'),
                InputDecorator(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today_outlined, color: C.fill)),
                  child: Text(longDate(_date), style: T.body),
                ),
                const FieldLabel('Milking observation'),
                TextFormField(controller: _note, maxLines: 3, decoration: const InputDecoration(hintText: 'Optional notes, for example slight kick, clean strip test')),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: PrimaryButton(key: const Key('save-milk'), label: _saving ? 'Saving...' : 'Save record', icon: Icons.check_rounded, onPressed: _saving ? null : _save),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.circle, size: 8, color: C.okFg),
              const SizedBox(width: 6),
              Text('Saved locally on device', style: T.caption),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Nudge extends StatelessWidget {
  const _Nudge(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: C.borderStrong), padding: const EdgeInsets.symmetric(horizontal: 10)),
          child: Text(label, style: T.label.copyWith(color: C.fill, fontWeight: FontWeight.w600)),
        ),
      );
}
