import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Load the app's real fonts so layout and overflow checks match the device
/// (the default test font draws every glyph as a wide square).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final (family, weights) in [('Inter', [400, 500, 600, 700]), ('Sora', [400, 600, 700])]) {
    final loader = FontLoader(family);
    for (final w in weights) {
      loader.addFont(rootBundle.load('assets/fonts/$family-$w.ttf'));
    }
    await loader.load();
  }
  await testMain();
}
