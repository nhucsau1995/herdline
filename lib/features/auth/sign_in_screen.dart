import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';

/// Pick a farm role and unlock with the device PIN. Roles decide what each person may change.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  Role _role = Role.manager;
  String _pin = '24';
  String? _error;

  static const _icons = {
    Role.admin: Icons.shield_outlined,
    Role.manager: Icons.work_outline_rounded,
    Role.worker: Icons.assignment_outlined,
    Role.vet: Icons.medical_services_outlined,
  };

  void _digit(String d) => setState(() {
        _error = null;
        if (_pin.length < 4) _pin += d;
      });

  void _signIn() {
    // Demo device: any 4-digit PIN unlocks it.
    if (_pin.length != 4) {
      setState(() => _error = 'Enter the 4-digit device PIN');
      return;
    }
    ref.read(sessionProvider.notifier).signIn(_role);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            height: 300 + top,
            child: Stack(fit: StackFit.expand, children: [
              Image.asset('assets/images/barn-hero.jpg', fit: BoxFit.cover),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 132,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: const BoxDecoration(gradient: C.hero),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/logo/icon.png', width: 36, height: 36)),
                      const SizedBox(width: 10),
                      Text('Herdline', style: T.display.copyWith(color: Colors.white)),
                    ]),
                    const SizedBox(height: 6),
                    Text('Herd records that work without signal', style: T.label.copyWith(color: Colors.white)),
                  ]),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Choose your role', style: T.label.copyWith(color: C.ink2, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.32,
                children: [for (final r in Role.values) _roleCard(r)],
              ),
              const SizedBox(height: 20),
              Text('Device PIN', style: T.caption),
              const SizedBox(height: 8),
              Row(children: [
                for (var i = 0; i < 4; i++)
                  Container(
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: i == _pin.length ? C.accent : C.borderStrong, width: i == _pin.length ? 2 : 1),
                    ),
                    child: i < _pin.length ? const Center(child: CircleAvatar(radius: 7, backgroundColor: C.fill)) : null,
                  ),
                const Spacer(),
                IconButton(
                  tooltip: 'Clear PIN',
                  onPressed: () => setState(() => _pin = ''),
                  icon: const Icon(Icons.backspace_outlined, color: C.ink2),
                ),
              ]),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_error!, style: T.caption.copyWith(color: C.dangerFg))),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'])
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: TextButton(key: Key('pin-$d'), onPressed: () => _digit(d), child: Text(d, style: T.titleSm.copyWith(color: C.fill))),
                  ),
              ]),
              const SizedBox(height: 16),
              PrimaryButton(key: const Key('sign-in'), label: 'Sign in', icon: Icons.arrow_forward_rounded, onPressed: _signIn),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (ref.watch(herdProvider).isLoading)
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  const Icon(Icons.lock_outline_rounded, size: 16, color: C.ink3),
                const SizedBox(width: 6),
                Text(
                  ref.watch(herdProvider).isLoading ? 'Preparing the herd on this device...' : 'All data stays on this device',
                  key: const Key('storage-status'),
                  style: T.caption.copyWith(color: C.ink3),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _roleCard(Role r) {
    final selected = r == _role;
    return Material(
      color: selected ? C.tint : C.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: Key('role-${r.name}'),
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _role = r),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? C.accent : C.border, width: selected ? 2 : 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(_icons[r], color: C.fill),
              const Spacer(),
              if (selected) const Icon(Icons.check_circle_rounded, color: C.fill, size: 20),
            ]),
            const Spacer(),
            Text(r.label, style: T.titleSm),
            Text(r.summary, style: T.small.copyWith(color: C.ink2), maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}
