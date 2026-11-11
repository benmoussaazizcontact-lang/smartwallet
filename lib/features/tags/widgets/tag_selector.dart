import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../models/tag.dart';
import '../repositories/tag_repository.dart';

class TagSelector extends ConsumerWidget {
  const TagSelector({
    super.key,
    required this.selectedIds,
    required this.onChanged,
  });

  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider);
    return tags.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('$e'),
      data: (items) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final tag in items)
                  FilterChip(
                    label: Text(tag.name),
                    selected: selectedIds.contains(tag.id),
                    onSelected: (selected) {
                      final next = {...selectedIds};
                      if (selected) {
                        next.add(tag.id);
                      } else {
                        next.remove(tag.id);
                      }
                      onChanged(next);
                    },
                  ),
                ActionChip(
                  label: Text(context.l10n.newTag),
                  onPressed: () => _create(context, ref, items),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    List<TagItem> existing,
  ) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.newTag),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.add)),
        ],
      ),
    );
    final name = controller.text.trim();
    if (ok == true && name.isNotEmpty) {
      final created = await ref.read(tagRepositoryProvider).create(name);
      ref.invalidate(tagsForUserProvider);
      onChanged({...selectedIds, created.id});
    }
  }
}
