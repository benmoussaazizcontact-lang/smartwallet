import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../repositories/category_repository.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.categories)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'categories-add-fab',
        onPressed: () async {
          final name = TextEditingController();
          String? parentId;
          final current = ref.read(categoriesProvider).asData?.value ?? [];
          final parents = current.where((c) => c.isParent).toList();
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: Text(l10n.customCategory),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: name, decoration: InputDecoration(labelText: l10n.name)),
                    DropdownButtonFormField<String?>(
                      items: [
                        DropdownMenuItem<String?>(value: null, child: Text(l10n.topLevel)),
                        ...parents.map((p) => DropdownMenuItem(value: p.id, child: Text(localizedCategoryName(l10n, p.name)))),
                      ],
                      onChanged: (v) => setState(() => parentId = v),
                      decoration: InputDecoration(labelText: l10n.parent),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.create)),
                ],
              ),
            ),
          );
          if (ok == true && name.text.trim().isNotEmpty) {
            await ref.read(categoryRepositoryProvider).create(
                  name: name.text,
                  parentId: parentId,
                );
            ref.invalidate(categoriesForUserProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: categories.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(categoriesForUserProvider)),
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(localizedCategoryName(l10n, item.name)),
              subtitle: Text(item.isGlobal ? l10n.global : l10n.custom),
              leading: CircleAvatar(
                backgroundColor: _parseColor(item.color),
                child: Text(item.name.isEmpty ? '?' : item.name[0]),
              ),
              trailing: item.isGlobal
                  ? const Icon(Icons.lock_outline)
                  : IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await ref.read(categoryRepositoryProvider).delete(item);
                        ref.invalidate(categoriesForUserProvider);
                      },
                    ),
            );
          },
        ),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.length < 7) return const Color(0xFF2563EB);
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  }
}

class CategoryManagementScreen extends CategoriesScreen {
  const CategoryManagementScreen({super.key});
}
