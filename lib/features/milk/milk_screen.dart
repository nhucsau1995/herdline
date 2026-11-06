import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/charts.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/herd_view.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import 'milk_entry_screen.dart';

class MilkScreen extends ConsumerStatefulWidget {
  const MilkScreen({super.key});
  @override
  ConsumerState<MilkScreen> createState() => _MilkScreenState();
}

class _MilkScreenState extends ConsumerState<MilkScreen> {
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(herdViewProvider);
    final role = ref.watch(sessionProvider) ?? Role.manager;
    if (view == null) return const Center(child: CircularProgressIndicator());
    final day = AppClock.today.subtract(Duration(days: _offset));
    final week = view.last7(day);
    final trend = view.trendPct(day);
    final cows = view.herd.where((a) => a.group == HerdGroup.milking).toList()
      ..sort((a, b) => (a.id! < 100 ? 0 : 1).compareTo(b.id! < 100 ? 0 : 1));
    final canRecord = Permissions.can(role, Module.milk);

    return Stack(children: [
      ListView(padding: const EdgeInsets.only(bottom: 96), children: [
        TabHeader(
          title: 'Milk',
          trailing: Container(
            decoration: BoxDecoration(color: C.tint, borderRadius: BorderRadius.circular(999)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(tooltip: 'Previous day', visualDensity: VisualDensity.compact, onPressed: _offset < 6 ? () => setState(() => _offset++) : null, icon: const Icon(Icons.chevron_left_rounded, color: C.fill)),
              Text(_offset == 0 ? 'Today, ${shortDate(day)}' : DateFormat('EEE, d MMM').format(day), style: T.caption.copyWith(color: C.fill, fontWeight: FontWeight.w600)),
              IconButton(tooltip: 'Next day', visualDensity: VisualDensity.compact, onPressed: _offset > 0 ? () => setState(() => _offset--) : null, icon: const Icon(Icons.chevron_right_rounded, color: C.fill)),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Herd total', style: T.caption),
                const Spacer(),
                StatusChip('${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(1)}% vs 7-day avg', trend >= 0 ? Tone.success : Tone.warning, icon: trend >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded),
              ]),
              const SizedBox(height: 4),
              Text(liters(view.totalOn(day)), key: const Key('milk-total'), style: T.display),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  _Session(Icons.wb_sunny_outlined, 'AM session', liters(view.totalOn(day, Session.am))),
                  Container(width: 1, height: 36, color: C.border),
                  _Session(Icons.nights_stay_outlined, 'PM session', liters(view.totalOn(day, Session.pm))),
                ]),
              ),
              const SizedBox(height: 16),
              Text('7-day yield', style: T.label.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              WeekBars(values: [for (final w in week) w.$2], labels: [for (final w in week) DateFormat('E').format(w.$1)]),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(children: [Text('Per cow', style: T.title), const SizedBox(width: 8), TintChip('${cows.length} milking')]),
        ),
        for (final a in cows.take(40))
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: _CowRow(view: view, a: a, day: day),
          ),
      ]),
      if (canRecord)
        Positioned(
          right: 20,
          bottom: 16,
          child: FloatingPill(
            key: const Key('record-milk'),
            label: 'Record milk',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MilkEntryScreen())),
          ),
        ),
    ]);
  }
}

class _Session extends StatelessWidget {
  const _Session(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: C.fill, size: 20),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: T.small), Text(value, style: T.label.copyWith(fontWeight: FontWeight.w700))]),
        ]),
      );
}

class _CowRow extends StatelessWidget {
  const _CowRow({required this.view, required this.a, required this.day});
  final HerdView view;
  final Animal a;
  final DateTime day;
  @override
  Widget build(BuildContext context) {
    final y = view.cowDay(a.id!, day);
    final withdrawal = view.withdrawalFor(a.id!);
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MilkEntryScreen(animalId: a.id))),
      child: Row(children: [
        Photo(a.photo, size: 48, radius: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.name, style: T.titleSm),
            Text('${a.tag} - ${a.breed} - ${a.pen}', style: T.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        if (withdrawal != null)
          const Flexible(child: StatusChip('Withdrawal - discard', Tone.warning, icon: Icons.warning_amber_rounded))
        else
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(liters(y.am + y.pm, digits: 1), style: T.titleSm),
            Text('AM ${y.am.toStringAsFixed(1)} - PM ${y.pm.toStringAsFixed(1)}', style: T.small),
          ]),
      ]),
    );
  }
}
