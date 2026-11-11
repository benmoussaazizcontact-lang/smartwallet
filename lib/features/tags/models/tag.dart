class TagItem {
  const TagItem({required this.id, required this.name});

  final String id;
  final String name;

  factory TagItem.fromMap(Map<String, dynamic> map) {
    return TagItem(id: map['id'] as String, name: map['name'] as String);
  }
}
