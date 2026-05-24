class SlipModel {
  final String id;
  final String userId;
  final String? imageUrl;
  final String? localAssetId; // PHAsset ID สำหรับ local
  final double amount;
  final DateTime date;
  final String? note;
  final String? categoryId;
  final bool isMatched; // ผ่าน Tinder swipe แล้วหรือยัง
  final DateTime createdAt;

  const SlipModel({
    required this.id,
    required this.userId,
    this.imageUrl,
    this.localAssetId,
    required this.amount,
    required this.date,
    this.note,
    this.categoryId,
    this.isMatched = false,
    required this.createdAt,
  });

  factory SlipModel.fromJson(Map<String, dynamic> json) => SlipModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        imageUrl: json['image_url'] as String?,
        localAssetId: json['local_asset_id'] as String?,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
        categoryId: json['category_id'] as String?,
        isMatched: json['is_matched'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'image_url': imageUrl,
        'local_asset_id': localAssetId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'category_id': categoryId,
        'is_matched': isMatched,
        'created_at': createdAt.toIso8601String(),
      };

  SlipModel copyWith({
    String? categoryId,
    bool? isMatched,
  }) =>
      SlipModel(
        id: id,
        userId: userId,
        imageUrl: imageUrl,
        localAssetId: localAssetId,
        amount: amount,
        date: date,
        note: note,
        categoryId: categoryId ?? this.categoryId,
        isMatched: isMatched ?? this.isMatched,
        createdAt: createdAt,
      );
}
