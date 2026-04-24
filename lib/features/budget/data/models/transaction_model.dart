class TransactionModel {
  final String id;
  final String type; // 'expense' | 'income'
  final String title;
  final int amountCents;
  final String? categoryId;
  final int occurredAt;
  final String? userId;

  final String? categoryName;
  final String? categoryIconKey;
  final String? categoryColorHex;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.amountCents,
    required this.categoryId,
    required this.occurredAt,
    this.userId,
    this.categoryName,
    this.categoryIconKey,
    this.categoryColorHex,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'type': type,
    'title': title,
    'amountCents': amountCents,
    'categoryId': categoryId,
    'occurredAt': occurredAt,
    'userId': userId,
  };

  static TransactionModel fromMap(Map<String, Object?> map) => TransactionModel(
    id: map['id'] as String,
    type: map['type'] as String,
    title: map['title'] as String,
    amountCents: map['amountCents'] as int,
    categoryId: map['categoryId'] as String?,
    occurredAt: map['occurredAt'] as int,
    userId: map['userId'] as String?,
    categoryName: map['categoryName'] as String?,
    categoryIconKey: map['categoryIconKey'] as String?,
    categoryColorHex: map['categoryColorHex'] as String?,
  );
}