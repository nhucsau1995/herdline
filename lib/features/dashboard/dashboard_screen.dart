import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/charts.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/herd_view.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../health/health_screen.dart';
import '../herd/animal_form_screen.dart';
import '../milk/milk_entry_screen.dart';
import '../shell/home_shell.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final herd = ref.watch(herdProvider);
    final view = ref.watch(herdViewProvider);
    final role = ref.watch(sessionProvider) ?? Role.manager;
    if (herd.hasError) return _ErrorState(error: herd.error!, onRetry: () => ref.invalidate(herdProvider));
    if (view == null) return const Center(child: CircularProgressIndicator());
    if (view.isEmpty) return const _EmptyDashboard();

    final today = AppClock.today;
    final total = view.totalOn(today);
    final trend = view.trendPct(today);
    final week = view.last7(today).map((e) => e.$2).toList();
    final me = memberFor(role);

    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
      Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset('assets/logo/icon.png', width: 28, height: 28)),
        const SizedBox(width: 8),
        Text('Herdline', style: T.titleSm),
        const Spacer(),
        const OfflineChip(),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Photo(me.photo, size: 48, radius: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Good morning, ${me.name.split(' ').first == 'Dr.' ? 'Sam' : me.name.split(' ').first}', style: T.title),
            const SizedBox(height: 2),
            TintChip(role.label),
          ]),
        ),
      ]),
      const SizedBox(height: 16),
      AppCard(
        gradient: C.hero,
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Milk today', style: T.label.copyWith(color: Colors.white)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0x33000000), borderRadius: BorderRadius.circular(999)),
              child: Text('${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(1)}% vs 7-day avg', style: T.caption.copyWith(color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(liters(total), key: const Key('milk-today'), style: T.display.copyWith(color: Colors.white, fontSize: 36)),
          const SizedBox(height: 4),
          Text('Bulk tank, withdrawal milk excluded', style: T.caption.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Sparkline(week),
        ]),
      ),
      const SizedBox(height: 16),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
        children: [
          _Stat('Cows in milk', view.count(HerdGroup.milking), Icons.water_drop_outlined, 'Avg ${view.avgPerCow(today).toStringAsFixed(1)} L/cow'),
          _Stat('Dry cows', view.count(HerdGroup.dry), Icons.bedtime_outlined, 'Dry pen'),
          _Stat('Pregnant', view.pregnant, Icons.favorite_border_rounded, '${view.conceptionRate}% conception'),
          _Stat('Heifers', view.count(HerdGroup.heifer), Icons.pets_outlined, 'Heifer barn'),
        ],
      ),
      const SizedBox(height: 16),
      Row(children: [
        _Quick('Add animal', Icons.add_rounded, const Key('quick-add-animal'), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnimalFormScreen()))),
        const SizedBox(width: 10),
        _Quick('Record milk', Icons.water_drop_outlined, const Key('quick-record-milk'), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MilkEntryScreen()))),
        const SizedBox(width: 10),
        _Quick('Log health', Icons.monitor_heart_outlined, const Key('quick-log-health'), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthScreen()))),
      ]),
      SectionHeader('Today', trailing: Text('4 tasks', style: T.caption)),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          _Task(Icons.favorite_border_rounded, '${view.heatChecksDue} heat checks due', 'Heat signs seen in pens 1 to 3', onTap: () => ref.read(tabProvider.notifier).go(3)),
          const Divider(height: 1, color: C.border),
          _Task(Icons.calendar_month_outlined, '${view.calvingsThisWeek.length} calvings due this week',
              view.calvingsThisWeek.isEmpty ? '' : 'Next: ${view.byId[view.calvingsThisWeek.first.animalId]?.name} on ${shortDate(view.calvingsThisWeek.first.date)}',
              onTap: () => ref.read(tabProvider.notifier).go(3)),
          const Divider(height: 1, color: C.border),
          _Task(Icons.warning_amber_rounded, '${view.inWithdrawal.length} cows in withdrawal', 'Milk discarded until ${view.withdrawalEnds == null ? '-' : shortDate(view.withdrawalEnds!)}',
              tone: Tone.warning, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthScreen()))),
          const Divider(height: 1, color: C.border),
          const _Task(Icons.medical_services_outlined, 'Vet visit 14:00', 'Dr. Sam Okafor - herd pregnancy checks'),
        ]),
      ),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.note);
  final String label;
  final int value;
  final IconData icon;
  final String note;
  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(label, style: T.label.copyWith(color: C.ink2))), IconPill(icon, size: 32)]),
          const Spacer(),
          Text('$value', style: T.display.copyWith(fontSize: 28)),
          Text(note, style: T.small, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      );
}

class _Quick extends StatelessWidget {
  const _Quick(this.label, this.icon, this.k, this.onTap);
  final String label;
  final IconData icon;
  final Key k;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Material(
          color: C.tint,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: k,
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(children: [
                CircleAvatar(radius: 16, backgroundColor: C.surface, child: Icon(icon, color: C.fill, size: 18)),
                const SizedBox(height: 8),
                Text(label, style: T.label.copyWith(color: C.fill, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      );
}

class _Task extends StatelessWidget {
  const _Task(this.icon, this.title, this.sub, {this.tone = Tone.info, this.onTap});
  final IconData icon;
  final String title, sub;
  final Tone tone;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final (fg, bg) = toneColors(tone);
    return InkWell(
      onTap: onTap,
      child: Container(
        color: tone == Tone.warning ? C.warnBg.withValues(alpha: 0.45) : null,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          IconPill(icon, color: fg, bg: tone == Tone.warning ? C.surface : bg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: T.label.copyWith(fontWeight: FontWeight.w600)),
              if (sub.isNotEmpty) Text(sub, style: T.caption.copyWith(color: tone == Tone.warning ? C.warnFg : C.ink2)),
            ]),
          ),
          if (onTap != null) const Icon(Icons.chevron_right_rounded, color: C.ink3),
        ]),
      ),
    );
  }
}

class _EmptyDashboard extends ConsumerWidget {
  const _EmptyDashboard();
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
        Row(children: [Text('Dashboard', style: T.title), const Spacer(), const OfflineChip()]),
        const SizedBox(height: 20),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Photo('empty-stall', height: 180, width: double.infinity, radius: 14),
            const SizedBox(height: 16),
            Text('Your herd starts here', style: T.title),
            const SizedBox(height: 6),
            Text('Register your first animal or load the sample herd to explore Herdline.', style: T.body.copyWith(color: C.ink2)),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Register first animal',
              icon: Icons.add_rounded,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnimalFormScreen())),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              key: const Key('load-sample'),
              label: 'Load sample herd',
              onPressed: () => guarded(context, () => ref.read(herdProvider.notifier).loadSample(), ok: 'Sample herd loaded'),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          for (final l in ['Cows in milk', 'Pregnant', 'Heifers'])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l, style: T.small),
                    Text('0', style: T.title.copyWith(color: C.ink3)),
                  ]),
                ),
              ),
            ),
        ]),
      ]);
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded, color: C.dangerFg, size: 40),
          const SizedBox(height: 12),
          Text('Could not open the herd database', style: T.title, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('$error', style: T.caption, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Try again', onPressed: onRetry, expand: false),
        ]),
      );
}
