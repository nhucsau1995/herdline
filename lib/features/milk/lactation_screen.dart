import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/charts.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';

/// Current lactation: fitted curve vs days in milk, yield to date, 305-day projection,
/// previous lactations, and dry-off.
class LactationScreen extends ConsumerWidget {
  const LactationScreen({super.key, required this.animalId});
  final int animalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(herdViewProvider);
    final role = ref.watch(sessionProvider) ?? Role.manager;
    final a = view?.byId[animalId];
    if (view == null || a == null) return const Scaffold(body: SizedBox());
    final dim = a.daysInMilk;
    final closed = a.closedLactations;
    final projected = view.projected305(a);
    final prev = closed.isEmpty ? null : closed.last.liters;
    final vsPrev = prev == null ? null : (projected - prev) / prev * 100;

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
          DetailHeader(title: 'Lactation ${a.lactation}', caption: '${a.name} - ${a.tag}'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (dim == null)
                AppCard(child: Text('${a.name} is not in milk right now.', style: T.body))
              else ...[
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Daily yield vs days in milk', style: T.titleSm),
                    Text('Fitted lactation curve, today is day $dim', style: T.caption),
                    const SizedBox(height: 12),
                    LactationChart(curve: a.curve, dim: dim),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(width: 16, height: 3, color: C.accent),
                      const SizedBox(width: 6),
                      Text('Actual', style: T.small),
                      const SizedBox(width: 16),
                      Container(width: 16, height: 3, color: C.supportStrong),
                      const SizedBox(width: 6),
                      Text('Projected', style: T.small),
                    ]),
                  ]),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _Box('Calved', longDate(a.calvingDate!), 'Lactation ${a.lactation}'),
                    _Box('Days in milk', '$dim', '${(dim / 305 * 100).round()}% of 305 d'),
                    _Box('Total to date', liters(view.totalToDate(a)), 'Avg ${view.avgDaily(a).toStringAsFixed(1)} L/day', color: C.fill),
                    _Box('Projected 305-d', liters(projected), vsPrev == null ? 'First lactation' : '${vsPrev >= 0 ? '+' : ''}${vsPrev.toStringAsFixed(1)}% vs L${a.lactation - 1}'),
                  ],
                ),
              ],
              SectionHeader('Previous lactations', trailing: Text('${closed.length} records', style: T.caption)),
              AppCard(
                child: closed.isEmpty
                    ? Text('No closed lactations yet.', style: T.caption)
                    : Column(children: [
                        for (final l in closed.reversed)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(children: [
                              const Icon(Icons.circle, size: 10, color: C.borderStrong),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('Lactation ${l.number} (L${l.number})', style: T.label.copyWith(fontWeight: FontWeight.w600)),
                                  Text('${l.years} - completed 305 d', style: T.caption),
                                ]),
                              ),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(liters(l.liters), style: T.label.copyWith(fontWeight: FontWeight.w700)),
                                Text('Peak ${l.peak} L', style: T.small),
                              ]),
                            ]),
                          ),
                      ]),
              ),
              const SizedBox(height: 20),
              if (dim != null && Permissions.can(role, Module.animals))
                SecondaryButton(
                  label: 'Mark dry off',
                  icon: Icons.bedtime_outlined,
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final ok = await guarded(context, () => ref.read(herdProvider.notifier).saveAnimal(a.copyWith(group: HerdGroup.dry, pen: 'Dry pen')), ok: '${a.name} moved to the dry group');
                    if (ok) nav.pop();
                  },
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box(this.label, this.value, this.note, {this.color = C.ink});
  final String label, value, note;
  final Color color;
  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: T.caption),
          const Spacer(),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: T.title.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: color))),
          Text(note, style: T.small, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      );
}
