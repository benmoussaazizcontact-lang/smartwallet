import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../models/category.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<CategoryItem> categories;
  final String? value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: l10n.category),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(l10n.none)),
        ...categories.map(
          (c) {
            final name = localizedCategoryName(l10n, c.name);
            return DropdownMenuItem(
              value: c.id,
              child: Text(c.parentId == null ? name : '  $name'),
            );
          },
        ),
      ],
      onChanged: onChanged,
    );
  }
}
