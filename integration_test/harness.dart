import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed-time pumps instead of pumpAndSettle: the first launch shows a spinner while the
/// local database is seeded, and a spinner never settles.
Future<void> pumpFor(WidgetTester t, [int ms = 600]) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> waitFor(WidgetTester t, Finder f, {int timeoutMs = 30000}) async {
  final end = DateTime.now().add(Duration(milliseconds: timeoutMs));
  while (f.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) throw StateError('Timed out waiting for $f');
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapKey(WidgetTester t, String key, {int settleMs = 900}) async {
  final f = find.byKey(Key(key));
  await waitFor(t, f);
  await t.ensureVisible(f.last);
  await pumpFor(t, 300);
  await t.tap(f.last);
  await pumpFor(t, settleMs);
}

Future<void> signIn(WidgetTester t, {int settleMs = 900}) async {
  await waitFor(t, find.byKey(const Key('sign-in')));
  await tapKey(t, 'role-manager', settleMs: settleMs);
  await tapKey(t, 'pin-6', settleMs: 300);
  await tapKey(t, 'pin-8', settleMs: 300);
  await tapKey(t, 'sign-in', settleMs: settleMs);
  await waitFor(t, find.text('Milk today'));
  await pumpFor(t, 600);
}
