import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/herd_view.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';

/// Bull and semen straw inventory with conception rate per sire.
class BullsScreen extends ConsumerWidget {
  const BullsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(herdViewProvider);
    final role = ref.watch(sessionProvider) ?? Role.manager;
    if (view == null) return const Scaffold(body: SizedBox());
    final bulls = view.data.bulls;
    final low = bulls.where((b) => b.isLow).length;
    final canEdit = Permissions.can(role, Module.breeding);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const DetailHeader(title: 'Bulls and semen'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Straws in tank', style: T.caption),
                  Text('${view.strawsInTank}', style: T.display.copyWith(color: C.fill)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text('${bulls.length} bulls - $low low on stock', style: T.caption),
                    const Spacer(),
                    if (low > 0) const StatusChip('Reorder soon', Tone.warning, icon: Icons.warning_amber_rounded),
                  ]),
                ]),
              ),
              SectionHeader('Inventory by sire', trailing: Text('${bulls.length} records', style: T.caption)),
              for (final b in bulls)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    onTap: canEdit ? () => _addStraws(context, ref, b) : null,
                    child: Row(children: [
                      Photo(b.photo, size: 56),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${b.name}  ${b.tag}', style: T.titleSm),
                          Text(b.breed + (b.sexed ? ' - sexed' : ''), style: T.caption),
                          const SizedBox(height: 4),
                          if (b.isLow) const StatusChip('Low stock', Tone.warning, icon: Icons.warning_amber_rounded) else if (b.note.isNotEmpty) TintChip(b.note),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${b.straws}', style: T.title),
                        Text('straws', style: T.small),
                        Text('Conception ${b.conception}%', style: T.small),
                      ]),
                    ]),
                  ),
                ),
              if (!canEdit) const NoAccess('the straw inventory'),
            ]),
          ),
          if (canEdit)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(label: 'Add straws', icon: Icons.add_rounded, onPressed: () => _addStraws(context, ref, bulls.firstWhere((b) => b.isLow, orElse: () => bulls.first))),
            ),
        ]),
      ),
    );
  }

  Future<void> _addStraws(BuildContext context, WidgetRef ref, Bull bull) async {
    var count = 10;
    var target = bull;
    final bulls = ref.read(herdViewProvider)!.data.bulls;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Add straws'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              initialValue: target.id,
              items: [for (final b in bulls) DropdownMenuItem(value: b.id, child: Text('${b.name} ${b.tag}'))],
              onChanged: (v) => set(() => target = bulls.firstWhere((b) => b.id == v)),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(tooltip: 'Fewer', onPressed: count > 1 ? () => set(() => count = count > 5 ? count - 5 : 1) : null, icon: const Icon(Icons.remove_circle_outline)),
              Text('$count', style: T.display),
              IconButton(tooltip: 'More', onPressed: () => set(() => count += 5), icon: const Icon(Icons.add_circle_outline)),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      await guarded(context, () => ref.read(herdProvider.notifier).addStraws(target, count), ok: '$count ${target.name} straws added');
    }
  }
}
