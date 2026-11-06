import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../breeding/breeding_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../herd/herd_screen.dart';
import '../milk/milk_screen.dart';
import '../reports/reports_screen.dart';

final tabProvider = NotifierProvider<TabNotifier, int>(TabNotifier.new);

class TabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void go(int i) => state = i;
}

const _tabs = [
  ('Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
  ('Herd', Icons.format_list_bulleted_rounded, Icons.format_list_bulleted_rounded),
  ('Milk', Icons.water_drop_outlined, Icons.water_drop_rounded),
  ('Breeding', Icons.favorite_border_rounded, Icons.favorite_rounded),
  ('Reports', Icons.bar_chart_rounded, Icons.bar_chart_rounded),
];

/// The five primary sections with the shared bottom tab bar from the design.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(tabProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: index, children: const [
          DashboardScreen(),
          HerdScreen(),
          MilkScreen(),
          BreedingScreen(),
          ReportsScreen(),
        ]),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: C.surface, border: Border(top: BorderSide(color: C.border))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: InkWell(
                    key: Key('tab-${_tabs[i].$1.toLowerCase()}'),
                    onTap: () => ref.read(tabProvider.notifier).go(i),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                        decoration: BoxDecoration(color: i == index ? C.tint : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                        child: Icon(i == index ? _tabs[i].$3 : _tabs[i].$2, color: i == index ? C.fill : C.ink3, size: 24),
                      ),
                      const SizedBox(height: 3),
                      Text(_tabs[i].$1,
                          style: T.small.copyWith(color: i == index ? C.fill : C.ink3, fontWeight: i == index ? FontWeight.w700 : FontWeight.w500)),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
