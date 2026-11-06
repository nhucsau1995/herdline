import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/shell/home_shell.dart';
import 'state/providers.dart';

class HerdlineApp extends ConsumerWidget {
  const HerdlineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(sessionProvider) != null;
    // Start opening the local database while the sign-in screen is up.
    ref.watch(herdProvider);
    return MaterialApp(
      title: 'Herdline',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: signedIn ? const HomeShell() : const SignInScreen(),
    );
  }
}
