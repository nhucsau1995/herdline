import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/herd_view.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';

/// Team members, their roles and the permission matrix. Admin-only actions are gated.
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(sessionProvider) ?? Role.manager;
    final admin = Permissions.can(role, Module.team);

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
          DetailHeader(title: 'Team and roles', actions: [const StatusChip('Admin only', Tone.info, icon: Icons.shield_outlined), const SizedBox(width: 8)]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (!admin) const NoAccess('team members or roles'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(children: [
                  for (final m in team)
                    ListTile(
                      minTileHeight: 64,
                      leading: Photo(m.photo, size: 48, radius: 24),
                      title: Row(children: [Flexible(child: Text(m.name, style: T.label.copyWith(fontWeight: FontWeight.w600))), const SizedBox(width: 8), TintChip(m.role.label)]),
                      subtitle: Text(m.subtitle, style: T.small),
                    ),
                ]),
              ),
              const SectionHeader('Role permissions'),
              AppCard(
                child: Column(children: [
                  Row(children: [
                    Expanded(flex: 3, child: Text('Module', style: T.small)),
                    for (final r in Role.values) Expanded(flex: 2, child: Center(child: Text(const {Role.admin: 'Adm', Role.manager: 'Mgr', Role.worker: 'Wkr', Role.vet: 'Vet'}[r]!, style: T.small.copyWith(fontWeight: FontWeight.w700)))),
                  ]),
                  const Divider(color: C.border),
                  for (final m in Module.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text(m.label, style: T.label)),
                        for (final r in Role.values)
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Permissions.can(r, m)
                                  ? const Icon(Icons.check_circle_rounded, color: C.fill, size: 20)
                                  : Semantics(label: 'View only', child: const Icon(Icons.remove_rounded, color: C.ink3, size: 20)),
                            ),
                          ),
                      ]),
                    ),
                  const SizedBox(height: 4),
                  Text('Check = can change. Every role can view the herd.', style: T.small),
                ]),
              ),
              const SizedBox(height: 20),
              if (admin) ...[
                PrimaryButton(label: 'Invite member', icon: Icons.person_add_alt_outlined, onPressed: () => toast(context, 'Invites are created on this device in the next phase')),
                const SizedBox(height: 12),
                SecondaryButton(
                  key: const Key('clear-data'),
                  label: 'Clear all herd data',
                  icon: Icons.delete_sweep_outlined,
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Clear all herd data?'),
                        content: const Text('Removes every animal and record from this device. You can load the sample herd again from the dashboard.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: C.dangerFg), child: const Text('Clear')),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) await guarded(context, () => ref.read(herdProvider.notifier).clearAll(), ok: 'Herd data cleared');
                  },
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
