class Category {
  final String id;
  final String name;
  final String accentColor;
  final String iconName;

  const Category({
    required this.id,
    required this.name,
    required this.accentColor,
    required this.iconName,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      accentColor: map['accent_color'] as String,
      iconName: map['icon_name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'accent_color': accentColor,
      'icon_name': iconName,
    };
  }
}
