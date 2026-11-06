import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herdline/app.dart';
import 'package:herdline/data/herd_repository.dart';
import 'package:herdline/state/providers.dart';

Future<void> pumpApp(WidgetTester tester, {bool seed = true}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [repositoryProvider.overrideWithValue(MemoryHerdRepository(seed: seed))],
    child: const HerdlineApp(),
  ));
  await tester.pumpAndSettle();
}

Future<void> signIn(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('role-manager')));
  await tester.tap(find.byKey(const Key('pin-6')));
  await tester.tap(find.byKey(const Key('pin-8')));
  await tester.ensureVisible(find.byKey(const Key('sign-in')));
  await tester.tap(find.byKey(const Key('sign-in')));
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sign in needs a 4-digit PIN', (tester) async {
    await pumpApp(tester);
    await tester.ensureVisible(find.byKey(const Key('sign-in')));
    await tester.tap(find.byKey(const Key('sign-in')));
    await tester.pump();
    expect(find.text('Enter the 4-digit device PIN'), findsOneWidget);
  });

  testWidgets('dashboard shows today and the tasks', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    expect(find.text('Milk today'), findsOneWidget);
    expect(find.text('Cows in milk'), findsOneWidget);
    expect(find.textContaining('cows in withdrawal'), findsOneWidget);
  });

  testWidgets('herd search, profile, pedigree and lactation', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await tap(tester, 'tab-herd');
    await tester.enterText(find.byKey(const Key('herd-search')), 'Bella');
    await tester.pumpAndSettle();
    await tap(tester, 'animal-NL 0482');
    expect(find.text('Bella'), findsWidgets);
    await tap(tester, 'link-pedigree');
    expect(find.text('Bolt'), findsWidgets);
    expect(find.text('Atlas'), findsOneWidget);
    await tap(tester, 'back');
    await tap(tester, 'link-lactation');
    expect(find.text('Lactation 3'), findsWidgets);
  });

  testWidgets('no match state and register with duplicate tag', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await tap(tester, 'tab-herd');
    await tester.enterText(find.byKey(const Key('herd-search')), 'NL 9999');
    await tester.pumpAndSettle();
    expect(find.text('No animals match'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('herd-search')), '');
    await tester.pumpAndSettle();
    await tap(tester, 'add-animal');
    await tester.enterText(find.byKey(const Key('field-tag')), 'NL 0482');
    await tester.enterText(find.byKey(const Key('field-name')), 'Poppy');
    await tap(tester, 'save-animal');
    expect(find.text('Tag NL 0482 is already in use'), findsOneWidget);
  });

  testWidgets('milk, record milk, breeding, bulls, reports, team', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await tap(tester, 'tab-milk');
    expect(find.text('Herd total'), findsOneWidget);
    await tap(tester, 'record-milk');
    expect(find.text('Record milk'), findsWidgets);
    await tap(tester, 'save-milk');
    expect(find.text('Milk record saved on this device'), findsOneWidget);
    await tap(tester, 'tab-breeding');
    expect(find.text('Calvings this week'), findsOneWidget);
    await tap(tester, 'bulls-link');
    expect(find.text('Low stock'), findsOneWidget);
    await tap(tester, 'back');
    await tap(tester, 'tab-reports');
    expect(find.text('Average yield'), findsOneWidget);
    await tap(tester, 'team-link');
    expect(find.text('Team and roles'), findsWidgets);
  });

  testWidgets('empty herd shows the first-run dashboard', (tester) async {
    await pumpApp(tester, seed: false);
    await signIn(tester);
    expect(find.text('Your herd starts here'), findsOneWidget);
    await tap(tester, 'load-sample');
    expect(find.text('Milk today'), findsOneWidget);
  });
}
