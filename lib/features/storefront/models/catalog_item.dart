class CatalogItem {
  final String id;
  final String categoryName;
  final String subjectName;
  final String description;
  final String colorHex;
  final String downloadUrl;
  final String iconUrl;
  final int sizeBytes;
  final int questionCount;
  final double version;

  CatalogItem({
    required this.id,
    required this.categoryName,
    required this.subjectName,
    required this.description,
    required this.colorHex,
    required this.downloadUrl,
    required this.iconUrl,
    required this.sizeBytes,
    required this.questionCount,
    required this.version,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id'] as String,
      categoryName: json['categoryName'] as String,
      subjectName: json['subjectName'] as String,
      description: json['description'] as String? ?? 'No description provided.',
      colorHex: json['colorHex'] as String? ?? '#607D8B',
      downloadUrl: json['downloadUrl'] as String,
      iconUrl: json['iconUrl'] as String? ?? 'menu_book',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      questionCount: json['questionCount'] as int? ?? 0,
      version: (json['version'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
