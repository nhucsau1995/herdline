import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herdline/app.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

/// Paced walkthrough for the demo GIF (about 20 s): sign in, dashboard, herd, Bella,
/// pedigree, milk, record milk, breeding, reports.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo walkthrough', (t) async {
    await t.pumpWidget(const ProviderScope(child: HerdlineApp()));
    await waitFor(t, find.byKey(const Key('sign-in')));
    await pumpFor(t, 1200);
    debugPrint('POC_DEMO_START');
    await pumpFor(t, 800);
    await signIn(t, settleMs: 700);
    await pumpFor(t, 1600);
    await tapKey(t, 'tab-herd', settleMs: 1300);
    await tapKey(t, 'animal-NL 0482', settleMs: 1600);
    await tapKey(t, 'link-pedigree', settleMs: 1800);
    await tapKey(t, 'back', settleMs: 600);
    await tapKey(t, 'back', settleMs: 600);
    await tapKey(t, 'tab-milk', settleMs: 1400);
    await tapKey(t, 'record-milk', settleMs: 1400);
    await tapKey(t, 'save-milk', settleMs: 1400);
    await tapKey(t, 'tab-breeding', settleMs: 1500);
    await tapKey(t, 'tab-reports', settleMs: 1800);
    debugPrint('POC_DEMO_END');
    await pumpFor(t, 500);
  });
}
