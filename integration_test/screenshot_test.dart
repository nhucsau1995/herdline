import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herdline/app.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture key screens', (t) async {
    await t.pumpWidget(const ProviderScope(child: HerdlineApp()));
    await binding.convertFlutterSurfaceToImage();
    await waitFor(t, find.byKey(const Key('sign-in')));
    // First launch writes the sample farm to SQLite; start once it is ready.
    await waitFor(t, find.text('All data stays on this device'), timeoutMs: 90000);
    await pumpFor(t, 1500);

    Future<void> shot(String name) async {
      await pumpFor(t, 1200);
      await binding.takeScreenshot(name);
    }

    await shot('01-sign-in');
    await signIn(t);
    await shot('02-dashboard');
    await tapKey(t, 'tab-herd');
    await shot('03-herd');
    await tapKey(t, 'animal-NL 0482');
    await shot('04-animal-profile');
    await tapKey(t, 'link-pedigree');
    await shot('05-pedigree');
    await tapKey(t, 'back');
    await tapKey(t, 'link-lactation');
    await shot('06-lactation');
    await tapKey(t, 'back');
    await tapKey(t, 'back');
    await tapKey(t, 'tab-milk');
    await shot('07-milk');
    await tapKey(t, 'record-milk');
    await shot('08-record-milk');
    await tapKey(t, 'back');
    await tapKey(t, 'tab-breeding');
    await shot('09-breeding');
    await tapKey(t, 'bulls-link');
    await shot('10-bulls-semen');
    await tapKey(t, 'back');
    await tapKey(t, 'tab-dashboard');
    await tapKey(t, 'quick-log-health');
    await shot('11-health');
    await tapKey(t, 'back');
    await tapKey(t, 'tab-reports');
    await shot('12-reports');
  });
}
