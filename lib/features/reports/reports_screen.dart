import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/charts.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/herd_view.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../health/health_screen.dart';
import '../shell/home_shell.dart';
import 'team_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(herdViewProvider);
    final role = ref.watch(sessionProvider) ?? Role.manager;
    if (view == null) return const Center(child: CircularProgressIndicator());
    final today = AppClock.today;
    final week = view.last7(today);
    // Milk records cover the last 14 days on the device.
    final span = _days.clamp(1, 14);
    final avg = view.avgPerCowPeriod(span);
    // Compare with the period before, when the device holds it (14 days of records).
    final prev = span * 2 <= 14 ? view.avgPerCowPeriod(span, skip: span) : null;
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

    return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
      TabHeader(
        title: 'Reports',
        trailing: IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout_rounded, color: C.ink2),
          onPressed: () {
            ref.read(tabProvider.notifier).go(0);
            ref.read(sessionProvider.notifier).signOut();
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            for (final (d, l) in [(7, '7 days'), (14, '14 days')]) FilterPill(label: l, selected: _days == d, onTap: () => setState(() => _days = d)),
          ]),
          const SizedBox(height: 16),
          AppCard(
            gradient: C.hero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Average yield', style: T.label.copyWith(color: Colors.white)),
              Text('${avg.toStringAsFixed(1)} L', key: const Key('avg-yield'), style: T.display.copyWith(color: Colors.white)),
              Text(prev == null ? 'per cow per day over $span days' : 'per cow per day, ${avg - prev >= 0 ? '+' : ''}${(avg - prev).toStringAsFixed(1)} L vs the $span days before', style: T.caption.copyWith(color: Colors.white)),
            ]),
          ),
          const SizedBox(height: 12),
          _Report(
            title: 'Milk production',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Text('Herd daily total', style: T.caption), const Spacer(), Text('${liters(view.totalOn(today))}/day', style: T.label.copyWith(fontWeight: FontWeight.w700))]),
              const SizedBox(height: 12),
              PairBars(
                am: [for (final w in week) view.totalOn(w.$1, Session.am)],
                pm: [for (final w in week) view.totalOn(w.$1, Session.pm)],
                labels: [for (final w in week) DateFormat('E').format(w.$1)],
              ),
              const SizedBox(height: 8),
              Row(children: [
                const CircleAvatar(radius: 5, backgroundColor: C.accent),
                const SizedBox(width: 6),
                Text('AM session', style: T.small),
                const SizedBox(width: 14),
                const CircleAvatar(radius: 5, backgroundColor: C.supportStrong),
                const SizedBox(width: 6),
                Text('PM session', style: T.small),
              ]),
            ]),
            onView: () => ref.read(tabProvider.notifier).go(2),
          ),
          _Report(
            title: 'Fertility',
            onView: () => ref.read(tabProvider.notifier).go(3),
            child: Row(children: [
              _Num('Conception rate', '${view.conceptionRate}%', 'Target 45%', view.conceptionRate >= 45 ? Tone.success : Tone.warning),
              const SizedBox(width: 12),
              _Num('Calving interval', '${view.calvingInterval} d', 'Optimal 385-400 d', view.calvingInterval <= 400 ? Tone.success : Tone.warning),
            ]),
          ),
          _Report(
            title: 'Health',
            onView: () => push(const HealthScreen()),
            child: Row(children: [
              _Num('Treatments, 30 days', '${view.treatmentsIn(30)}', 'Vet courses', Tone.info),
              const SizedBox(width: 12),
              _Num('In withdrawal', '${view.inWithdrawal.length}', 'Milk withheld', Tone.warning),
            ]),
          ),
          _Report(
            title: 'Herd structure',
            onView: () => ref.read(tabProvider.notifier).go(1),
            child: Row(children: [
              Donut(center: '${view.herd.length}', segments: [
                DonutSegment('Milking', view.count(HerdGroup.milking), C.accent),
                DonutSegment('Dry', view.count(HerdGroup.dry), C.supportStrong),
                DonutSegment('Heifers', view.count(HerdGroup.heifer), C.borderStrong),
                DonutSegment('Bulls', view.count(HerdGroup.bull), C.warnFg),
              ]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(children: [
                  for (final (l, g, c) in [('Milking', HerdGroup.milking, C.accent), ('Dry', HerdGroup.dry, C.supportStrong), ('Heifers', HerdGroup.heifer, C.borderStrong), ('Bulls', HerdGroup.bull, C.warnFg)])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        CircleAvatar(radius: 5, backgroundColor: c),
                        const SizedBox(width: 8),
                        Expanded(child: Text(l, style: T.label)),
                        Text('${view.count(g)}', style: T.label.copyWith(fontWeight: FontWeight.w700)),
                      ]),
                    ),
                ]),
              ),
            ]),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              ListTile(
                minTileHeight: 56,
                leading: const IconPill(Icons.medical_services_outlined, size: 36),
                title: Text('Health records', style: T.label.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Treatments and withdrawal periods', style: T.small),
                trailing: const Icon(Icons.chevron_right_rounded, color: C.ink3),
                onTap: () => push(const HealthScreen()),
              ),
              const Divider(height: 1, color: C.border),
              ListTile(
                key: const Key('team-link'),
                minTileHeight: 56,
                leading: const IconPill(Icons.groups_outlined, size: 36),
                title: Text('Team and roles', style: T.label.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(Permissions.can(role, Module.team) ? 'Manage members and permissions' : 'View who can change what', style: T.small),
                trailing: const Icon(Icons.chevron_right_rounded, color: C.ink3),
                onTap: () => push(const TeamScreen()),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.title, required this.child, this.onView});
  final String title;
  final Widget child;
  final VoidCallback? onView;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: T.titleSm)),
              if (onView != null) TextButton(onPressed: onView, child: Text('View', style: T.label.copyWith(color: C.fill, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 4),
            child,
          ]),
        ),
      );
}

class _Num extends StatelessWidget {
  const _Num(this.label, this.value, this.note, this.tone);
  final String label, value, note;
  final Tone tone;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: T.small),
            Text(value, style: T.title.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            StatusChip(note, tone),
          ]),
        ),
      );
}
