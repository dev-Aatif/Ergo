class Subject {
  final String id;
  final String categoryId;
  final String name;
  final String description;

  const Subject({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description = '',
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
    };
  }
}
