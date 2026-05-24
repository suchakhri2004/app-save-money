class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final List<String> keywords;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    required this.keywords,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String? ?? '📦',
        keywords: List<String>.from(json['keywords'] as List? ?? []),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'emoji': emoji,
        'keywords': keywords,
        'created_at': createdAt.toIso8601String(),
      };

  /// ตรวจสอบว่า note จาก slip ตรงกับ keyword ในหมวดนี้หรือไม่
  bool matchesNote(String? note) {
    if (note == null || note.isEmpty) return false;
    final lowerNote = note.toLowerCase();
    return keywords.any((kw) => lowerNote.contains(kw.toLowerCase()));
  }
}
