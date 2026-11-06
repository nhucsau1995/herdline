import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import 'animal_form_screen.dart';
import 'animal_profile_screen.dart';

class HerdScreen extends ConsumerStatefulWidget {
  const HerdScreen({super.key});
  @override
  ConsumerState<HerdScreen> createState() => _HerdScreenState();
}

class _HerdScreenState extends ConsumerState<HerdScreen> {
  final _search = TextEditingController();
  HerdGroup? _group;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(herdViewProvider);
    final role = ref.watch(sessionProvider) ?? Role.manager;
    if (view == null) return const Center(child: CircularProgressIndicator());
    final list = view.search(_search.text, _group);
    final canEdit = Permissions.can(role, Module.animals);

    return Stack(children: [
      Column(children: [
        TabHeader(title: 'Herd', caption: '${view.herd.length} animals', trailing: const OfflineChip()),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: TextField(
            key: const Key('herd-search'),
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search tag, name or group',
              prefixIcon: const Icon(Icons.search_rounded, color: C.ink3),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(tooltip: 'Clear search', icon: const Icon(Icons.close_rounded), onPressed: () => setState(_search.clear)),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
            FilterPill(label: 'All ${view.herd.length}', selected: _group == null, onTap: () => setState(() => _group = null)),
            for (final g in HerdGroup.values)
              FilterPill(key: Key('filter-${g.name}'), label: '${g.label} ${view.count(g)}', selected: _group == g, onTap: () => setState(() => _group = g)),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: list.isEmpty
              ? _NoMatch(onClear: () => setState(() {
                    _search.clear();
                    _group = null;
                  }))
              : ListView.separated(
                  key: const Key('herd-list'),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final a = list[i];
                    final (label, tone) = view.status(a);
                    return AppCard(
                      key: Key('animal-${a.tag}'),
                      padding: const EdgeInsets.all(12),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AnimalProfileScreen(animalId: a.id!))),
                      child: Row(children: [
                        Photo(a.photo, size: 56),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a.name, style: T.titleSm),
                            Text('${a.tag} - ${a.breed} - ${a.pen}', style: T.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                        StatusChip(label, tone),
                      ]),
                    );
                  },
                ),
        ),
      ]),
      if (canEdit)
        Positioned(
          right: 20,
          bottom: 16,
          child: FloatingPill(
            key: const Key('add-animal'),
            label: 'Add animal',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnimalFormScreen())),
          ),
        ),
    ]);
  }
}

class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.onClear});
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const Photo('empty-pasture', width: double.infinity, height: 170, radius: 16),
            const SizedBox(height: 16),
            Text('No animals match', style: T.title),
            const SizedBox(height: 6),
            Text('Try another ear tag or clear the filters.', style: T.body.copyWith(color: C.ink2), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SecondaryButton(label: 'Clear filters', onPressed: onClear),
          ]),
        ),
      ]);
}
