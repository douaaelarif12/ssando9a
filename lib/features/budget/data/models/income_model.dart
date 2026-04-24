class IncomeModel {
  final String id;
  final String userId;
  final String title;
  final int amountCents;
  final String type; // bonus | other
  final int occurredAt;

  const IncomeModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amountCents,
    required this.type,
    required this.occurredAt,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'amountCents': amountCents,
    'type': type,
    'occurredAt': occurredAt,
  };

  static IncomeModel fromMap(Map<String, Object?> map) => IncomeModel(
    id: map['id'] as String,
    userId: map['userId'] as String,
    title: map['title'] as String,
    amountCents: map['amountCents'] as int,
    type: map['type'] as String,
    occurredAt: map['occurredAt'] as int,
  );
}