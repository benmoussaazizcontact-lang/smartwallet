class CategoryItem {
  const CategoryItem({
    required this.id,
    this.userId,
    required this.name,
    this.parentId,
    this.icon,
    this.color,
  });

  final String id;
  final String? userId;
  final String name;
  final String? parentId;
  final String? icon;
  final String? color;

  bool get isGlobal => userId == null;
  bool get isParent => parentId == null;

  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    return CategoryItem(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      name: map['name'] as String,
      parentId: map['parent_id'] as String?,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
    );
  }
}
